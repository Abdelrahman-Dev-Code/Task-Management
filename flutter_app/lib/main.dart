import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell_screen.dart';
import 'services/session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskManagementApp());
}

/// التطبيق الرئيسي لإدارة المهام بواجهة عربية متجاوبة ونظام ألوان فاتح/داكن
class TaskManagementApp extends StatefulWidget {
  const TaskManagementApp({super.key});

  @override
  State<TaskManagementApp> createState() => _TaskManagementAppState();
}

class _TaskManagementAppState extends State<TaskManagementApp> {
  final SessionController _session = SessionController();

  @override
  void initState() {
    super.initState();
    _session.initialize();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        return MaterialApp(
          title: 'لوحة المهام',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _session.themeMode,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: !_session.isInitialized
                ? const Scaffold(
                    key: ValueKey('splash'),
                    body: Center(child: CircularProgressIndicator()),
                  )
                : _session.isAuthenticated
                    ? MainShellScreen(
                        key: const ValueKey('home'),
                        session: _session,
                      )
                    : LoginScreen(
                        key: const ValueKey('auth'),
                        session: _session,
                      ),
          ),
        );
      },
    );
  }
}
