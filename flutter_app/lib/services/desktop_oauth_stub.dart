import 'api_client.dart';
import 'auth_service.dart';

/// تنفيذ بديل للويب حيث يتم الاعتماد على حزمة google_sign_in المخصصة للويب
Future<AuthPayload> runDesktopGoogleOAuth(ApiClient client) {
  throw const ApiException(
    0,
    'لتسجيل الدخول عبر جوجل على الويب، يرجى تمرير --dart-define=GOOGLE_CLIENT_ID.',
  );
}
