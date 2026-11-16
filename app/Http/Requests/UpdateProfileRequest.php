<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Hash;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'avatar' => ['sometimes', 'nullable', 'string', 'max:1024'],
            'password' => ['sometimes', 'nullable', 'string', 'min:6', 'max:255'],
            'current_password' => ['nullable', 'string'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'الاسم مطلوب.',
            'name.max' => 'الاسم لا يجب أن يتجاوز 255 حرفًا.',
            'avatar.string' => 'رابط الصورة الشخصية غير صالح.',
            'password.min' => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.',
            'password.max' => 'كلمة المرور لا يجب أن تتجاوز 255 حرفًا.',
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            if ($this->filled('password')) {
                $user = $this->user();
                if ($user && ! empty($user->password)) {
                    $currentPassword = (string) $this->input('current_password', '');
                    if (! Hash::check($currentPassword, $user->password)) {
                        $validator->errors()->add('current_password', 'كلمة المرور الحالية غير صحيحة.');
                    }
                }
            }
        });
    }
}
