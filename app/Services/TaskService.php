<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Task;
use App\Repositories\TaskRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class TaskService
{
    public function __construct(
        protected TaskRepositoryInterface $taskRepository,
    ) {}

    /**
     * @param  array<string, mixed>  $filters
     */
    public function listForUser(int $userId, array $filters): Collection|LengthAwarePaginator
    {
        return $this->taskRepository->getFilteredForUser($userId, $filters);
    }

    public function findForUser(int $userId, int $taskId): ?Task
    {
        return $this->taskRepository->findForUser($userId, $taskId);
    }

    public function statsForUser(int $userId): array
    {
        return $this->taskRepository->getStatsForUser($userId);
    }

    public function createForUser(int $userId, array $data): Task
    {
        /** @var Task $task */
        $task = $this->taskRepository->create([
            'user_id' => $userId,
            'title' => trim((string) $data['title']),
            'description' => $data['description'] ?? null,
            'status' => $data['status'] ?? 'Pending',
            'priority' => $data['priority'] ?? 'Medium',
            'due_date' => $data['due_date'] ?? null,
        ]);

        AppNotification::query()->create([
            'user_id' => $userId,
            'type' => 'task_created',
            'title' => 'تمت إضافة مهمة جديدة',
            'body' => "تم إنشاء المهمة \"{$task->title}\" بأولوية {$task->priority}.",
            'data' => ['task_id' => $task->id],
        ]);

        return $task;
    }

    public function updateTask(Task $task, array $data): Task
    {
        $task->update($data);

        return $task->fresh() ?? $task;
    }

    public function deleteTask(Task $task): bool
    {
        return (bool) $task->delete();
    }

    public function deleteCompletedForUser(int $userId): int
    {
        return $this->taskRepository->deleteCompletedForUser($userId);
    }
}
