# Task Management API (API-Only Backend)

واجهة برمجة تطبيقات (REST API) متكاملة لإدارة المهام والمصادقة، مصممة لربطها مع تطبيق **Flutter**.

## المميزات المكتملة في الباكاند
- **وضع API فقط** مع دعم CORS كامل لتطبيقات Flutter (Mobile / Web / Desktop).
- **المصادقة الكاملة**: التسجيل، تسجيل الدخول، تسجيل الخروج، تسجيل الخروج من جميع الأجهزة، وتحديث بيانات الحساب وكلمة المرور.
- **نظام OTP متكامل**:
  - إرسال رمز تحقق من 6 أرقام (`verify_email` لتأكيد البريد، `login` لتسجيل الدخول بدون كلمة مرور، `reset_password` لاستعادة كلمة المرور).
  - حد إعادة الإرسال (30 ثانية) وحد أقصى للمحاولات (5 محاولات) وصلاحية 10 دقائق.
  - إرسال فعلي عبر Resend API عند ضبط `RESEND_API_KEY`، أو إرجاع `dev_otp` في بيئة التطوير لتسهيل اختبار Flutter.
- **المتابعة باستخدام جوجل (Continue with Google)**:
  - `POST /api/auth/google` للتحقق من `id_token` أو `access_token` القادم من حزمة `google_sign_in` في Flutter.
  - `GET /api/auth/google/url` و `GET /api/auth/google/callback` لتدفق OAuth2 عبر المتصفح.
- **إدارة المهام الكاملة (CRUD + Analytics)**:
  - إنشاء، عرض، تعديل كامل (`PUT`)، تعديل جزئي (`PATCH`)، حذف، وحذف المهام المكتملة.
  - البحث، الفلترة (`status`, `priority`)، الترتيب (`sort_by`, `sort_dir`)، الترقيم (`page`, `per_page`)، وتاريخ الاستحقاق (`due_date`) وإحصائيات المهام (`GET /api/tasks/stats`).
- **الإشعارات**: `GET /api/notifications` و `PATCH /api/notifications/:id/read` و `POST /api/notifications/read-all`.

## التشغيل محليًا
```bash
npm install
npm run dev
```

## الحساب التجريبي الجاهز للاختبار
- **البريد الإلكتروني**: `ahmed@example.com`
- **كلمة المرور**: `12345678`
