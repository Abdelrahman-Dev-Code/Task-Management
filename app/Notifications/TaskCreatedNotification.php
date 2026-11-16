<?php

namespace App\Notifications;

use App\Models\Task;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class TaskCreatedNotification extends Notification
{
    use Queueable;

    public function __construct(public readonly Task $task) {}

    /**
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject("تمت إضافة مهمة جديدة: {$this->task->title}")
            ->greeting('مرحبًا '.($notifiable->name ?? ''))
            ->line("تم إنشاء مهمة جديدة بعنوان: {$this->task->title}")
            ->line("الحالة: {$this->task->status} | الأولوية: {$this->task->priority}");
    }
}
