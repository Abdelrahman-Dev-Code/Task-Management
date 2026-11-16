# Task Management — Flutter App

تطبيق **لوحة المهام** المتكامل بواجهة Flutter متجاوبة (`Mobile / Tablet / Web / Desktop`) ومربوط بالكامل مع خادم **Task Management REST API**.

## المميزات وتجربة المستخدم (UI/UX)
- **دعم كامل للعربية (RTL)** مع مظهر **فاتح وداكن وتلقائي (Light / Dark / System)**.
- **تخطيط متجاوب لجميع الأجهزة**:
  - شريط تنقل سفلي (`NavigationBar`) على الجوال و`NavigationRail` جانبي على التابلت وسطح المكتب.
  - عرض المهام في قائمة عمودية على الجوال وشبكة متعددة الأعمدة على الشاشات الكبيرة.
  - شاشة دخول مقسمة (`Split Layout`) على الشاشات الواسعة.
- **أداء وسلاسة**:
  - بحث فوري مع Debounce (`350ms`) لتقليل الطلبات.
  - تحديث متفائل (Optimistic UI) عند تغيير حالة المهمة مع تراجع تلقائي عند فشل الشبكة.
  - شاشات تحميل هيكلية (`Skeleton Loader`)، وتفاصيل مهمة كاملة عبر `TaskDetailSheet`.
  - حقل إدخال رمز OTP مقسّم إلى 6 خانات (`OtpCodeInput`) مع دعم اللصق والتعبئة التلقائية.
- **المصادقة الكاملة**:
  - البريد وكلمة المرور + الحساب التجريبي (`ahmed@example.com` / `12345678`).
  - نظام OTP متكامل (تأكيد البريد، الدخول بدون كلمة مرور، استعادة كلمة المرور).
  - المتابعة باستخدام جوجل (`google_sign_in` -> `POST /api/auth/google`).
- **إعدادات الحساب**: تعديل الاسم، تغيير كلمة المرور، فحص سرعة الاتصال بالخادم، وتبديل عنوان الخادم من داخل التطبيق.

## خطوات التشغيل على جهازك
1. انتقل إلى مجلد التطبيق:
   ```bash
   cd flutter_app
   ```
2. أنشئ ملفات المنصات (Android / iOS / Web) دون استبدال `lib/` أو `pubspec.yaml`:
   ```bash
   flutter create . --platforms=android,ios,web
   ```
3. ثبّت الحزم وشغّل التطبيق:
   ```bash
   flutter pub get
   flutter run
   ```

## عند إرفاق مفاتيح جوجل لاحقًا
1. شغّل التطبيق مع تمرير `GOOGLE_CLIENT_ID`:
   ```bash
   flutter run --dart-define=GOOGLE_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
   ```
2. بالنسبة لـ **Android**: أضف `SHA-1` في Google Cloud / Firebase Console.
3. بالنسبة لـ **iOS**: أضف `CFBundleURLTypes` (`REVERSED_CLIENT_ID`) في `ios/Runner/Info.plist`.
4. بالنسبة للخادم: أضف `GOOGLE_CLIENT_ID` و `GOOGLE_CLIENT_SECRET` في `.env` على الخادم.
