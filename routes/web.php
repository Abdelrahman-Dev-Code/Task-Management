<?php

use Illuminate\Foundation\Auth\EmailVerificationRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

// API-only mode: redirect web requests to API or return JSON guidance.
Route::get('/', function () {
    return response()->json([
        'message' => 'API-only application. Use the /api endpoints for authentication and task management.',
    ]);
});

// Keep a minimal ping endpoint for quick checks
Route::get('/health', function () {
    return response()->json(['status' => 'ok']);
});

// If someone tries to access legacy web auth routes, return a JSON hint
Route::fallback(function () {
    return response()->json([
        'message' => 'This application is API-only. See /api for available endpoints.'
    ], 404);
});

// Disable email verification web endpoints (handled via API)
// Note: Implement verification via API endpoints in the AuthController if needed.
