<?php

use App\Models\Task;
use App\Models\User;

test('authenticated user can CRUD tasks, filter overdue/status, get stats, and delete completed', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();

    $otherTask = Task::factory()->for($otherUser)->create(['title' => 'مهمة مستخدم آخر']);

    $this->actingAs($user, 'sanctum');

    // Create task
    $created = $this->postJson('/api/tasks', [
        'title' => 'إطلاق نسخة Flutter',
        'description' => 'ربط واجهات التطبيق مع Laravel API',
        'status' => 'In Progress',
        'priority' => 'High',
        'due_date' => now()->subDays(2)->toDateString(),
    ])->assertCreated()
        ->assertJsonPath('data.title', 'إطلاق نسخة Flutter')
        ->assertJsonPath('data.priority', 'High');

    $taskId = $created->json('data.id');

    // Cannot view another user's task
    $this->getJson("/api/tasks/{$otherTask->id}")->assertNotFound();

    // Filter overdue tasks
    $this->getJson('/api/tasks?overdue=true')
        ->assertOk()
        ->assertJsonCount(1, 'data');

    // Partial PATCH status update
    $this->patchJson("/api/tasks/{$taskId}", [
        'status' => 'Completed',
    ])->assertOk()
        ->assertJsonPath('data.status', 'Completed');

    // Stats endpoint
    $this->getJson('/api/tasks/stats')
        ->assertOk()
        ->assertJsonPath('data.total', 1)
        ->assertJsonPath('data.completed', 1)
        ->assertJsonPath('data.overdue', 0);

    // Notifications created automatically for task_created
    $notifications = $this->getJson('/api/notifications')
        ->assertOk()
        ->assertJsonPath('unread_count', 1);

    $notificationId = $notifications->json('data.0.id');

    $this->patchJson("/api/notifications/{$notificationId}/read")
        ->assertOk();

    $this->postJson('/api/notifications/read-all')
        ->assertOk();

    // Bulk delete completed tasks
    $this->deleteJson('/api/tasks/completed')
        ->assertOk()
        ->assertJsonPath('deleted_count', 1);
});
