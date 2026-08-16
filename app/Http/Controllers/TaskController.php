<?php

/**
 * File Name: TaskController.php
* Description:
 * Developer: Abdelrahman-Dev-Code
 * Created Date: 2026-08-16
 * Last Modified: 2026-08-16
 */


namespace App\Http\Controllers;

use App\Http\Requests\StoreRequestTask;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Controller;

class TaskController extends Controller
{
    public function index(): JsonResponse
    {
        $tasks = Task::all();

        return response()->json([
            'data' => $tasks,
        ], 200);
    }

    public function show($id): JsonResponse
    {
        $task = Task::find($id);

        if (! $task) {
            return response()->json(['message' => 'Task not found'], 404);
        }

        return response()->json([
            'data' => $task,
        ], 200);
    }

    public function store(StoreRequestTask $request): JsonResponse
    {
        $data = $request->validated();
        $task = Task::create($data);

        return response()->json([
            'data' => $task,
        ], 201);
    }

    public function update(StoreRequestTask $request, $id): JsonResponse
    {
        $task = Task::find($id);

        if (! $task) {
            return response()->json(['message' => 'Task not found'], 404);
        }

        $task->update($request->validated());

        return response()->json([
            'data' => $task,
        ], 200);
    }

    public function destroy($id): JsonResponse
    {
        $task = Task::find($id);

        if (! $task) {
            return response()->json(['message' => 'Task not found'], 404);
        }

        $task->delete();

        return response()->json([
            'message' => 'Task deleted successfully',
            'data' => $task,
        ], 200);
    }
}


