<?php

namespace App\Livewire\Auth;

use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class LoginForm extends Component
{
    public string $email = '';

    public string $password = '';

    public string $error = '';

    public function login(): void
    {
        $this->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'min:6'],
        ]);

        if (! Auth::attempt(['email' => $this->email, 'password' => $this->password], true)) {
            $this->error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

            return;
        }

        session()->regenerate();

        $this->redirect(route('tasks.index'));
    }

    public function render()
    {
        return view('livewire.auth.login-form');
    }
}
