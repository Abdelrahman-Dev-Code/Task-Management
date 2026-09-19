<?php

use App\Http\Controllers\TaskController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

/*
 =====================================================================
                  Start Route API Tasks
 =====================================================================
*/



        // Route::get('tasks', [TaskController::class, 'index']);
        // Route::get('tasks/{id}', [TaskController::class, 'show'])->where('id', '[1-9]+');
        // Route::post('tasks', [TaskController::class, 'store']);
        // Route::put('tasks/{id}', [TaskController::class, 'update'])->whereNumber('id');
        // Route::delete('tasks/{id}', [TaskController::class, 'destroy']);

Route::get('tasks', [TaskController::class, 'index']);
Route::get('tasks/{id}', [TaskController::class, 'show']);

// Authentication routes (API tokens via Sanctum)
Route::post('register', [AuthController::class, 'register']);
Route::post('login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('logout', [AuthController::class, 'logout']);
    Route::post('tasks', [TaskController::class, 'store']);
    Route::put('tasks/{id}', [TaskController::class, 'update']);
    Route::delete('tasks/{id}', [TaskController::class, 'destroy']);
});

// ===================================================================
//                     The End Route API Tasks
// ===================================================================


// ===================================================================
//                     The Start Route API Tasks
// ===================================================================

        // Route::get('user', [UserController::class, 'index']);
        // Route::post('login', [UserController::class, 'login']);
        // Route::get('user/{id}', [UserController::class, 'show']);
        // Route::post('user', [UserController::class, 'store']);
        // Route::put('user/{id}', [UserController::class, 'update']);
        // Route::delete('user/{id}', [UserController::class, 'destroy']);
        // Route::delete('user', [UserController::class, 'edit']);
        //    Route::resource('user', UserController::class);


 // ===================================================================
//                     The End Route API Users
// ===================================================================
