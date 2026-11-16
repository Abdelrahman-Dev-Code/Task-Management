import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// حقل إدخال رمز OTP مقسّم إلى 6 خانات بتجربة سلسة (تنقل تلقائي ودعم اللصق)
class OtpCodeInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final String? initialCode;

  const OtpCodeInput({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.initialCode,
  });

  @override
  State<OtpCodeInput> createState() => OtpCodeInputState();
}

class OtpCodeInputState extends State<OtpCodeInput> {
  static const int _length = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());
    if (widget.initialCode != null) {
      setCode(widget.initialCode!);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// تعبئة الرمز برمجياً (مثل زر التعبئة السريعة أو عند اللصق)
  void setCode(String code) {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    _notify();
  }

  String get currentCode => _controllers.map((c) => c.text).join();

  void _notify() {
    final code = currentCode;
    widget.onChanged(code);
    if (code.length == _length) {
      widget.onCompleted?.call(code);
    }
  }

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // دعم لصق الرمز كاملاً دفعة واحدة في أي خانة
      setCode(digits);
      _focusNodes[_length - 1].requestFocus();
      return;
    }

    if (digits.isNotEmpty) {
      _controllers[index].text = digits[0];
      if (index < _length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_length, (index) {
          return SizedBox(
            width: 46,
            height: 56,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => _handleChanged(index, v),
            ),
          );
        }),
      ),
    );
  }
}
