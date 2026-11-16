import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/app_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'desktop_oauth.dart';

class AuthPayload {
  final UserModel user;
  final String token;
  final String message;
  final bool otpRequired;
  final String? devOtp;

  const AuthPayload({
    required this.user,
    required this.token,
    required this.message,
    this.otpRequired = false,
    this.devOtp,
  });
}

class OtpSendResult {
  final String purpose;
  final int expiresInSeconds;
  final String message;
  final String? devOtp;

  const OtpSendResult({
    required this.purpose,
    required this.expiresInSeconds,
    required this.message,
    this.devOtp,
  });
}

class OtpVerifyResult {
  final bool verified;
  final UserModel? user;
  final String? token;
  final String? resetToken;
  final String message;

  const OtpVerifyResult({
    required this.verified,
    this.user,
    this.token,
    this.resetToken,
    required this.message,
  });
}

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  String get _deviceName {
    if (kIsWeb) return 'flutter-web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'flutter-android',
      TargetPlatform.iOS => 'flutter-ios',
      TargetPlatform.windows => 'flutter-windows',
      TargetPlatform.macOS => 'flutter-macos',
      TargetPlatform.linux => 'flutter-linux',
      TargetPlatform.fuchsia => 'flutter-fuchsia',
    };
  }

  Future<AuthPayload> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _client.post('/api/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'device_name': _deviceName,
    });

    final token = data['token'] as String;
    await _client.setToken(token);

    return AuthPayload(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: token,
      message: (data['message'] as String?) ?? 'تم إنشاء الحساب بنجاح.',
      otpRequired: (data['otp_required'] as bool?) ?? false,
      devOtp: data['dev_otp'] as String?,
    );
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post('/api/login', body: {
      'email': email,
      'password': password,
      'device_name': _deviceName,
    });

    final token = data['token'] as String;
    await _client.setToken(token);

    return AuthPayload(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: token,
      message: (data['message'] as String?) ?? 'تم تسجيل الدخول بنجاح.',
    );
  }

  Future<OtpSendResult> sendOtp({
    required String email,
    required String purpose,
  }) async {
    final data = await _client.post('/api/otp/send', body: {
      'email': email,
      'purpose': purpose,
    });

    return OtpSendResult(
      purpose: (data['purpose'] as String?) ?? purpose,
      expiresInSeconds: (data['expires_in_seconds'] as num? ?? 600).toInt(),
      message: (data['message'] as String?) ?? 'تم إرسال رمز التحقق.',
      devOtp: data['dev_otp'] as String?,
    );
  }

  Future<OtpVerifyResult> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    final data = await _client.post('/api/otp/verify', body: {
      'email': email,
      'otp': otp,
      'purpose': purpose,
      'device_name': '$_deviceName-otp',
    });

    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _client.setToken(token);
    }

    return OtpVerifyResult(
      verified: (data['verified'] as bool?) ?? true,
      user: data['user'] != null
          ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
          : null,
      token: token,
      resetToken: data['reset_token'] as String?,
      message: (data['message'] as String?) ?? 'تم التحقق من الرمز بنجاح.',
    );
  }

  Future<OtpSendResult> forgotPassword(String email) async {
    final data = await _client.post('/api/password/forgot', body: {'email': email});
    return OtpSendResult(
      purpose: 'reset_password',
      expiresInSeconds: (data['expires_in_seconds'] as num? ?? 600).toInt(),
      message: (data['message'] as String?) ?? 'تم إرسال رمز استعادة كلمة المرور.',
      devOtp: data['dev_otp'] as String?,
    );
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final data = await _client.post('/api/password/reset', body: {
      'email': email,
      'otp': otp,
      'password': password,
    });
    return (data['message'] as String?) ?? 'تم إعادة تعيين كلمة المرور بنجاح.';
  }

  /// تسجيل الدخول عبر جوجل مع دعم تلقائي لكل المنصات:
  /// - Android / iOS / Web / macOS (مع Client ID): GoogleSignIn الأصلي
  /// - Windows / Linux (أو macOS بدون Client ID): تدفق المتصفح Loopback OAuth2
  Future<AuthPayload> continueWithGoogle() async {
    final isWindowsOrLinux = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    final isMacWithoutNativeClientId = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.macOS &&
        AppConfig.googleServerClientId.isEmpty;

    if (isWindowsOrLinux || isMacWithoutNativeClientId) {
      return runDesktopGoogleOAuth(_client);
    }

    if (kIsWeb && AppConfig.googleServerClientId.isEmpty) {
      throw const ApiException(
        0,
        'لتسجيل الدخول عبر جوجل على الويب، مرر --dart-define=GOOGLE_CLIENT_ID.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: kIsWeb ? AppConfig.googleServerClientId : null,
      serverClientId:
          !kIsWeb && AppConfig.googleServerClientId.isNotEmpty
              ? AppConfig.googleServerClientId
              : null,
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw const ApiException(0, 'تم إلغاء تسجيل الدخول عبر جوجل.');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;

    if ((idToken == null || idToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      throw const ApiException(
        0,
        'تعذر الحصول على رمز جوجل. تأكد من إعداد GOOGLE_CLIENT_ID على المنصة.',
      );
    }

    final data = await _client.post('/api/auth/google', body: {
      if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
      if (accessToken != null && accessToken.isNotEmpty) 'access_token': accessToken,
      'device_name': '$_deviceName-google',
    });

    final token = data['token'] as String;
    await _client.setToken(token);

    return AuthPayload(
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: token,
      message: (data['message'] as String?) ?? 'تم تسجيل الدخول باستخدام جوجل.',
    );
  }

  Future<UserModel> getCurrentUser() async {
    final data = await _client.get('/api/user');
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final data = await _client.put('/api/user', body: {
      if (name != null) 'name': name,
      if (newPassword != null && newPassword.isNotEmpty) ...{
        'password': newPassword,
        if (currentPassword != null) 'current_password': currentPassword,
      },
    });
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout({bool allDevices = false}) async {
    try {
      await _client.post(allDevices ? '/api/logout-all' : '/api/logout');
    } finally {
      await _client.setToken(null);
    }
  }
}
