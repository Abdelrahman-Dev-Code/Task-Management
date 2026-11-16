<?php

namespace App\Http\Controllers;

use App\Http\Requests\LoginRequestUser;
use App\Http\Requests\StoreRequestUser;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

class AuthController extends Controller
{
    public function __construct(protected AuthService $authService) {}

    public function register(StoreRequestUser $request): JsonResponse
    {
        $result = $this->authService->register($request->validated());
        $otpMeta = $result['otp_meta'];

        $payload = [
            'user' => (new UserResource($result['user']))->resolve($request),
            'token' => $result['token'],
            'otp_required' => true,
            'otp_expires_in_seconds' => $otpMeta['expires_in_seconds'] ?? 600,
            'message' => 'تم تسجيل الحساب بنجاح. تم إرسال رمز التحقق إلى بريدك الإلكتروني.',
        ];

        if (! empty($otpMeta['dev_otp'])) {
            $payload['dev_otp'] = $otpMeta['dev_otp'];
        }

        return response()->json($payload, 201);
    }

    public function login(LoginRequestUser $request): JsonResponse
    {
        $validated = $request->validated();
        $deviceName = ! empty($validated['device_name'])
            ? trim((string) $validated['device_name'])
            : 'flutter-app';

        try {
            $result = $this->authService->login(
                (string) $validated['email'],
                (string) $validated['password'],
                $deviceName
            );

            return response()->json([
                'user' => (new UserResource($result['user']))->resolve($request),
                'token' => $result['token'],
                'message' => 'تم تسجيل الدخول بنجاح.',
            ]);
        } catch (RuntimeException $e) {
            $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 401;

            return response()->json(['message' => $e->getMessage()], $status);
        }
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return response()->json([
            'message' => 'تم تسجيل الخروج بنجاح.',
        ]);
    }

    public function logoutAll(Request $request): JsonResponse
    {
        $revoked = $this->authService->logoutAll($request->user());

        return response()->json([
            'revoked_tokens' => $revoked,
            'message' => 'تم تسجيل الخروج من جميع الأجهزة بنجاح.',
        ]);
    }

    public function user(Request $request): JsonResponse
    {
        return response()->json((new UserResource($request->user()))->resolve($request));
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $updated = $this->authService->updateProfile($request->user(), $request->validated());

        return response()->json([
            'user' => (new UserResource($updated))->resolve($request),
            'message' => 'تم تحديث بيانات الحساب بنجاح.',
        ]);
    }
}
