<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreRequestTask extends FormRequest
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
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'status' => 'nullable|in:Pending,In Progress,Completed',
            'priority' => 'nullable|in:Low,Medium,High',
            'user_id' => 'required|exists:users,id',
        ];
    }

    /**
     * Custom validation messages in Arabic.
     */
    public function messages(): array
    {
        return [
            'title.required' => 'حقل العنوان مطلوب.',
            'title.string' => 'يجب أن يكون العنوان نصًا.',
            'title.max' => 'لا يجوز أن يتجاوز العنوان 255 حرفًا.',

            'description.string' => 'يجب أن يكون الوصف نصًا.',

            'status.in' => 'الحالة المختارة غير موجودة في النطاق المسموح.',
            'priority.in' => 'الأولوية المختارة غير موجودة في النطاق المسموح.',

            'user_id.required' => 'حقل معرف المستخدم مطلوب.',
            'user_id.exists' => 'المستخدم المحدد غير موجود.',
        ];
    }
}
