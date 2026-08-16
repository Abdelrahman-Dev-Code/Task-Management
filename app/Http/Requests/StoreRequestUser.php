<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreRequestUser extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6', 'max:10'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'الاسم مطلوب.',
            'name.string' => 'الاسم يجب أن يكون نصًا.',
            'name.max' => 'الاسم لا يجب أن يتجاوز 255 حرفًا.',

            'email.required' => 'البريد الإلكتروني مطلوب.',
            'email.email' => 'صيغة البريد الإلكتروني غير صحيحة.',
            'email.max' => 'البريد الإلكتروني لا يجب أن يتجاوز 255 حرفًا.',
            'email.unique' => 'هذا البريد الإلكتروني مسجل بالفعل.',

            'password.required' => 'كلمة المرور مطلوبة.',
            'password.string' => 'كلمة المرور يجب أن تكون نصًا.',
            'password.min' => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.',
            'password.max' => 'كلمة المرور يجب أن تكون 10 أحرف كحد أقصى.',
        ];
    }

    public function prepareForValidation(): void
    {
        $data = [];

        if ($this->has('name')) {
            $data['name'] = trim((string) $this->input('name'));
        }

        if ($this->has('email')) {
            $data['email'] = trim((string) $this->input('email'));
        }

        if ($this->has('password')) {
            $data['password'] = trim((string) $this->input('password'));
        }

        if (! empty($data)) {
            $this->merge($data);
        }
    }
}
