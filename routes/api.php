<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\GoogleAuthController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\OtpController;
use App\Http\Controllers\TaskController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes (Laravel 13 + Sanctum + OTP + Google OAuth + Flutter)
|--------------------------------------------------------------------------
*/

Route::get('/health', fn () => response()->json([
    'status' => 'ok',
    'service' => 'task-management-api',
    'framework' => 'laravel',
    'timestamp' => now()->toIso8601String(),
]));

// ============================
// Authentication (Public)
// ============================
Route::post('/register', [AuthController::class, 'register']);
Route::post('/auth/register', [AuthController::class, 'register']);

Route::post('/login', [AuthController::class, 'login']);
Route::post('/auth/login', [AuthController::class, 'login']);

// ============================
// OTP System (Verify Email / Passwordless Login / Forgot Password)
// ============================
Route::middleware('throttle:otp')->group(function () {
    Route::post('/otp/send', [OtpController::class, 'send']);
    Route::post('/otp/verify', [OtpController::class, 'verify']);
    Route::post('/auth/otp/request', [OtpController::class, 'requestLoginOtp']);
    Route::post('/auth/otp/verify', [OtpController::class, 'verifyLoginOtp']);
    Route::post('/password/forgot', [OtpController::class, 'forgotPassword']);
    Route::post('/password/reset', [OtpController::class, 'resetPassword']);
});

// ============================
// Continue with Google (Flutter ID/Access Token & OAuth2 Code Flow)
// ============================
Route::prefix('auth/google')->group(function () {
    Route::post('/', [GoogleAuthController::class, 'authenticateWithToken']);
    Route::get('/url', [GoogleAuthController::class, 'redirectUrl']);
    Route::get('/callback', [GoogleAuthController::class, 'callback']);
});

// ============================
// Protected Endpoints (Sanctum Bearer Token)
// ============================
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
    // Session & Profile
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/logout-all', [AuthController::class, 'logoutAll']);

    Route::get('/user', [AuthController::class, 'user']);
    Route::get('/auth/me', [AuthController::class, 'user']);
    Route::match(['put', 'patch'], '/user', [AuthController::class, 'updateProfile']);

    // Tasks CRUD & Analytics (supports /tasks and legacy /task prefix)
    foreach (['tasks', 'task'] as $prefix) {
        Route::get("{$prefix}/stats", [TaskController::class, 'stats']);
        Route::delete("{$prefix}/completed", [TaskController::class, 'destroyCompleted']);
        Route::get($prefix, [TaskController::class, 'index']);
        Route::post($prefix, [TaskController::class, 'store']);
        Route::get("{$prefix}/{id}", [TaskController::class, 'show'])->whereNumber('id');
        Route::match(['put', 'patch'], "{$prefix}/{id}", [TaskController::class, 'update'])->whereNumber('id');
        Route::delete("{$prefix}/{id}", [TaskController::class, 'destroy'])->whereNumber('id');
    }

    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead'])->whereNumber('id');
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllRead']);
});

Route::fallback(fn () => response()->json([
    'message' => 'نقطة النهاية غير موجودة.',
], 404));
