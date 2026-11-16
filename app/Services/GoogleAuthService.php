<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\User;
use App\Repositories\UserRepositoryInterface;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class GoogleAuthService
{
    public function __construct(
        protected UserRepositoryInterface $userRepository,
    ) {}

    /**
     * التحقق من Google ID Token القادم من تطبيق Flutter (google_sign_in).
     *
     * @return array{sub: string, email: string, name: string, picture: string|null, email_verified: bool}
     */
    public function verifyIdToken(string $idToken): array
    {
        $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (! $response->successful()) {
            throw new RuntimeException('رمز جوجل (id_token) غير صالح أو منتهي الصلاحية.', 401);
        }

        /** @var array<string, mixed> $payload */
        $payload = $response->json() ?? [];
        $email = isset($payload['email']) ? mb_strtolower(trim((string) $payload['email'])) : '';
        $sub = isset($payload['sub']) ? trim((string) $payload['sub']) : '';
        $emailVerified = ($payload['email_verified'] ?? false) === true
            || ($payload['email_verified'] ?? '') === 'true';

        if ($email === '' || $sub === '' || ! $emailVerified) {
            throw new RuntimeException('حساب جوجل لا يحتوي على بريد إلكتروني موثق.', 401);
        }

        $allowedAudiences = $this->allowedClientIds();
        $audience = isset($payload['aud']) ? trim((string) $payload['aud']) : '';
        if ($allowedAudiences !== [] && ($audience === '' || ! in_array($audience, $allowedAudiences, true))) {
            throw new RuntimeException('رمز جوجل لا يطابق معرف العميل المصرح به لهذا التطبيق.', 401);
        }

        return [
            'sub' => $sub,
            'email' => $email,
            'name' => trim((string) ($payload['name'] ?? explode('@', $email)[0])),
            'picture' => isset($payload['picture']) ? (string) $payload['picture'] : null,
            'email_verified' => true,
        ];
    }

    /**
     * التحقق من Google Access Token عبر UserInfo Endpoint.
     *
     * @return array{sub: string, email: string, name: string, picture: string|null, email_verified: bool}
     */
    public function verifyAccessToken(string $accessToken): array
    {
        $response = Http::timeout(10)
            ->withToken($accessToken)
            ->get('https://www.googleapis.com/oauth2/v3/userinfo');

        if (! $response->successful()) {
            throw new RuntimeException('رمز الوصول من جوجل (access_token) غير صالح أو منتهي الصلاحية.', 401);
        }

        /** @var array<string, mixed> $payload */
        $payload = $response->json() ?? [];
        $email = isset($payload['email']) ? mb_strtolower(trim((string) $payload['email'])) : '';
        $sub = isset($payload['sub']) ? trim((string) $payload['sub']) : '';
        $emailVerified = ($payload['email_verified'] ?? false) === true
            || ($payload['email_verified'] ?? '') === 'true';

        if ($email === '' || $sub === '' || ! $emailVerified) {
            throw new RuntimeException('حساب جوجل لا يحتوي على بريد إلكتروني موثق.', 401);
        }

        return [
            'sub' => $sub,
            'email' => $email,
            'name' => trim((string) ($payload['name'] ?? explode('@', $email)[0])),
            'picture' => isset($payload['picture']) ? (string) $payload['picture'] : null,
            'email_verified' => true,
        ];
    }

    public function buildAuthorizationUrl(?string $redirectUri = null, ?string $state = null): string
    {
        $clientId = trim((string) config('services.google.client_id', ''));
        $callbackUri = trim((string) ($redirectUri ?: config('services.google.redirect') ?: url('/api/auth/google/callback')));

        if ($clientId === '') {
            throw new RuntimeException('إعدادات جوجل غير مكتملة: يرجى إضافة GOOGLE_CLIENT_ID في ملف البيئة.', 503);
        }

        $query = array_filter([
            'client_id' => $clientId,
            'redirect_uri' => $callbackUri,
            'response_type' => 'code',
            'scope' => 'openid email profile',
            'access_type' => 'offline',
            'prompt' => 'select_account',
            'state' => $state,
        ], fn ($value) => $value !== null && $value !== '');

        return 'https://accounts.google.com/o/oauth2/v2/auth?'.http_build_query($query);
    }

    /**
     * استبدال Authorization Code ببيانات المستخدم عبر Google Token Endpoint.
     *
     * @return array{sub: string, email: string, name: string, picture: string|null, email_verified: bool}
     */
    public function exchangeAuthorizationCode(string $code, ?string $redirectUri = null): array
    {
        $clientId = trim((string) config('services.google.client_id', ''));
        $clientSecret = trim((string) config('services.google.client_secret', ''));
        $callbackUri = trim((string) ($redirectUri ?: config('services.google.redirect') ?: url('/api/auth/google/callback')));

        if ($clientId === '' || $clientSecret === '') {
            throw new RuntimeException('إعدادات جوجل غير مكتملة: يرجى إضافة GOOGLE_CLIENT_ID و GOOGLE_CLIENT_SECRET.', 503);
        }

        $response = Http::timeout(10)
            ->asForm()
            ->post('https://oauth2.googleapis.com/token', [
                'code' => $code,
                'client_id' => $clientId,
                'client_secret' => $clientSecret,
                'redirect_uri' => $callbackUri,
                'grant_type' => 'authorization_code',
            ]);

        if (! $response->successful()) {
            throw new RuntimeException('فشل تبادل رمز التفويض مع خادم جوجل.', 401);
        }

        /** @var array<string, mixed> $tokens */
        $tokens = $response->json() ?? [];

        if (! empty($tokens['id_token'])) {
            return $this->verifyIdToken((string) $tokens['id_token']);
        }

        if (! empty($tokens['access_token'])) {
            return $this->verifyAccessToken((string) $tokens['access_token']);
        }

        throw new RuntimeException('لم يُرجع خادم جوجل رمز تحقق صالح.', 401);
    }

    /**
     * إنشاء أو تحديث حساب المستخدم وإصدار رمز Sanctum.
     *
     * @param  array{sub: string, email: string, name: string, picture: string|null, email_verified: bool}  $profile
     * @return array{user: User, token: string, is_new_user: bool}
     */
    public function upsertUserFromGoogleProfile(array $profile, string $deviceName = 'flutter-google'): array
    {
        $existing = $this->userRepository->findByGoogleIdOrEmail($profile['sub'], $profile['email']);
        $isNewUser = $existing === null;

        if (! $existing) {
            /** @var User $user */
            $user = $this->userRepository->create([
                'name' => $profile['name'] ?: 'مستخدم جوجل',
                'email' => $profile['email'],
                'avatar' => $profile['picture'],
                'provider' => 'google',
                'google_id' => $profile['sub'],
                'email_verified_at' => now(),
                'password' => null,
            ]);

            AppNotification::query()->create([
                'user_id' => $user->id,
                'type' => 'google_welcome',
                'title' => 'مرحبًا بك عبر جوجل',
                'body' => 'تم ربط حسابك عبر جوجل وتوثيق بريدك الإلكتروني تلقائيًا.',
                'data' => ['provider' => 'google'],
            ]);
        } else {
            $existing->update([
                'google_id' => $existing->google_id ?: $profile['sub'],
                'avatar' => $profile['picture'] ?: $existing->avatar,
                'email_verified_at' => $existing->email_verified_at ?? now(),
            ]);
            $user = $existing->fresh() ?? $existing;
        }

        $token = $user->createToken($deviceName)->plainTextToken;

        return [
            'user' => $user,
            'token' => $token,
            'is_new_user' => $isNewUser,
        ];
    }

    /**
     * @return array<int, string>
     */
    private function allowedClientIds(): array
    {
        $ids = array_filter([
            trim((string) config('services.google.client_id', '')),
            ...(array) config('services.google.allowed_client_ids', []),
        ]);

        return array_values(array_unique($ids));
    }
}
