<?php

namespace App\Services;

use App\Models\OtpCode;
use App\Models\User;
use App\Notifications\OtpCodeNotification;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use RuntimeException;

class OtpService
{
    public const PURPOSES = ['verify_email', 'login', 'reset_password'];

    /**
     * إرسال رمز OTP من 6 أرقام وتخزينه بشكل مشفر في قاعدة البيانات.
     *
     * @return array{expires_in_seconds: int, delivered_via: string, dev_otp?: string}
     */
    public function send(User $user, string $purpose, bool $bypassCooldown = false): array
    {
        $email = mb_strtolower(trim($user->email));
        $ttlMinutes = max(1, (int) config('services.otp.ttl_minutes', 10));
        $cooldownSeconds = max(0, (int) config('services.otp.cooldown_seconds', 30));

        $existing = OtpCode::query()
            ->where('email', $email)
            ->where('purpose', $purpose)
            ->first();

        if (! $bypassCooldown && $existing && $existing->last_sent_at) {
            $elapsed = $existing->last_sent_at->diffInSeconds(now(), true);
            if ($elapsed < $cooldownSeconds) {
                $retryAfter = max(1, (int) ceil($cooldownSeconds - $elapsed));

                return [
                    'cooldown' => true,
                    'retry_after_seconds' => $retryAfter,
                    'message' => "يرجى الانتظار {$retryAfter} ثانية قبل إعادة إرسال الرمز.",
                ];
            }
        }

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $hash = $this->hashCode($email, $purpose, $code);

        OtpCode::query()->updateOrCreate(
            ['email' => $email, 'purpose' => $purpose],
            [
                'code_hash' => $hash,
                'attempts' => 0,
                'last_sent_at' => now(),
                'expires_at' => now()->addMinutes($ttlMinutes),
            ]
        );

        $mailer = (string) config('mail.default', 'log');
        $user->notify(new OtpCodeNotification($code, $purpose, $ttlMinutes));

        $result = [
            'expires_in_seconds' => $ttlMinutes * 60,
            'delivered_via' => $mailer,
        ];

        if (app()->environment(['local', 'testing']) && in_array($mailer, ['log', 'array'], true)) {
            $result['dev_otp'] = $code;
        }

        return $result;
    }

    /**
     * التحقق من رمز OTP مع حماية ضد التخمين وانتهاء الصلاحية.
     *
     * @return array{ok: bool, status?: int, message?: string}
     */
    public function verify(string $email, string $purpose, string $otp): array
    {
        $normalizedEmail = mb_strtolower(trim($email));
        $maxAttempts = max(1, (int) config('services.otp.max_attempts', 5));

        $record = OtpCode::query()
            ->where('email', $normalizedEmail)
            ->where('purpose', $purpose)
            ->first();

        if (! $record) {
            return [
                'ok' => false,
                'status' => 404,
                'message' => 'لم يتم العثور على رمز تحقق نشط. يرجى طلب رمز جديد.',
            ];
        }

        if ($record->expires_at->isPast()) {
            $record->delete();

            return [
                'ok' => false,
                'status' => 410,
                'message' => 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.',
            ];
        }

        if ($record->attempts >= $maxAttempts) {
            $record->delete();

            return [
                'ok' => false,
                'status' => 429,
                'message' => 'تم تجاوز الحد الأقصى للمحاولات. يرجى طلب رمز جديد.',
            ];
        }

        $expectedHash = $this->hashCode($normalizedEmail, $purpose, trim($otp));
        if (! hash_equals($record->code_hash, $expectedHash)) {
            $record->increment('attempts');
            if ($record->attempts >= $maxAttempts) {
                $record->delete();

                return [
                    'ok' => false,
                    'status' => 429,
                    'message' => 'تم استنفاد محاولات التحقق. يرجى طلب رمز جديد.',
                ];
            }

            return [
                'ok' => false,
                'status' => 422,
                'message' => 'رمز التحقق غير صحيح.',
            ];
        }

        $record->delete();

        return ['ok' => true];
    }

    public function issueResetToken(string $email): string
    {
        $token = Str::random(48);
        Cache::put(
            "password_reset:{$token}",
            mb_strtolower(trim($email)),
            now()->addMinutes(15)
        );

        return $token;
    }

    public function consumeResetToken(string $token, string $email): bool
    {
        $storedEmail = Cache::pull("password_reset:{$token}");
        if (! is_string($storedEmail)) {
            return false;
        }

        return hash_equals($storedEmail, mb_strtolower(trim($email)));
    }

    private function hashCode(string $email, string $purpose, string $code): string
    {
        $secret = (string) config('services.otp.secret', 'task-management-otp-secret');

        return hash_hmac('sha256', "{$email}:{$purpose}:{$code}", $secret);
    }
}
