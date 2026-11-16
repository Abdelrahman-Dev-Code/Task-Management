<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\User;
use App\Repositories\UserRepositoryInterface;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class AuthService
{
    public function __construct(
        protected UserRepositoryInterface $userRepository,
        protected OtpService $otpService,
    ) {}

    /**
     * @param  array{name: string, email: string, password: string, device_name?: string}  $data
     * @return array{user: User, token: string, otp_meta: array<string, mixed>|null}
     */
    public function register(array $data): array
    {
        /** @var User $user */
        $user = $this->userRepository->create([
            'name' => trim($data['name']),
            'email' => mb_strtolower(trim($data['email'])),
            'password' => $data['password'],
            'provider' => 'local',
        ]);

        $deviceName = ! empty($data['device_name']) ? trim((string) $data['device_name']) : 'flutter-app';
        $token = $user->createToken($deviceName)->plainTextToken;

        $otpMeta = null;
        try {
            $otpMeta = $this->otpService->send($user, 'verify_email', bypassCooldown: true);
        } catch (\Throwable) {
            $otpMeta = null;
        }

        AppNotification::query()->create([
            'user_id' => $user->id,
            'type' => 'account_registered',
            'title' => 'تم إنشاء حسابك بنجاح',
            'body' => 'يرجى تأكيد بريدك الإلكتروني باستخدام رمز التحقق المرسل إليك.',
            'data' => ['email' => $user->email],
        ]);

        return [
            'user' => $user,
            'token' => $token,
            'otp_meta' => $otpMeta,
        ];
    }

    /**
     * @return array{user: User, token: string}
     */
    public function login(string $email, string $password, string $deviceName = 'flutter-app'): array
    {
        $user = $this->userRepository->findByEmail($email);
        if (! $user) {
            throw new RuntimeException('بيانات الدخول غير صحيحة.', 401);
        }

        if (empty($user->password)) {
            throw new RuntimeException(
                'هذا الحساب مسجل عبر جوجل. يرجى المتابعة باستخدام جوجل أو تسجيل الدخول عبر رمز التحقق (OTP).',
                401
            );
        }

        if (! Hash::check($password, $user->password)) {
            throw new RuntimeException('بيانات الدخول غير صحيحة.', 401);
        }

        $token = $user->createToken($deviceName)->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
        ];
    }

    public function updateProfile(User $user, array $data): User
    {
        $patch = [];

        if (array_key_exists('name', $data)) {
            $patch['name'] = trim((string) $data['name']);
        }

        if (array_key_exists('avatar', $data)) {
            $patch['avatar'] = $data['avatar'];
        }

        if (! empty($data['password'])) {
            $patch['password'] = $data['password'];
        }

        $user->update($patch);

        return $user->fresh() ?? $user;
    }

    public function logout(User $user): void
    {
        $user->currentAccessToken()?->delete();
    }

    public function logoutAll(User $user): int
    {
        return (int) $user->tokens()->delete();
    }
}
