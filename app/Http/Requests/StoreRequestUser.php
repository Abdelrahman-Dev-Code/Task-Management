<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreRequestUser extends FormRequest
{
    /**
     * Description: Determine if the user is authorized to make this request.
     *
     * @author Abdelrahman-Dev-Code
     *   * @created 2026-08-22
     *
     * @modified 2026-08-22
     *
     * @version 1
     *
     * @return array
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Description: Get the validation rules that apply to the request.
     *
     * @author Abdelrahman-Dev-Code
     *
     * @created 2026-08-22
     *
     * @modified 2026-08-22
     *
     * @version 1
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6', 'max:255'],
        ];
    }

    /**
     * Description:
     *
     * @author Abdelrahman-Dev-Code
     *
     * @created 2026-08-22
     *
     * @modified 2026-08-22
     *
     * @version 1
     */
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
            'password.max' => 'كلمة المرور لا يجب أن تتجاوز 255 حرفًا.',
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
