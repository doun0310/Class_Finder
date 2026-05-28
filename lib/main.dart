import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/result_screen.dart';
import 'screens/saved_timetables_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_state.dart';
import 'services/api_client.dart';
import 'services/auth_repository.dart';
import 'services/auth_service.dart';
import 'services/social_auth_service.dart';
import 'services/timetable_repository.dart';
import 'theme/app_theme.dart';

void main() {
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  final authRepo = apiBaseUrl.isEmpty
      ? LocalAuthRepository()
      : RemoteAuthRepository(ApiClient(baseUrl: apiBaseUrl));
  final socialAuth = DeviceSocialAuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(authRepo, socialAuth: socialAuth),
        ),
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider<TimetableRepository>(
          create: (_) {
            if (apiBaseUrl.isEmpty) {
              return const LocalTimetableRepository();
            }

            return RemoteTimetableRepository(
              client: ApiClient(baseUrl: apiBaseUrl),
            );
          },
          dispose: (_, repository) => repository.dispose(),
        ),
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
