<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Task;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */

    public function run(): void
    {

        // User::create([
        //     'name'=>'ahmed ',
        //     'email'=>'ahmed@gamail.com ',
        //     'password'=>'12345678 '
        // ]);
          Task::create(
            [
              'Title'=>' my Taskes 1',
              'description'=>'of data in progranming ',
              'status'=>'Pending',
              'priority'=>'Low',
              'user_id'=>1,


            ]
        );
    }
}
