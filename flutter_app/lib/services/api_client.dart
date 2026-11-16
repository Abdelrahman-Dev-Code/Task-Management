import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';

/// استثناء موحّد يمثل أخطاء الشبكة أو استجابات الخادم غير الناجحة
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  final int? retryAfterSeconds;

  const ApiException(
    this.statusCode,
    this.message, {
    this.errors,
    this.retryAfterSeconds,
  });

  @override
  String toString() => message;
}

/// عميل HTTP مركزي يدير التوكن، Keep-Alive، عنوان الخادم، المهلة الزمنية، ومعالجة الأخطاء
class ApiClient {
  static const _tokenKey = 'auth_token';
  static const _baseUrlKey = 'api_base_url';
  static const Duration _timeout = Duration(seconds: 15);

  /// استخدام عميل HTTP دائم (Keep-Alive) لتسريع الاتصالات المتكررة
  final http.Client _http = http.Client();

  String? _token;
  String _baseUrl = AppConfig.defaultBaseUrl;
  VoidCallback? onUnauthorized;

  String get baseUrl => _baseUrl;
  String? get token => _token;

  /// تهيئة العميل واستعادة الجلسة وعنوان الخادم المحفوظين
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = savedUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
  }

  /// حفظ أو مسح رمز المصادقة (Bearer Token)
  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  /// تحديث عنوان الخادم الأساسي وحفظه محلياً
  Future<void> setBaseUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    _baseUrl = normalized.isEmpty ? AppConfig.defaultBaseUrl : normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$cleanPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _send(
    String path,
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(_timeout);
      return _decode(path, response);
    } on TimeoutException {
      throw const ApiException(408, 'انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى.');
    } on http.ClientException {
      throw const ApiException(
        0,
        'تعذر الوصول إلى الخادم. تحقق من اتصال الإنترنت أو عنوان الخادم.',
      );
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send(path, () => _http.get(_uri(path, query), headers: _headers()));
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send(
      path,
      () => _http.post(
        _uri(path),
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) {
    return _send(
      path,
      () => _http.put(
        _uri(path),
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) {
    return _send(
      path,
      () => _http.patch(
        _uri(path),
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send(path, () => _http.delete(_uri(path), headers: _headers()));
  }

  /// قياس سرعة الاستجابة وفحص جاهزية الخادم
  Future<int> pingHealth() async {
    final sw = Stopwatch()..start();
    await get('/api/health');
    sw.stop();
    return sw.elapsedMilliseconds;
  }

  Map<String, dynamic> _decode(String path, http.Response response) {
    Map<String, dynamic> payload = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        }
      } catch (_) {
        payload = <String, dynamic>{};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    // معالجة انتهاء الجلسة تلقائياً للطلبات المحمية
    final isPublicAuthPath = path.contains('/login') ||
        path.contains('/register') ||
        path.contains('/otp') ||
        path.contains('/password/') ||
        path.contains('/auth/google');

    if (response.statusCode == 401 && !isPublicAuthPath && _token != null) {
      onUnauthorized?.call();
    }

    final message = (payload['message'] as String?) ??
        'تعذر الاتصال بالخادم (رمز الحالة: ${response.statusCode}).';
    throw ApiException(
      response.statusCode,
      message,
      errors: payload['errors'] as Map<String, dynamic>?,
      retryAfterSeconds: (payload['retry_after_seconds'] as num?)?.toInt(),
    );
  }

  void dispose() {
    _http.close();
  }
}
