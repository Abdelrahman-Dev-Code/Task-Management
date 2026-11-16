import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// تدفق Google OAuth2 لسطح المكتب (Windows / macOS / Linux) عبر خادم Loopback محلي
Future<AuthPayload> runDesktopGoogleOAuth(ApiClient client) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final redirectUri = 'http://127.0.0.1:${server.port}/callback';
  final state = _randomState();

  try {
    final urlData = await client.get(
      '/api/auth/google/url',
      query: {
        'redirect_uri': redirectUri,
        'state': state,
      },
    );

    final authUrl = urlData['url'] as String?;
    if (authUrl == null || authUrl.isEmpty) {
      throw const ApiException(500, 'تعذر إنشاء رابط تسجيل الدخول عبر جوجل.');
    }

    final launched = await launchUrl(
      Uri.parse(authUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw const ApiException(0, 'تعذر فتح المتصفح لإتمام تسجيل الدخول عبر جوجل.');
    }

    final HttpRequest callbackReq = await server
        .firstWhere((req) => req.uri.path == '/callback')
        .timeout(
          const Duration(minutes: 2),
          onTimeout: () => throw const ApiException(
            408,
            'انتهت مهلة إتمام تسجيل الدخول عبر المتصفح.',
          ),
        );

    final query = callbackReq.uri.queryParameters;
    final error = query['error'];
    final code = query['code'];
    final returnedState = query['state'];

    if (error != null && error.isNotEmpty) {
      await _sendHtml(
        callbackReq.response,
        title: 'تم إلغاء تسجيل الدخول',
        body: 'تم إلغاء المصادقة عبر جوجل ($error). يمكنك إغلاق هذه النافذة والعودة للتطبيق.',
        success: false,
      );
      throw ApiException(400, 'تم إلغاء تسجيل الدخول عبر جوجل: $error');
    }

    if (returnedState != state || code == null || code.isEmpty) {
      await _sendHtml(
        callbackReq.response,
        title: 'بيانات تحقق غير صالحة',
        body: 'فشل التحقق الأمني من الجلسة. يرجى المحاولة مرة أخرى من داخل التطبيق.',
        success: false,
      );
      throw const ApiException(422, 'رمز التفويض أو حالة الأمان (state) غير صالحة.');
    }

    final authData = await client.get(
      '/api/auth/google/callback',
      query: {
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    final token = authData['token'] as String;
    await client.setToken(token);

    await _sendHtml(
      callbackReq.response,
      title: 'تم تسجيل الدخول بنجاح',
      body: 'أهلاً بك! يمكنك إغلاق هذه النافذة والعودة إلى تطبيق لوحة المهام.',
      success: true,
    );

    return AuthPayload(
      user: UserModel.fromJson(authData['user'] as Map<String, dynamic>),
      token: token,
      message: (authData['message'] as String?) ?? 'تم تسجيل الدخول باستخدام جوجل بنجاح.',
    );
  } finally {
    await server.close(force: true);
  }
}

String _randomState() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

Future<void> _sendHtml(
  HttpResponse response, {
  required String title,
  required String body,
  required bool success,
}) async {
  response.statusCode = success ? HttpStatus.ok : HttpStatus.badRequest;
  response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
  final accent = success ? '#4F46E5' : '#DC2626';
  response.write('''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$title</title>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; background: #F8FAFC; color: #0F172A; display: grid; place-items: center; min-height: 100vh; margin: 0; }
    .card { background: #fff; padding: 32px; border-radius: 18px; max-width: 420px; text-align: center; box-shadow: 0 12px 32px rgba(15,23,42,.08); border-top: 5px solid $accent; }
    h1 { font-size: 20px; margin: 0 0 12px; color: $accent; }
    p { font-size: 15px; line-height: 1.6; color: #475569; margin: 0; }
  </style>
</head>
<body>
  <div class="card">
    <h1>$title</h1>
    <p>$body</p>
  </div>
</body>
</html>
''');
  await response.close();
}
