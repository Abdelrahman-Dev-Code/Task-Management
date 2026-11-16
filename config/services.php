<?php

return [
    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'allowed_client_ids' => array_values(array_filter(array_map(
            'trim',
            explode(',', (string) env('GOOGLE_ALLOWED_CLIENT_IDS', ''))
        ))),
        'redirect' => env('GOOGLE_REDIRECT_URI'),
    ],
    'otp' => [
        'ttl_minutes' => (int) env('OTP_TTL_MINUTES', 10),
        'cooldown_seconds' => (int) env('OTP_RESEND_COOLDOWN_SECONDS', 30),
        'max_attempts' => (int) env('OTP_MAX_ATTEMPTS', 5),
        'secret' => env('OTP_SECRET', env('APP_KEY', 'task-management-otp-secret')),
    ],
];
