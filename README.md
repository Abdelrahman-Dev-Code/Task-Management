# Task Management — Laravel 13 API + Flutter App

نظام إدارة مهام متكامل يعمل بنظام **API-Only** مبني على **Laravel 13 + Sanctum** مع نظام تحقق **OTP** عبر البريد الإلكتروني، و**المتابعة باستخدام جوجل (Google OAuth / Sign-In)**، ومربوط بتطبيق **Flutter** متكامل (`flutter_app/`) متوافق مع الجوال والويب وسطح المكتب.

> **ملاحظة حول بيئة المعاينة السحابية:**
> يضم المشروع أيضًا خادم معاينة متطابق بالـ Node.js (`server.ts`) على المنفذ `3000` يعمل داخل بيئة المعاينة (التي تدعم Node.js)، بينما عند تحميل المشروع على جهازك أو استضافته يمكنك تشغيل **خادم Laravel الكامل** على المنفذ `8000` وربط تطبيق Flutter به مباشرة.

---

## 1. البنية المعمارية للمشروع
- **الباكاند الأساسي (Laravel 13 API-Only)**:
  - `app/Repositories/`: نمط المستودعات (`BaseRepository`, `UserRepository`, `TaskRepository`) مع واجهات مربوطة في `RepositoryServiceProvider`.
  - `app/Services/`: طبقة المنطق (`AuthService`, `OtpService`, `GoogleAuthService`, `TaskService`).
  - `app/Http/Controllers/`: (`AuthController`, `OtpController`, `GoogleAuthController`, `TaskController`, `NotificationController`).
  - `app/Http/Requests/` و `app/Http/Resources/`: تحقق بالعربية وعقود JSON متطابقة 100% مع Flutter.
  - `database/migrations/` و `database/seeders/`: الجداول كاملة (`users`, `tasks`, `personal_access_tokens`, `otp_codes`, `app_notifications`).
  - `tests/Feature/`: اختبارات Pest شاملة للمصادقة، OTP، Google Auth، المهام، والإشعارات.
- **تطبيق الواجهات (Flutter)**: داخل مجلد `flutter_app/` (`lib/core/`, `lib/models/`, `lib/services/`, `lib/widgets/`, `lib/screens/`).

---

## 2. تشغيل باكاند Laravel على جهازك
تأكد من توفر **PHP 8.3+** و **Composer**، ثم نفّذ:
```bash
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```
أو باختصار:
```bash
composer run setup
composer run dev
```

لتشغيل اختبارات Pest:
```bash
php artisan test
```

### الحساب التجريبي الجاهز بعد الـ Seed
- **البريد الإلكتروني**: `ahmed@example.com`
- **كلمة المرور**: `12345678`

---

## 3. تشغيل تطبيق Flutter على جميع الأجهزة (Windows / Mac / Linux / Android / iOS / Web)
تأكد من توفر **Flutter SDK**، ثم نفّذ:
```bash
cd flutter_app
flutter create . --platforms=android,ios,web,windows,macos,linux
flutter pub get

# تشغيل على Windows أو macOS أو Linux أو iOS أو Web مع خادم Laravel المحلي:
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
# أو -d macos / -d linux / -d chrome

# تشغيل على محاكي Android:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
- **Windows / macOS / Linux / iOS Simulator / Web**: استخدم `http://127.0.0.1:8000` (أو `127.0.0.1:3000` لمعاينة Node.js).
- **محاكي Android**: استخدم `http://10.0.2.2:8000`.
- **جهاز جوال حقيقي**: استخدم عنوان IP جهازك على نفس شبكة Wi-Fi مثل `http://192.168.1.15:8000`.
- **macOS (ملاحظة صلاحيات الشبكة)**: بعد تشغيل `flutter create` على الماك، أضف `<key>com.apple.security.network.client</key><true/>` في `macos/Runner/DebugProfile.entitlements` و `Release.entitlements`.

### إعداد Google Sign-In / OAuth
1. أضف في `.env` للباكاند:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET`
   - `GOOGLE_ALLOWED_CLIENT_IDS` (اختياري لدعم أكثر من عميل Android/iOS/Web)
   - `GOOGLE_REDIRECT_URI=https://your-domain.com/api/auth/google/callback`
2. مرر `GOOGLE_CLIENT_ID` لتطبيق Flutter عند البناء/التشغيل:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 --dart-define=GOOGLE_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
   ```
   (وعلى أندرويد أضف بصمة SHA-1 في Google Cloud Console، وعلى iOS أضف `REVERSED_CLIENT_ID` في `Info.plist`).

---

## 4. نقاط النهاية الرئيسية (API Endpoints)
- `GET /api/health` — فحص جاهزية الخادم
- `POST /api/register` | `POST /api/login` | `POST /api/logout` | `POST /api/logout-all`
- `GET /api/user` | `PUT /api/user`
- `POST /api/otp/send` | `POST /api/otp/verify` (`verify_email`, `login`, `reset_password`)
- `POST /api/auth/otp/request` | `POST /api/auth/otp/verify`
- `POST /api/password/forgot` | `POST /api/password/reset`
- `POST /api/auth/google` | `GET /api/auth/google/url` | `GET /api/auth/google/callback`
- `GET /api/tasks` (`search`, `status`, `priority`, `overdue=true`, `sort_by`, `sort_dir`, `page`, `per_page`)
- `GET /api/tasks/stats` | `POST /api/tasks` | `PUT/PATCH /api/tasks/{id}` | `DELETE /api/tasks/{id}` | `DELETE /api/tasks/completed`
- `GET /api/notifications` | `PATCH /api/notifications/{id}/read` | `POST /api/notifications/read-all`
