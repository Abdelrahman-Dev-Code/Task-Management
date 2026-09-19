<?php

namespace Database\Seeders;

use App\Models\Task;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Description: Run the database seeds.
     *
     * @author Abdelrahman-Dev-Code
     *
     * @created 2026-08-15
     *
     * @modified 2026-08-31
     *
     * @version 2
     */
    public function run(): void
    {
        // User::truncate();

        // User::firstOrCreate([
        //     'name' => 'ahmed ',
        //     'email' => 'ahmed@gamail.com ',
        //     'password' => Hash::make('12345678'),
        // ]);

        // User::factory(10)->has(
        //     Task::factory()->
        //                   count(3)
        // )->create();

        //  User::factory(5)->create();
    }
}
