<?php

namespace App\Repositories;

use App\Models\Task;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

interface TaskRepositoryInterface extends BaseRepositoryInterface
{
    public function findForUser(int $userId, int $taskId): ?Task;

    /**
     * @param  array<string, mixed>  $filters
     */
    public function getFilteredForUser(int $userId, array $filters): Collection|LengthAwarePaginator;

    /**
     * @return array<string, mixed>
     */
    public function getStatsForUser(int $userId): array;

    public function deleteCompletedForUser(int $userId): int;
}
