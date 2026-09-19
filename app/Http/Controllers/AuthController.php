<?php

namespace App\Http\Controllers;

use App\Http\Requests\LoginRequestUser;
use App\Http\Requests\StoreRequestUser;
use App\Services\AuthService;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(protected AuthService $authService) {}

    public function register(StoreRequestUser $request)
    {
        $payload = $this->authService->register($request->validated());

        return response()->json([
            'user' => $payload['user'],
            'token' => $payload['token'],
            'message' => 'تم تسجيل الحساب بنجاح.',
        ], 201);
    }

    public function login(LoginRequestUser $request)
    {
        $payload = $this->authService->login($request->validated());

        if (! $payload) {
            return response()->json([
                'message' => 'بيانات الدخول غير صحيحة.',
            ], 401);
        }

        return response()->json([
            'user' => $payload['user'],
            'token' => $payload['token'],
            'message' => 'تم تسجيل الدخول بنجاح.',
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'تم تسجيل الخروج بنجاح.',
        ]);
    }
}
