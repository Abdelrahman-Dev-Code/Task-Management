<?php

use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json([
    'service' => 'Task Management API',
    'framework' => 'Laravel 13 (API-Only)',
    'status' => 'ok',
    'endpoints' => [
        'health' => 'GET /api/health',
        'register' => 'POST /api/register',
        'login' => 'POST /api/login',
        'otp_send' => 'POST /api/otp/send',
        'otp_verify' => 'POST /api/otp/verify',
        'google_auth' => 'POST /api/auth/google',
        'google_url' => 'GET /api/auth/google/url',
        'google_callback' => 'GET /api/auth/google/callback',
        'tasks' => 'GET/POST /api/tasks',
        'tasks_stats' => 'GET /api/tasks/stats',
        'notifications' => 'GET /api/notifications',
    ],
]));

Route::get('/health', fn () => response()->json([
    'status' => 'ok',
    'service' => 'task-management-api',
    'timestamp' => now()->toIso8601String(),
]));

Route::fallback(fn () => response()->json([
    'message' => 'API-only backend. Use /api/* endpoints.',
], 404));
