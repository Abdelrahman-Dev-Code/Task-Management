<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Task;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Description: Run the database seeds.
     *
     * @author Abdelrahman-Dev-Code
     * @created 2026-08-15
     * @modified 2026-08-15
     * @version 2
     *
     *
     * @return  void
     */
    public function run(): void
    {
            User::firstOrCreate([
                'name'=>'ahmed ',
                'email'=>'ahmed@gamail.com ',
                'password'=>Hash::make('12345678')
        ]);
        User::factory(5)->create();
    }
}
