<?php

namespace App\Http\Controllers;

use App\Http\Resources\UserResource;
use App\Repositories\UserRepositoryInterface;
use App\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use RuntimeException;

class OtpController extends Controller
{
    public function __construct(
        protected OtpService $otpService,
        protected UserRepositoryInterface $userRepository,
    ) {}

    public function send(Request $request, ?string $forcedPurpose = null): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'purpose' => ['nullable', 'string', Rule::in(OtpService::PURPOSES)],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'صيغة البريد الإلكتروني غير صحيحة.',
            'purpose.in' => 'غرض رمز التحقق غير صالح. القيم المسموحة: verify_email, login, reset_password.',
        ]);

        $purpose = $forcedPurpose ?? ($validated['purpose'] ?? 'verify_email');
        $user = $this->userRepository->findByEmail($validated['email']);

        if (! $user) {
            return response()->json([
                'message' => 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.',
            ], 404);
        }

        try {
            $result = $this->otpService->send($user, $purpose);

            if (! empty($result['cooldown'])) {
                return response()->json([
                    'message' => $result['message'] ?? 'يرجى الانتظار قبل إعادة إرسال الرمز.',
                    'retry_after_seconds' => $result['retry_after_seconds'] ?? 30,
                ], 429);
            }

            $payload = [
                'purpose' => $purpose,
                'expires_in_seconds' => $result['expires_in_seconds'],
                'delivered_via' => $result['delivered_via'],
                'message' => 'تم إرسال رمز التحقق (OTP) إلى بريدك الإلكتروني بنجاح.',
            ];

            if (! empty($result['dev_otp'])) {
                $payload['dev_otp'] = $result['dev_otp'];
            }

            return response()->json($payload);
        } catch (RuntimeException $e) {
            $status = $e->getCode() >= 400 && $e->getCode() < 600 ? $e->getCode() : 500;

            return response()->json([
                'message' => $e->getMessage(),
            ], $status);
        }
    }

    public function requestLoginOtp(Request $request): JsonResponse
    {
        return $this->send($request, 'login');
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        return $this->send($request, 'reset_password');
    }

    public function verify(Request $request, ?string $forcedPurpose = null): JsonResponse
    {
        $otpInput = $request->input('otp', $request->input('code'));
        $request->merge(['otp' => $otpInput]);

        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'otp' => ['required', 'regex:/^\d{6}$/'],
            'purpose' => ['nullable', 'string', Rule::in(OtpService::PURPOSES)],
            'device_name' => ['nullable', 'string', 'max:100'],
        ], [
            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'صيغة البريد الإلكتروني غير صحيحة.',
            'otp.required' => 'رمز التحقق مطلوب.',
            'otp.regex' => 'رمز التحقق يجب أن يتكون من 6 أرقام.',
            'purpose.in' => 'غرض رمز التحقق غير صالح.',
        ]);

        $purpose = $forcedPurpose ?? ($validated['purpose'] ?? 'verify_email');
        $user = $this->userRepository->findByEmail($validated['email']);

        if (! $user) {
            return response()->json([
                'message' => 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.',
            ], 404);
        }

        $verification = $this->otpService->verify($validated['email'], $purpose, $validated['otp']);
        if (! $verification['ok']) {
            return response()->json([
                'message' => $verification['message'] ?? 'فشل التحقق من الرمز.',
            ], $verification['status'] ?? 422);
        }

        if ($purpose === 'verify_email') {
            if (! $user->email_verified_at) {
                $user->forceFill(['email_verified_at' => now()])->save();
                $user->refresh();
            }

            return response()->json([
                'verified' => true,
                'user' => (new UserResource($user))->resolve($request),
                'message' => 'تم التحقق من البريد الإلكتروني بنجاح.',
            ]);
        }

        if ($purpose === 'login') {
            if (! $user->email_verified_at) {
                $user->forceFill(['email_verified_at' => now()])->save();
                $user->refresh();
            }

            $deviceName = ! empty($validated['device_name'])
                ? trim((string) $validated['device_name'])
                : 'flutter-otp';
            $token = $user->createToken($deviceName)->plainTextToken;

            return response()->json([
                'verified' => true,
                'user' => (new UserResource($user))->resolve($request),
                'token' => $token,
                'message' => 'تم تسجيل الدخول بنجاح باستخدام رمز التحقق.',
            ]);
        }

        $resetToken = $this->otpService->issueResetToken($validated['email']);

        return response()->json([
            'verified' => true,
            'reset_token' => $resetToken,
            'message' => 'تم التحقق من الرمز بنجاح. يمكنك الآن تعيين كلمة مرور جديدة.',
        ]);
    }

    public function verifyLoginOtp(Request $request): JsonResponse
    {
        return $this->verify($request, 'login');
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $otpInput = $request->input('otp', $request->input('code'));
        $request->merge(['otp' => $otpInput]);

        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'otp' => ['nullable', 'regex:/^\d{6}$/', 'required_without:reset_token'],
            'reset_token' => ['nullable', 'string', 'required_without:otp'],
            'password' => ['required', 'string', 'min:6', 'max:255'],
        ], [
            'email.required' => 'يرجى إدخال بريد إلكتروني صحيح.',
            'email.email' => 'يرجى إدخال بريد إلكتروني صحيح.',
            'otp.required_without' => 'يرجى إدخال رمز التحقق (OTP) أو رمز إعادة التعيين.',
            'otp.regex' => 'رمز التحقق يجب أن يتكون من 6 أرقام.',
            'reset_token.required_without' => 'يرجى إدخال رمز التحقق (OTP) أو رمز إعادة التعيين.',
            'password.required' => 'كلمة المرور الجديدة مطلوبة.',
            'password.min' => 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل.',
        ]);

        $user = $this->userRepository->findByEmail($validated['email']);
        if (! $user) {
            return response()->json([
                'message' => 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.',
            ], 404);
        }

        if (! empty($validated['reset_token'])) {
            if (! $this->otpService->consumeResetToken((string) $validated['reset_token'], $validated['email'])) {
                return response()->json([
                    'message' => 'رمز إعادة تعيين كلمة المرور غير صالح أو منتهي الصلاحية.',
                ], 422);
            }
        } else {
            $verification = $this->otpService->verify(
                $validated['email'],
                'reset_password',
                (string) $validated['otp']
            );
            if (! $verification['ok']) {
                return response()->json([
                    'message' => $verification['message'] ?? 'فشل التحقق من الرمز.',
                ], $verification['status'] ?? 422);
            }
        }

        $user->forceFill([
            'password' => $validated['password'],
            'email_verified_at' => $user->email_verified_at ?? now(),
        ])->save();

        $user->tokens()->delete();

        return response()->json([
            'message' => 'تم إعادة تعيين كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
        ]);
    }
}
