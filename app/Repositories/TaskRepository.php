<?php

namespace App\Repositories;

use App\Models\Task;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class TaskRepository extends BaseRepository implements TaskRepositoryInterface
{
    public function __construct(Task $model)
    {
        parent::__construct($model);
    }

    public function findForUser(int $userId, int $taskId): ?Task
    {
        return $this->model->newQuery()
            ->where('user_id', $userId)
            ->where('id', $taskId)
            ->first();
    }

    public function getFilteredForUser(int $userId, array $filters): Collection|LengthAwarePaginator
    {
        $query = $this->model->newQuery()->where('user_id', $userId);

        if (! empty($filters['search']) && is_string($filters['search'])) {
            $search = trim($filters['search']);
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if (! empty($filters['status']) && is_string($filters['status'])) {
            $query->where('status', trim($filters['status']));
        }

        if (! empty($filters['priority']) && is_string($filters['priority'])) {
            $query->where('priority', trim($filters['priority']));
        }

        if (($filters['overdue'] ?? false) === true || ($filters['overdue'] ?? null) === 'true') {
            $query->where('status', '!=', 'Completed')
                ->whereNotNull('due_date')
                ->whereDate('due_date', '<', now()->toDateString());
        }

        $sortBy = $filters['sort_by'] ?? 'created_at';
        $sortDir = ($filters['sort_dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc';

        match ($sortBy) {
            'priority' => $query->orderByRaw(
                "CASE priority WHEN 'High' THEN 3 WHEN 'Medium' THEN 2 ELSE 1 END {$sortDir}, id {$sortDir}"
            ),
            'title' => $query->orderBy('title', $sortDir)->orderBy('id', $sortDir),
            'due_date' => $query->orderByRaw(
                "CASE WHEN due_date IS NULL THEN 1 ELSE 0 END ASC, due_date {$sortDir}, id {$sortDir}"
            ),
            'updated_at' => $query->orderBy('updated_at', $sortDir)->orderBy('id', $sortDir),
            default => $query->orderBy('id', $sortDir),
        };

        if (! empty($filters['page']) && (int) $filters['page'] > 0) {
            $perPage = ! empty($filters['per_page'])
                ? min(100, max(1, (int) $filters['per_page']))
                : 15;

            return $query->paginate($perPage);
        }

        return $query->get();
    }

    public function getStatsForUser(int $userId): array
    {
        $base = $this->model->newQuery()->where('user_id', $userId);

        $total = (clone $base)->count();
        $pending = (clone $base)->where('status', 'Pending')->count();
        $inProgress = (clone $base)->where('status', 'In Progress')->count();
        $completed = (clone $base)->where('status', 'Completed')->count();
        $low = (clone $base)->where('priority', 'Low')->count();
        $medium = (clone $base)->where('priority', 'Medium')->count();
        $high = (clone $base)->where('priority', 'High')->count();
        $overdue = (clone $base)
            ->where('status', '!=', 'Completed')
            ->whereNotNull('due_date')
            ->whereDate('due_date', '<', now()->toDateString())
            ->count();

        return [
            'total' => $total,
            'pending' => $pending,
            'in_progress' => $inProgress,
            'completed' => $completed,
            'by_priority' => [
                'low' => $low,
                'medium' => $medium,
                'high' => $high,
            ],
            'overdue' => $overdue,
        ];
    }

    public function deleteCompletedForUser(int $userId): int
    {
        return $this->model->newQuery()
            ->where('user_id', $userId)
            ->where('status', 'Completed')
            ->delete();
    }
}
