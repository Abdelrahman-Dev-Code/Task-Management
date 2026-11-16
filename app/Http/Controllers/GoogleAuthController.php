<?php

namespace App\Http\Controllers;

use App\Http\Resources\UserResource;
use App\Services\GoogleAuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

class GoogleAuthController extends Controller
{
    public function __construct(protected GoogleAuthService $googleAuthService) {}

    public function authenticateWithToken(Request $request): JsonResponse
    {
        $idToken = trim((string) ($request->input('id_token') ?? $request->input('idToken') ?? ''));
        $accessToken = trim((string) ($request->input('access_token') ?? $request->input('accessToken') ?? ''));
        $deviceName = trim((string) ($request->input('device_name') ?? 'flutter-google')) ?: 'flutter-google';

        if ($idToken === '' && $accessToken === '') {
            return response()->json([
                'message' => 'يرجى إرسال id_token أو access_token للمتابعة باستخدام جوجل.',
                'errors' => [
                    'id_token' => ['حقل id_token أو access_token مطلوب.'],
                ],
            ], 422);
        }

        try {
            $profile = $idToken !== ''
                ? $this->googleAuthService->verifyIdToken($idToken)
                : $this->googleAuthService->verifyAccessToken($accessToken);

            $result = $this->googleAuthService->upsertUserFromGoogleProfile($profile, $deviceName);

            return response()->json([
                'user' => (new UserResource($result['user']))->resolve($request),
                'token' => $result['token'],
                'is_new_user' => $result['is_new_user'],
                'message' => 'تم تسجيل الدخول باستخدام جوجل بنجاح.',
            ]);
        } catch (RuntimeException $e) {
            $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 401;

            return response()->json(['message' => $e->getMessage()], $status);
        }
    }

    public function redirectUrl(Request $request): JsonResponse
    {
        try {
            $redirectUri = $request->query('redirect_uri');
            $state = $request->query('state');

            $url = $this->googleAuthService->buildAuthorizationUrl(
                is_string($redirectUri) ? $redirectUri : null,
                is_string($state) ? $state : null
            );

            return response()->json([
                'url' => $url,
                'message' => 'تم إنشاء رابط المصادقة عبر جوجل بنجاح.',
            ]);
        } catch (RuntimeException $e) {
            $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 500;

            return response()->json(['message' => $e->getMessage()], $status);
        }
    }

    public function callback(Request $request): JsonResponse
    {
        $error = $request->query('error');
        if (is_string($error) && $error !== '') {
            return response()->json([
                'message' => "تم إلغاء أو رفض المصادقة من جوجل: {$error}",
            ], 400);
        }

        $code = trim((string) $request->query('code', ''));
        if ($code === '') {
            return response()->json([
                'message' => 'رمز التفويض (code) مفقود.',
            ], 422);
        }

        try {
            $redirectUri = $request->query('redirect_uri');
            $profile = $this->googleAuthService->exchangeAuthorizationCode(
                $code,
                is_string($redirectUri) ? $redirectUri : null
            );
            $result = $this->googleAuthService->upsertUserFromGoogleProfile($profile, 'google-oauth-web');

            return response()->json([
                'user' => (new UserResource($result['user']))->resolve($request),
                'token' => $result['token'],
                'is_new_user' => $result['is_new_user'],
                'message' => 'تم تسجيل الدخول باستخدام جوجل بنجاح.',
            ]);
        } catch (RuntimeException $e) {
            $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 401;

            return response()->json(['message' => $e->getMessage()], $status);
        }
    }
}
