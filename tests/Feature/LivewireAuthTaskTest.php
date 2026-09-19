<?php

use App\Models\User;

it('shows login page', function () {
    $this->get('/login')
        ->assertOk();
});

it('shows task dashboard for authenticated user', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get('/tasks')
        ->assertOk();
});
