<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class OtpCodeNotification extends Notification
{
    use Queueable;

    public function __construct(
        public readonly string $code,
        public readonly string $purpose,
        public readonly int $ttlMinutes = 10,
    ) {}

    /**
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $purposeLabel = match ($this->purpose) {
            'login' => 'تسجيل الدخول السريع',
            'reset_password' => 'إعادة تعيين كلمة المرور',
            default => 'تأكيد البريد الإلكتروني',
        };

        return (new MailMessage)
            ->subject("رمز التحقق ({$this->code}) - {$purposeLabel}")
            ->greeting('مرحبًا '.($notifiable->name ?? ''))
            ->line("رمز التحقق الخاص بك لغرض {$purposeLabel} هو:")
            ->line("**{$this->code}**")
            ->line("ينتهي هذا الرمز خلال {$this->ttlMinutes} دقائق.")
            ->line('إذا لم تطلب هذا الرمز، يمكنك تجاهل هذه الرسالة بأمان.');
    }
}
