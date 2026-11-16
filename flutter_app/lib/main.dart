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
                ? const _SplashScreen(key: ValueKey('splash'))
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryIndigo, AppTheme.secondaryIndigo],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'لوحة المهام',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
