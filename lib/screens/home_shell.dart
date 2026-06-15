import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'course_search_screen.dart';
import 'dashboard_screen.dart';
import 'input_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  bool _checkedProfileCompletion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedProfileCompletion) {
      return;
    }

    final user = context.read<AuthService>().user;
    if (user != null && !user.profileComplete) {
      _currentIndex = 3;
    }
    _checkedProfileCompletion = true;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigate: (index) => setState(() => _currentIndex = index),
      ),
      InputScreen(onProfileRequired: () => setState(() => _currentIndex = 3)),
      const CourseSearchScreen(),
      const ProfileScreen(),
    ];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: '홈',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_view_week_outlined),
                  selectedIcon: Icon(Icons.calendar_view_week_rounded),
                  label: '시간표',
                ),
                NavigationDestination(
                  icon: Icon(Icons.manage_search_outlined),
                  selectedIcon: Icon(Icons.manage_search_rounded),
                  label: '탐색',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: Icon(Icons.account_circle_rounded),
                  label: '프로필',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
