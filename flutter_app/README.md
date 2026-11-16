# Task Management — Flutter App (All Platforms)

تطبيق **لوحة المهام** المتكامل بواجهة Flutter متجاوبة تعمل على **جميع المنصات**:
- **سطح المكتب**: Windows، macOS، Linux
- **الجوال**: Android، iOS
- **الويب**: Chrome / Edge / Safari

---

## المميزات وتجربة المستخدم (UI/UX)
- **دعم كامل للعربية (RTL)** مع الوضع **الفاتح والداكن والتلقائي (Light / Dark / System)**.
- **تخطيط متجاوب لجميع الشاشات**:
  - شريط تنقل سفلي (`NavigationBar`) على الجوال و `NavigationRail` جانبي على التابلت وسطح المكتب.
  - عرض المهام في قائمة عمودية على الجوال وشبكة متعددة الأعمدة على الشاشات الكبيرة.
  - اختصارات لوحة المفاتيح على Windows/macOS/Linux: `Ctrl/Cmd + N` مهمة جديدة، `Ctrl/Cmd + F` بحث، `F5` أو `Ctrl/Cmd + R` تحديث.
- **سرعة وأداء عالٍ**:
  - اتصال HTTP دائم (`Keep-Alive`)، تخزين مؤقت فوري عند الفتح (`Cache-First`)، وترقيم مع التمرير اللانهائي (`Pagination`).
  - تحديث متفائل (`Optimistic UI`) لتغيير الحالة والإشعارات.
- **المصادقة الكاملة على كل المنصات**:
  - البريد وكلمة المرور + الحساب التجريبي (`ahmed@example.com` / `12345678`).
  - نظام OTP متكامل (تأكيد البريد، الدخول بدون كلمة مرور، استعادة كلمة المرور).
  - المتابعة باستخدام جوجل:
    - على **Android / iOS / Web**: عبر حزمة `google_sign_in`.
    - على **Windows / macOS / Linux**: عبر تدفق المتصفح الآمن (`Loopback OAuth2`) تلقائياً!

---

## خطوات التشغيل على جهازك (Windows / macOS / Linux / Android / iOS / Web)
1. انتقل إلى مجلد التطبيق:
   ```bash
   cd flutter_app
   ```
2. أنشئ مجلدات جميع المنصات دفعة واحدة دون استبدال `lib/` أو `pubspec.yaml`:
   ```bash
   flutter create . --platforms=android,ios,web,windows,macos,linux
   ```
3. ثبّت الحزم:
   ```bash
   flutter pub get
   ```
4. شغّل التطبيق على المنصة التي تريدها (أو على الخادم السحابي مباشرة دون تغيير):
   ```bash
   # على Windows
   flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000

   # على macOS
   flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8000

   # على Linux
   flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:8000

   # على الويب (Chrome)
   flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000

   # على محاكي Android
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
   ```
   *(ملاحظة مهمة لنظام **macOS**: بعد تشغيل `flutter create`، أضف `<key>com.apple.security.network.client</key><true/>` داخل ملفَي `macos/Runner/DebugProfile.entitlements` و `macos/Runner/Release.entitlements` للسماح للاتصالات الشبكية).*

---

## التصدير للإنتاج (Build)
```bash
flutter build windows      # مجلد .exe على Windows
flutter build macos        # تطبيق .app على Mac
flutter build linux        # حزمة Linux
flutter build apk          # تطبيق Android
flutter build ios          # تطبيق iOS
flutter build web          # نسخة الويب
```
