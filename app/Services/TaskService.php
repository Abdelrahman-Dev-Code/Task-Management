<?php

namespace App\Services;

use App\Repositories\TaskRepositoryInterface;

class TaskService
{
    public function __construct(protected TaskRepositoryInterface $taskRepository) {}

    public function getAllTasks()
    {
        return $this->taskRepository->all();
    }

    public function getTaskByUser(int|string $userId)
    {
        return $this->taskRepository->getByUserId($userId);
    }

    public function getTaskById(int|string $id)
    {
        return $this->taskRepository->findById($id);
    }

    public function createTask(array $data)
    {
        // محاولة الحصول على المعرف من Sanctum أولاً ثم من الحارس الافتراضي
        $userId = auth('sanctum')->id() ?? auth()->id();

        if (! $userId) {
            throw new \Exception('يجب تسجيل الدخول لإضافة مهمة');
        }

        $data['user_id'] = $userId;

        return $this->taskRepository->create($data);
    }

    public function updateTask(int|string $id, array $data)
    {
        return $this->taskRepository->update($id, $data);
    }

    public function deleteTask(int|string $id): bool
    {
        return $this->taskRepository->delete($id);
    }
}
