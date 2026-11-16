<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\Task;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::firstOrCreate(
            ['email' => 'ahmed@example.com'],
            [
                'name' => 'أحمد محمد',
                'provider' => 'local',
                'email_verified_at' => now(),
                'password' => Hash::make('12345678'),
            ]
        );

        if ($user->tasks()->count() === 0) {
            $tasks = [
                [
                    'title' => 'إعداد واجهات برمجة التطبيقات للمصادقة',
                    'description' => 'تجهيز نقاط النهاية الخاصة بتسجيل الدخول و OTP والمتابعة باستخدام جوجل.',
                    'status' => 'Completed',
                    'priority' => 'High',
                ],
                [
                    'title' => 'ربط تطبيق Flutter مع لوحة المهام',
                    'description' => 'تنفيذ شاشات المصادقة وعرض المهام وإدارتها عبر REST API.',
                    'status' => 'In Progress',
                    'priority' => 'High',
                ],
                [
                    'title' => 'اختبار مسارات التحقق من رمز OTP',
                    'description' => 'التأكد من عمل إرسال والتحقق من رمز OTP لتأكيد البريد وتسجيل الدخول.',
                    'status' => 'Pending',
                    'priority' => 'Medium',
                ],
                [
                    'title' => 'تحديث وثائق API لفريق الموبايل',
                    'description' => 'توضيح صيغ الطلبات والاستجابات لجميع نقاط النهاية في README.',
                    'status' => 'Pending',
                    'priority' => 'Low',
                ],
            ];

            foreach ($tasks as $taskData) {
                $user->tasks()->create($taskData);
            }

            AppNotification::create([
                'user_id' => $user->id,
                'type' => 'welcome',
                'title' => 'مرحباً بك في واجهة برمجة تطبيقات إدارة المهام',
                'body' => 'حسابك التجريبي جاهز للاستخدام مع تطبيق Flutter.',
            ]);
        }
    }
}
