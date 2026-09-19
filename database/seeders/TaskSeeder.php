<?php

namespace Database\Seeders;

use App\Models\Task;
use App\Models\User;
use Illuminate\Database\Seeder;

class TaskSeeder extends Seeder
{
    /**
     * Description: Run the database seeds.
     *
     * @author Abdelrahman-Dev-Code
     *
     * @created 2026-08-15
     *
     * @modified 2026-08-21
     *
     * @version 1
     */
    public function run(): void
    {

        // Task::create(
        //     [
        //       'Title'=>' my Taskes 1',
        //       'description'=>'of data in progranming ',
        //       'status'=>'Pending',
        //       'priority'=>'Low',
        //       'user_id'=>1,
        //     ]
        // );

        //  Task::truncate();

        // $users = User::all();
        // foreach ($users as $user) {

        //     Task::factory(10)->create(
        //         ['user_id' => $user->id]
        //     );
        // }

        // Task::factory()->for(User::factory()->create(),"Usess")->create();

    }
}
