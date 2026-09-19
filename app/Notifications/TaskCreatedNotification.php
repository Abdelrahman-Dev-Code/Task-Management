<?php

namespace App\Notifications;

use App\Models\Task;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class TaskCreatedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public Task $task) {}

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('تمت إضافة مهمة جديدة')
            ->greeting('مرحباً '.$notifiable->name)
            ->line('تمت إضافة مهمة جديدة بنجاح على حسابك.')
            ->line('العنوان: '.$this->task->title)
            ->line('الحالة: '.$this->task->status)
            ->line('الأولوية: '.$this->task->priority)
            ->action('عرض المهام', config('app.url').'/api/tasks')
            ->line('شكراً لاستخدامك لوحة المهام.');
    }
}
