<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $users = User::all();

        return response()->json(['data ' => $users, 200]);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email',
            'password' => 'required|string|min:6|max:10',

        ]);

        $user = User::create($data);

        return response()->json(['data' => $data], 201);

    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $user = User::find($id);
        if ($user == null) {
            return response()->json(['message' => 'not found'], 404);
        }

        return response()->json(['data' => $user], 200);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $user = User::find($id);
        if ($user == null) {
            return response()->json(['message' => 'not found'], 404);
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email',
            'password' => 'required|string|min:6|max:10',
        ]);

        //  unset($data['user_id']);
        $user->update($data);

        return response()->json(['data' =>$data], 201);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {

        $user = User::find($id);
        if ($user == null) {
            return response()->json(['msgg' => 'not found '], 404);
        }

        $user->delete();

        return response()->json(['message' => 'deleted', 'data' => $user], 200);

    }
}
