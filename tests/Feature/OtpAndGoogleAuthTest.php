<?php

use App\Models\User;
use Illuminate\Support\Facades\Http;

test('user can request and verify passwordless login OTP', function () {
    $user = User::factory()->create([
        'email' => 'otpuser@example.com',
    ]);

    $send = $this->postJson('/api/auth/otp/request', [
        'email' => $user->email,
    ])->assertOk()
        ->assertJsonPath('purpose', 'login')
        ->assertJsonStructure(['expires_in_seconds', 'dev_otp']);

    // Resend immediately triggers 429 cooldown
    $this->postJson('/api/auth/otp/request', [
        'email' => $user->email,
    ])->assertStatus(429);

    // Wrong OTP fails with 422
    $this->postJson('/api/auth/otp/verify', [
        'email' => $user->email,
        'otp' => '000000',
    ])->assertStatus(422);

    // Correct OTP issues Sanctum token
    $this->postJson('/api/auth/otp/verify', [
        'email' => $user->email,
        'otp' => $send->json('dev_otp'),
    ])->assertOk()
        ->assertJsonPath('verified', true)
        ->assertJsonStructure(['user', 'token']);
});

test('user can reset password using forgot-password OTP flow', function () {
    $user = User::factory()->create([
        'email' => 'reset@example.com',
    ]);

    $forgot = $this->postJson('/api/password/forgot', [
        'email' => $user->email,
    ])->assertOk();

    $otp = $forgot->json('dev_otp');

    $this->postJson('/api/password/reset', [
        'email' => $user->email,
        'otp' => $otp,
        'password' => 'brandnewpass',
    ])->assertOk();

    $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'brandnewpass',
    ])->assertOk();
});

test('user can authenticate via Google ID token and receive Sanctum token', function () {
    config()->set('services.google.client_id', 'test-google-client-id');

    Http::fake([
        'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
            'sub' => 'google-sub-12345',
            'email' => 'google.flutter@example.com',
            'email_verified' => 'true',
            'name' => 'Flutter Google User',
            'picture' => 'https://example.com/avatar.png',
            'aud' => 'test-google-client-id',
        ], 200),
    ]);

    $response = $this->postJson('/api/auth/google', [
        'id_token' => 'fake-google-id-token',
        'device_name' => 'flutter-android',
    ]);

    $response->assertOk()
        ->assertJsonPath('user.email', 'google.flutter@example.com')
        ->assertJsonPath('user.provider', 'google')
        ->assertJsonPath('is_new_user', true)
        ->assertJsonStructure(['user', 'token']);

    $this->assertDatabaseHas('users', [
        'email' => 'google.flutter@example.com',
        'google_id' => 'google-sub-12345',
    ]);
});
