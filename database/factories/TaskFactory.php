<?php

namespace Database\Factories;

use App\Models\Task;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<Task> */
class TaskFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'title' => fake()->sentence(4),
            'description' => fake()->optional()->paragraph(),
            'status' => fake()->randomElement(['Pending', 'In Progress', 'Completed']),
            'priority' => fake()->randomElement(['Low', 'Medium', 'High']),
            'due_date' => fake()->optional()->dateTimeBetween('now', '+14 days')?->format('Y-m-d'),
        ];
    }
}
