<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreRequestUser;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Invalid credentials.',
            ], 401);
        }

        return response()->json([
            'message' => 'Login successful.',
            'data' => $user,
        ], 200);
    }

    public function index(): JsonResponse
    {
        $users = User::all();

        return response()->json([
            'data' => $users,
        ], 200);
    }

    public function create()
    {
        //
    }

    public function store(StoreRequestUser $request): JsonResponse
    {
        $data = $request->validated();
        $user = User::create($data);

        return response()->json([
            'message' => 'User created successfully.',
            'data' => $user,
        ], 201);
    }

    public function show(string $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'message' => 'User not found.',
            ], 404);
        }

        return response()->json([
            'data' => $user,
        ], 200);
    }

    public function edit(string $id)
    {
        //
    }

    public function update(StoreRequestUser $request, string $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'message' => 'User not found.',
            ], 404);
        }

        $data = $request->validated();
        $user->update($data);

        return response()->json([
            'message' => 'User updated successfully.',
            'data' => $user->fresh(),
        ], 200);
    }

    public function destroy(string $id): JsonResponse
    {
        $user = User::find($id);

        if (!$user) {
            return response()->json([
                'message' => 'User not found.',
            ], 404);
        }

        $user->delete();

        return response()->json([
            'message' => 'User deleted successfully.',
            'data' => $user,
        ], 200);
    }
}
