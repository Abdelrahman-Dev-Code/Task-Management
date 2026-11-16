import 'package:flutter/material.dart';
import '../../services/session_controller.dart';
import '../../widgets/server_url_dialog.dart';
import '../auth/otp_verification_screen.dart';

/// تبويب الحساب الشخصي: إدارة البيانات، كلمة المرور، المظهر، وفحص الاتصال
class ProfileTab extends StatefulWidget {
  final SessionController session;

  const ProfileTab({super.key, required this.session});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _busy = false;

  Future<void> _verifyEmailViaOtp() async {
    final user = widget.session.user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final result = await widget.session.authService.sendOtp(
        email: user.email,
        purpose: 'verify_email',
      );
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            session: widget.session,
            email: user.email,
            purpose: 'verify_email',
            initialDevOtp: result.devOtp,
          ),
        ),
      );
      if (verified == true) {
        await widget.session.refreshUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editName() async {
    final user = widget.session.user;
    if (user == null) return;
    final controller = TextEditingController(text: user.name);
    final updatedName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'الاسم الكامل'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updatedName == null || updatedName.isEmpty) return;

    try {
      await widget.session.authService.updateProfile(name: updatedName);
      await widget.session.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الاسم بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final nextCtrl = TextEditingController();
    final isGoogleOnly = widget.session.user?.provider == 'google';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isGoogleOnly) ...[
              TextField(
                controller: currentCtrl,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: nextCtrl,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة (6+ أحرف)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );

    final currentPassword = currentCtrl.text;
    final newPassword = nextCtrl.text;
    currentCtrl.dispose();
    nextCtrl.dispose();

    if (confirmed != true) return;
    if (newPassword.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل')),
        );
      }
      return;
    }

    try {
      await widget.session.authService.updateProfile(
        currentPassword: isGoogleOnly ? null : currentPassword,
        newPassword: newPassword,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _testConnection() async {
    try {
      final ms = await widget.session.apiClient.pingHealth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الاتصال بالخادم ممتاز (زمن الاستجابة: ${ms}ms)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user;
    if (user == null) return const SizedBox.shrink();

    final providerLabel = switch (user.provider) {
      'google' => 'حساب جوجل',
      'otp' => 'تحقق OTP',
      _ => 'بريد وكلمة مرور',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('الحساب الشخصي')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF4F46E5),
                        backgroundImage:
                            user.avatar != null ? NetworkImage(user.avatar!) : null,
                        child: user.avatar == null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0] : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          Chip(
                            avatar: Icon(
                              user.isEmailVerified ? Icons.verified : Icons.warning_amber,
                              size: 18,
                              color:
                                  user.isEmailVerified ? Colors.green : Colors.amber.shade800,
                            ),
                            label: Text(
                              user.isEmailVerified ? 'البريد مؤكد' : 'البريد غير مؤكد',
                            ),
                          ),
                          Chip(label: Text('المصادقة: $providerLabel')),
                        ],
                      ),
                      if (!user.isEmailVerified) ...[
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: _busy ? null : _verifyEmailViaOtp,
                          icon: const Icon(Icons.mark_email_read_outlined),
                          label: const Text('تأكيد البريد الإلكتروني عبر OTP'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'مظهر التطبيق',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto),
                            label: Text('تلقائي'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('فاتح'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('داكن'),
                          ),
                        ],
                        selected: {widget.session.themeMode},
                        onSelectionChanged: (s) => widget.session.setThemeMode(s.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('تعديل الاسم'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _editName,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset_outlined),
                      title: const Text('تغيير كلمة المرور'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.dns_outlined),
                      title: const Text('عنوان الخادم (API URL)'),
                      subtitle: Text(
                        widget.session.baseUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showServerUrlDialog(context, widget.session),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.speed_outlined),
                      title: const Text('فحص سرعة الاتصال بالخادم'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _testConnection,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                      onTap: () => widget.session.logout(allDevices: false),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.devices_other, color: Colors.red),
                      title: const Text(
                        'تسجيل الخروج من جميع الأجهزة',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => widget.session.logout(allDevices: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
