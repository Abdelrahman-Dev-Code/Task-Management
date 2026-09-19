<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('user can register and receive a sanctum token', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'Test User',
        'email' => 'test@example.com',
        'password' => 'secret123',
    ]);

    $response->assertStatus(201)
        ->assertJsonStructure([
            'user' => ['id', 'name', 'email'],
            'token',
        ]);

    $this->assertDatabaseHas('users', ['email' => 'test@example.com']);
});

test('user can login and access protected route with sanctum token', function () {
    $user = User::factory()->create([
        'email' => 'login@example.com',
        'password' => bcrypt('secret123'),
    ]);

    $loginResponse = $this->postJson('/api/login', [
        'email' => 'login@example.com',
        'password' => 'secret123',
    ]);

    $loginResponse->assertStatus(200)
        ->assertJsonStructure([
            'user' => ['id', 'name', 'email'],
            'token',
        ]);

    $token = $loginResponse->json('token');

    $this->getJson('/api/user', ['Authorization' => 'Bearer '.$token])
        ->assertStatus(200)
        ->assertJsonPath('email', 'login@example.com');
});
