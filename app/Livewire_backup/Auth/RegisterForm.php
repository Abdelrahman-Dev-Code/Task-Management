<?php

namespace App\Livewire\Auth;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Attributes\Validate;
use Livewire\Component;

class RegisterForm extends Component
{
    #[Validate('required|string|min:3|max:255')]
    public string $name = '';

    #[Validate('required|email|unique:users,email')]
    public string $email = '';

    #[Validate('required|min:8|confirmed')]
    public string $password = '';

    public string $password_confirmation = '';

    public string $error = '';

    public function register(): void
    {
        $this->validate();

        $user = User::create([
            'name' => $this->name,
            'email' => $this->email,
            'password' => $this->password,
        ]);

        $user->sendEmailVerificationNotification();

        Auth::login($user);

        session()->flash('success', 'تم إنشاء الحساب بنجاح، وتم إرسال رابط التحقق إلى بريدك الإلكتروني.');

        $this->redirect(route('tasks.index'));
    }

    public function render()
    {
        return view('livewire.auth.register-form');
    }
}
