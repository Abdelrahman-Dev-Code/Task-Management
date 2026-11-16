import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'task_service.dart';

/// وحدة التحكم المركزية لحالة الجلسة، السمات (فاتح/داكن)، والخدمات
class SessionController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';

  final ApiClient apiClient = ApiClient();
  late final AuthService authService = AuthService(apiClient);
  late final TaskService taskService = TaskService(apiClient);
  late final NotificationService notificationService = NotificationService(apiClient);

  UserModel? _user;
  bool _initialized = false;
  int _unreadNotifications = 0;
  ThemeMode _themeMode = ThemeMode.system;

  UserModel? get user => _user;
  bool get isInitialized => _initialized;
  bool get isAuthenticated => _user != null;
  int get unreadNotifications => _unreadNotifications;
  String get baseUrl => apiClient.baseUrl;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    await apiClient.init();
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    _themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    if (apiClient.token != null && apiClient.token!.isNotEmpty) {
      try {
        _user = await authService.getCurrentUser();
        await refreshUnreadCount();
      } catch (_) {
        await apiClient.setToken(null);
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeKey, value);
  }

  void setAuthenticatedUser(UserModel user) {
    _user = user;
    notifyListeners();
    refreshUnreadCount();
  }

  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    _user = await authService.getCurrentUser();
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    if (!isAuthenticated) return;
    try {
      final feed = await notificationService.getNotifications();
      _unreadNotifications = feed.unreadCount;
      notifyListeners();
    } catch (_) {
      // تجاهل الأخطاء العابرة أثناء تحديث شارة الإشعارات بالخلفية
    }
  }

  void updateUnreadCount(int count) {
    _unreadNotifications = count;
    notifyListeners();
  }

  Future<void> updateBaseUrl(String newUrl) async {
    await apiClient.setBaseUrl(newUrl);
    notifyListeners();
  }

  Future<void> logout({bool allDevices = false}) async {
    await authService.logout(allDevices: allDevices);
    _user = null;
    _unreadNotifications = 0;
    notifyListeners();
  }
}
