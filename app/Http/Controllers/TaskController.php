<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Task;



namespace App\Http\Controllers;


use App\Models\Task;
use GuzzleHttp\Psr7\Response;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;

class TaskController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $tasks = Task::all();
        return response()->json(['data '=>$tasks,200]);
    }

    /**
     * Display the specified resource.
     */
    public function show($id)
    {
        $task = Task::find($id);
        if ($task == null) {
            return response()->json(['message' => 'not found'], 404);
        }

        return  response()->json(['data' => $task], 200);
    }

    /*

     *  ======================================================
     *
     *  ======================================================
    */
    public function store(Request $request)
    {
        $data = $request->validate([
             'Title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'status' => 'nullable|in:Pending,In Progress,Completed',
            'priority' => 'nullable|in:Low,Medium,High',
            'user_id' => 'nullable|exists:users,id',
        ]);

        $task = Task::create($data);
        return response()->json(['data'=>$data],201);
    }

    public function update(Request $request, $id)
    {
        $task = Task::find($id);
        if ($task == null) {
            return response()->json(['message' => 'not found'], 404);
        }

        $data = $request->validate([
              'Title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'status' => 'nullable|in:Pending,In Progress,Completed',
            'priority' => 'nullable|in:Low,Medium,High',
            'user_id' => 'nullable|exists:users,id',
        ]);

      //  unset($data['user_id']);
        $task->update($data);
        return response()->json(['data'=>$task],201);

    }

    public function destroy($id)
    {

        $task = Task::find($id);
        if ($task == null) {
            return response()->json(['msgg' => 'not found '], 404);
        }

        $task->delete();

        return response()->json(['message' => 'deleted', 'data' => $task], 200);

    }
}


