<?php

use App\Livewire\Auth\RegisterForm;
use App\Livewire\Tasks\TaskBoard;
use App\Models\User;
use App\Notifications\TaskCreatedNotification;
use Illuminate\Support\Facades\Notification;
use Livewire\Livewire;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('user receives email verification notification on registration', function () {
    Notification::fake();

    Livewire::test(RegisterForm::class)
        ->set('name', 'Ali')
        ->set('email', 'ali@example.com')
        ->set('password', 'password123')
        ->set('password_confirmation', 'password123')
        ->call('register');

    $user = User::where('email', 'ali@example.com')->first();

    expect($user)->not->toBeNull();
    Notification::assertSentTo($user, \Illuminate\Auth\Notifications\VerifyEmail::class);
});

test('task creation sends notification to the user', function () {
    Notification::fake();

    $user = User::factory()->create();

    Livewire::actingAs($user)
        ->test(TaskBoard::class)
        ->set('title', 'Write project brief')
        ->set('description', 'Draft the launch summary for the client meeting')
        ->set('taskStatus', 'Pending')
        ->set('taskPriority', 'High')
        ->call('saveTask');

    Notification::assertSentTo($user, TaskCreatedNotification::class);
});
