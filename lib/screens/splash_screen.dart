import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    // 최소 스플래시 노출 시간
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final auth = context.read<AuthService>();
    await auth.loadSession();
    final p = await SharedPreferences.getInstance();
    final onboarded = p.getBool('onboarded') ?? false;

    if (!mounted) return;

    Widget next;
    if (!onboarded) {
      next = const OnboardingScreen();
    } else if (auth.isAuthenticated) {
      next = const HomeShell();
    } else {
      next = const LoginScreen();
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: scheme.onPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.auto_awesome,
                    size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 20),
              Text('ClassFinder',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimary,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text('AI 기반 맞춤 시간표 매칭',
                  style: TextStyle(
                      fontSize: 14,
                      color: scheme.onPrimary.withValues(alpha: 0.85))),
              const SizedBox(height: 36),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: scheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
