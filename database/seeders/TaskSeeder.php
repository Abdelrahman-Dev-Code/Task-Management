<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use app\Models\Task;
use app\Models\User;

class TaskSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {

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
