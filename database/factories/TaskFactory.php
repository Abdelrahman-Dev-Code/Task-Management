<?php

/**
 * File Name: TaskFactory.php
 * Description:
 * Developer: Abdelrahman-Dev-Code
 * Created Date: 2026-08-11
 * Last Modified: 2026-08-11
 */


namespace Database\Factories;

use App\Models\Task;
use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<Task>
 */
class TaskFactory extends Factory
{
    protected $model=Task::class;
    /**
     * Description: Define the model's default state.
     *
     * @author Abdelrahman-Dev-Code
     * @created 2026-08-11
     * @modified 2026-08-11
     * @version 1
     *
     * @returns
     */
    public function definition(): array
    {
         return [
            'title' => $this->faker->sentence(),
            'description' => $this->faker->paragraph(),
            'status' => $this->faker->randomElement(['Pending', 'In Progress', 'Completed']),
            'priority' => $this->faker->randomElement(['Low', 'Medium', 'High']),
            'user_id' =>2,
        ];
    }
}
