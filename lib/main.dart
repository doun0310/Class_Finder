import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/result_screen.dart';
import 'screens/saved_timetables_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_state.dart';
import 'services/auth_repository.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  // 로컬 구현 주입. 실제 서버 연동 시 RemoteAuthRepository(ApiClient(...))로 교체
  final authRepo = LocalAuthRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(authRepo)),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const ClassFinderApp(),
    ),
  );
}

class ClassFinderApp extends StatelessWidget {
  const ClassFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassFinder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeShell(),
        '/results': (_) => const ResultScreen(),
        '/saved': (_) => const SavedTimetablesScreen(),
      },
    );
  }
}
