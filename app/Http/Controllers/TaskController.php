<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreRequestTask;
use App\Http\Requests\UpdateRequestTask;
use App\Http\Resources\TaskResource;
use App\Services\TaskService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function __construct(protected TaskService $taskService) {}

    public function stats(Request $request): JsonResponse
    {
        $stats = $this->taskService->statsForUser($request->user()->id);

        return response()->json([
            'data' => $stats,
            'message' => 'تم جلب إحصائيات المهام بنجاح.',
        ]);
    }

    public function destroyCompleted(Request $request): JsonResponse
    {
        $deletedCount = $this->taskService->deleteCompletedForUser($request->user()->id);

        return response()->json([
            'deleted_count' => $deletedCount,
            'message' => 'تم حذف المهام المكتملة بنجاح.',
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $result = $this->taskService->listForUser($request->user()->id, [
            'search' => $request->query('search'),
            'status' => $request->query('status'),
            'priority' => $request->query('priority'),
            'overdue' => $request->query('overdue'),
            'sort_by' => $request->query('sort_by', 'created_at'),
            'sort_dir' => $request->query('sort_dir', 'desc'),
            'page' => $request->query('page'),
            'per_page' => $request->query('per_page'),
        ]);

        if ($result instanceof LengthAwarePaginator) {
            return response()->json([
                'data' => TaskResource::collection($result->items())->resolve($request),
                'meta' => [
                    'total' => $result->total(),
                    'page' => $result->currentPage(),
                    'per_page' => $result->perPage(),
                    'last_page' => $result->lastPage(),
                ],
                'message' => 'تم جلب المهام بنجاح.',
            ]);
        }

        return response()->json([
            'data' => TaskResource::collection($result)->resolve($request),
            'message' => 'تم جلب المهام بنجاح.',
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $task = $this->taskService->findForUser($request->user()->id, $id);
        if (! $task) {
            return response()->json(['message' => 'المهمة غير موجودة.'], 404);
        }

        return response()->json([
            'data' => (new TaskResource($task))->resolve($request),
            'message' => 'تم جلب المهمة بنجاح.',
        ]);
    }

    public function store(StoreRequestTask $request): JsonResponse
    {
        $task = $this->taskService->createForUser($request->user()->id, $request->validated());

        return response()->json([
            'data' => (new TaskResource($task))->resolve($request),
            'message' => 'تم إنشاء المهمة بنجاح.',
        ], 201);
    }

    public function update(UpdateRequestTask $request, int $id): JsonResponse
    {
        $task = $this->taskService->findForUser($request->user()->id, $id);
        if (! $task) {
            return response()->json(['message' => 'المهمة غير موجودة.'], 404);
        }

        $updated = $this->taskService->updateTask($task, $request->validated());

        return response()->json([
            'data' => (new TaskResource($updated))->resolve($request),
            'message' => 'تم تحديث المهمة بنجاح.',
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $task = $this->taskService->findForUser($request->user()->id, $id);
        if (! $task) {
            return response()->json(['message' => 'المهمة غير موجودة.'], 404);
        }

        $resource = (new TaskResource($task))->resolve($request);
        $this->taskService->deleteTask($task);

        return response()->json([
            'message' => 'تم حذف المهمة بنجاح.',
            'data' => $resource,
        ]);
    }
}
