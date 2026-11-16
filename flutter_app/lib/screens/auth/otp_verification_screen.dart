import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/session_controller.dart';
import '../../widgets/otp_code_input.dart';

/// شاشة التحقق من رمز OTP المكون من 6 أرقام لتأكيد البريد أو تسجيل الدخول
class OtpVerificationScreen extends StatefulWidget {
  final SessionController session;
  final String email;
  final String purpose; // verify_email | login | reset_password
  final String? initialDevOtp;

  const OtpVerificationScreen({
    super.key,
    required this.session,
    required this.email,
    required this.purpose,
    this.initialDevOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final GlobalKey<OtpCodeInputState> _otpInputKey = GlobalKey<OtpCodeInputState>();
  String _code = '';
  Timer? _timer;
  int _cooldownSeconds = 30;
  bool _loading = false;
  String? _error;
  String? _devOtp;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.initialDevOtp;
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 30]) {
    _timer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _verify([String? submittedCode]) async {
    final code = (submittedCode ?? _code).trim();
    if (code.length != 6) {
      setState(() => _error = 'يرجى إدخال رمز مكون من 6 أرقام.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.session.authService.verifyOtp(
        email: widget.email,
        otp: code,
        purpose: widget.purpose,
      );

      if (!mounted) return;
      if (result.user != null) {
        widget.session.setAuthenticatedUser(result.user!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );

      if (widget.purpose == 'login') {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.session.authService.sendOtp(
        email: widget.email,
        purpose: widget.purpose,
      );
      setState(() => _devOtp = result.devOtp);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } on ApiException catch (e) {
      if (e.retryAfterSeconds != null && e.retryAfterSeconds! > 0) {
        _startCooldown(e.retryAfterSeconds!);
      }
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (widget.purpose) {
      'login' => 'تسجيل الدخول برمز التحقق',
      'reset_password' => 'تأكيد رمز استعادة كلمة المرور',
      _ => 'تأكيد البريد الإلكتروني',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 52,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل الرمز المكون من 6 أرقام المرسل إلى:\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      if (_devOtp != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'رمز التطوير: $_devOtp',
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _otpInputKey.currentState?.setCode(_devOtp!);
                                },
                                child: const Text('تعبئة'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      OtpCodeInput(
                        key: _otpInputKey,
                        onChanged: (value) => _code = value,
                        onCompleted: (value) {
                          if (!_loading) _verify(value);
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : () => _verify(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('تأكيد الرمز'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: (_loading || _cooldownSeconds > 0) ? null : _resend,
                        child: Text(
                          _cooldownSeconds > 0
                              ? 'إعادة الإرسال بعد $_cooldownSeconds ثانية'
                              : 'إعادة إرسال رمز التحقق',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
