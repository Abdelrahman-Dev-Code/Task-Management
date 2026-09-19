<?php

/**
 * File Name: TaskController.php
 * Description: m
 * Developer: Abdelrahman-Dev-Code
 * Created Date: 2026-08-16
 * Last Modified: 2026-08-16
 */

namespace App\Http\Controllers;

use App\Http\Requests\StoreRequestTask;
use App\Http\Resources\TaskResource;
use App\Services\TaskService;
use Illuminate\Http\JsonResponse;

class TaskController extends Controller
{
    public function __construct(protected TaskService $taskService) {}

    public function index(): JsonResponse
    {
        $userId = auth('sanctum')->id();
        $tasks = $this->taskService->getTaskByUser($userId);

        return response()->json([
            'data' => TaskResource::collection($tasks),
            'message' => 'تم جلب المهام بنجاح.',
        ], 200);
    }

    public function show(int|string $id): JsonResponse
    {
        $task = $this->taskService->getTaskById($id);

        if (! $task || $task->user_id !== auth()->id()) {
            return response()->json(['message' => 'المهمة غير موجودة.'], 404);
        }

        return response()->json([
            'data' => new TaskResource($task),
            'message' => 'تم جلب المهمة بنجاح.',
        ], 200);
    }

    public function store(StoreRequestTask $request): JsonResponse
    {
        try {
            $task = $this->taskService->createTask($request->validated());

            return response()->json([
                'data' => new TaskResource($task),
                'message' => 'تم إنشاء المهمة بنجاح.',
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'فشل حفظ المهمة: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function update(StoreRequestTask $request, int|string $id): JsonResponse
    {
        $task = $this->taskService->getTaskById($id);

        if (! $task || $task->user_id !== auth()->id()) {
            return response()->json(['message' => 'المهمة غير موجودة.'], 404);
        }

        $updatedTask = $this->taskService->updateTask($id, $request->validated());

        return response()->json([
            'data' => new TaskResource($this->taskService->getTaskById($id)),
            'message' => 'تم تحديث المهمة بنجاح.',
        ], 200);
    }

    public function destroy(int|string $id): JsonResponse
    {
        $task = $this->taskService->getTaskById($id);

        if (! $task || $task->user_id !== auth()->id()) {
            return response()->json(['message' => 'المهمة غير موجودة.'], 404);
        }

        $this->taskService->deleteTask($id);

        return response()->json([
            'message' => 'تم حذف المهمة بنجاح.',
            'data' => $task,
        ], 200);
    }
}
