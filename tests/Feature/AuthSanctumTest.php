<?php

use App\Models\User;

test('health endpoints respond with ok JSON', function () {
    $this->getJson('/api/health')
        ->assertOk()
        ->assertJsonPath('status', 'ok')
        ->assertJsonPath('service', 'task-management-api');

    $this->getJson('/health')
        ->assertOk()
        ->assertJsonPath('status', 'ok');
});

test('user can register, receive initial OTP, login, update profile, and logout', function () {
    $register = $this->postJson('/api/register', [
        'name' => 'أحمد محمد',
        'email' => 'newuser@example.com',
        'password' => 'secret123',
        'device_name' => 'flutter-test',
    ]);

    $register->assertCreated()
        ->assertJsonStructure(['user', 'token', 'otp_required', 'otp_expires_in_seconds', 'dev_otp', 'message'])
        ->assertJsonPath('user.email', 'newuser@example.com')
        ->assertJsonPath('otp_required', true);

    $token = $register->json('token');
    $otp = $register->json('dev_otp');

    // Verify email using initial OTP
    $this->postJson('/api/otp/verify', [
        'email' => 'newuser@example.com',
        'otp' => $otp,
        'purpose' => 'verify_email',
    ])->assertOk()
        ->assertJsonPath('verified', true);

    // Fetch current user
    $this->withToken($token)
        ->getJson('/api/user')
        ->assertOk()
        ->assertJsonPath('email', 'newuser@example.com');

    // Update profile name and password
    $this->withToken($token)
        ->putJson('/api/user', [
            'name' => 'أحمد المحدث',
            'current_password' => 'secret123',
            'password' => 'newsecret123',
        ])->assertOk()
        ->assertJsonPath('user.name', 'أحمد المحدث');

    // Login with new password
    $login = $this->postJson('/api/login', [
        'email' => 'newuser@example.com',
        'password' => 'newsecret123',
    ])->assertOk()
        ->assertJsonStructure(['user', 'token', 'message']);

    $newToken = $login->json('token');

    // Logout current token
    $this->withToken($newToken)
        ->postJson('/api/logout')
        ->assertOk();

    // Logout all remaining tokens
    $this->withToken($token)
        ->postJson('/api/logout-all')
        ->assertOk();
});

test('google-only account without password receives clear message on password login', function () {
    User::factory()->googleOnly()->create([
        'email' => 'googleonly@example.com',
    ]);

    $this->postJson('/api/login', [
        'email' => 'googleonly@example.com',
        'password' => '12345678',
    ])->assertStatus(401);
});
