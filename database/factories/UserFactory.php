<?php

/**
 * File Name: UserFactory.php
 * Description:
 * Developer: Abdelrahman-Dev-Code
 * Created Date: 2026-08-14
 * Last Modified: 2026-08-21
 */


namespace Database\Factories;

// use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;


    /**
     * Description: Define the model's default state.
     *
     * @author Abdelrahman-Dev-Code
     * @created 2026-08-15
     * @modified 2026-08-15
     * @version 1
     *
     * @return void
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'remember_token' => Str::random(10),
        ];
    }

    public function creteUserAndTask(){

       
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
