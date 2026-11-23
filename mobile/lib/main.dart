import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.load();
  runApp(const MessMateApp());
}

class MessMateApp extends StatelessWidget {
  const MessMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.current,
      builder: (_, locale, _) => MaterialApp(
        title: 'Ctg Mess',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(isBn: locale == 'bn'),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await ApiService.getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: !_isLoggedIn
          ? AuthScreen(
              key: const ValueKey('auth'),
              onAuthenticated: () => setState(() => _isLoggedIn = true),
            )
          : HomeShell(
              key: const ValueKey('home'),
              onLogout: () => setState(() => _isLoggedIn = false),
            ),
    );
  }
}
