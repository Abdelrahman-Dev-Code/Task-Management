import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../services/session_controller.dart';
import '../../widgets/server_url_dialog.dart';
import 'forgot_password_screen.dart';
import 'otp_login_screen.dart';
import 'register_screen.dart';

/// شاشة تسجيل الدخول الرئيسية مع دعم البريد وكلمة المرور، OTP، وجوجل
class LoginScreen extends StatefulWidget {
  final SessionController session;

  const LoginScreen({super.key, required this.session});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.session.authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.session.setAuthenticatedUser(result.user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _demoLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.session.authService.login(
        email: 'ahmed@example.com',
        password: '12345678',
      );
      widget.session.setAuthenticatedUser(result.user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.session.authService.continueWithGoogle();
      widget.session.setAuthenticatedUser(result.user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildHeroCard({required bool expanded}) {
    return Container(
      padding: EdgeInsets.all(expanded ? 32 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Text(
                'مرحباً بعودتك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'سجّل دخولك للوصول إلى لوحة المهام وإدارة أولوياتك اليومية بسهولة وسلاسة.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          if (expanded) ...[
            const SizedBox(height: 24),
            const _HeroFeature(text: 'إدارة كاملة للمهام مع البحث والفلترة الفورية'),
            const SizedBox(height: 10),
            const _HeroFeature(text: 'تسجيل دخول مرن عبر كلمة المرور أو OTP أو جوجل'),
            const SizedBox(height: 10),
            const _HeroFeature(text: 'تجربة متجاوبة بالكامل على الجوال والتابلت والويب'),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تسجيل الدخول',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
                  if (!v.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _loading ? null : _submitLogin(),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                  if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(session: widget.session),
                            ),
                          ),
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: _loading ? null : _submitLogin,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تسجيل الدخول', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _googleSignIn,
                icon: const Icon(Icons.g_mobiledata, size: 26),
                label: const Text('المتابعة باستخدام جوجل'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OtpLoginScreen(session: widget.session),
                          ),
                        ),
                icon: const Icon(Icons.pin_outlined),
                label: const Text('تسجيل الدخول عبر رمز التحقق (OTP)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _loading ? null : _demoLogin,
                child: const Text('الدخول السريع بالحساب التجريبي'),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ليس لديك حساب؟'),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(session: widget.session),
                              ),
                            ),
                    child: const Text('إنشاء حساب جديد'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = !Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المهام'),
        actions: [
          IconButton(
            tooltip: 'إعداد عنوان الخادم',
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => showServerUrlDialog(context, widget.session),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 920 : 440),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildHeroCard(expanded: true)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildFormCard(theme)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroCard(expanded: false),
                        const SizedBox(height: 18),
                        _buildFormCard(theme),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  final String text;

  const _HeroFeature({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }
}
