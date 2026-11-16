<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreRequestTask extends FormRequest
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
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status' => ['nullable', Rule::in(['Pending', 'In Progress', 'Completed'])],
            'priority' => ['nullable', Rule::in(['Low', 'Medium', 'High'])],
            'due_date' => ['nullable', 'date'],
        ];
    }

    /**
     * @return array<string, string>
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
            'due_date.date' => 'صيغة تاريخ الاستحقاق غير صحيحة.',
        ];
    }
}
