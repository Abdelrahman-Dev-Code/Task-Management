<?php

/**
 * File Name: my_api.php
 * Description:  API
 * Developer: <Abdelrah></Abdelrah>man-Dev-Code
 * Created Date: 2026-08-30
 * Last Modified: 2026-08-31
 */

use App\Http\Controllers\AuthController;
use App\Http\Controllers\TaskController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);
    Route::apiResource('task', TaskController::class);
    Route::apiResource('tasks', TaskController::class);

}
);
