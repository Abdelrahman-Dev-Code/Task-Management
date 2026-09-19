<?php

namespace App\Repositories;

use App\Models\Task;

class TaskRepository extends BaseRepository implements TaskRepositoryInterface
{
    protected function model(): string
    {
        return Task::class;
    }

    public function findById(int|string $id)
    {
        return $this->find($id);
    }

    public function getByUserId(int|string $userId)
    {
        return Task::query()->where('user_id', $userId)->get();
    }
}
