# Task Management

![Status](https://img.shields.io/badge/status-in%20progress-orange)
![Laravel](https://img.shields.io/badge/Laravel-PHP-red)

نظام ويب لإدارة المهام مبني باستخدام Laravel. المستودع مخصص لتطوير تطبيق عملي لإدارة المهام ومتابعة سير العمل.

## الحالة
**قيد العمل** — ما زالت الميزات والتحسينات قيد التطوير.

## التقنيات
- PHP وLaravel
- Blade
- Vite
- قاعدة بيانات عبر Laravel migrations
- PHPUnit للاختبارات

## التشغيل محليًا
```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
npm install
npm run build
php artisan serve
```

> عدّل إعدادات قاعدة البيانات في `.env` قبل تشغيل الترحيلات.

## هيكل المشروع
- `app/` منطق التطبيق
- `database/` الترحيلات والبيانات التجريبية
- `resources/` الواجهات والملفات الأمامية
- `routes/` مسارات التطبيق
- `tests/` الاختبارات

## خارطة الطريق
- [ ] توثيق الوظائف الأساسية
- [ ] إضافة اختبارات للميزات الرئيسية
- [ ] تحسين تجربة المستخدم
- [ ] إعداد CI للتحقق التلقائي

## المساهمة
أنشئ فرعًا مستقلًا، نفّذ التغيير، ثم افتح Pull Request مع وصف واضح.

## English summary
A Laravel-based task management web application. The project is currently under active development.
