<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateRequestTask extends FormRequest
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
        $titleRule = $this->isMethod('patch')
            ? ['sometimes', 'required', 'string', 'max:255']
            : ['required', 'string', 'max:255'];

        return [
            'title' => $titleRule,
            'description' => ['sometimes', 'nullable', 'string'],
            'status' => ['sometimes', 'nullable', Rule::in(['Pending', 'In Progress', 'Completed'])],
            'priority' => ['sometimes', 'nullable', Rule::in(['Low', 'Medium', 'High'])],
            'due_date' => ['sometimes', 'nullable', 'date'],
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
