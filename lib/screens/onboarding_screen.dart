import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.auto_awesome_rounded,
      title: 'AI 시간표 매칭',
      description: '유전 알고리즘으로 수십만 개의 조합 중에서\n당신에게 가장 잘 맞는 시간표를 찾아드립니다.',
      color: Color(0xFF3B6BFF),
    ),
    _OnboardingPageData(
      icon: Icons.tune_rounded,
      title: '세밀한 맞춤 설정',
      description: '공강 요일, 점심시간, 시작/종료 시간,\n팀플 기피까지 — 당신의 취향대로 시간표가 짜입니다.',
      color: Color(0xFF14B8A6),
    ),
    _OnboardingPageData(
      icon: Icons.bookmark_rounded,
      title: '저장하고 비교하기',
      description: '마음에 드는 시간표를 저장해두고\n언제든 다시 꺼내보세요. 5개의 추천 결과를 비교할 수 있어요.',
      color: Color(0xFFF59E0B),
    ),
  ];

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarded', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Skip 버튼
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton(
                onPressed: _finish,
                child: const Text('건너뛰기'),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
            ),
          ),
          // 인디케이터
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // 다음/시작 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: FilledButton(
              onPressed: () {
                if (isLast) {
                  _finish();
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  );
                }
              },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54)),
              child: Text(isLast ? '시작하기' : '다음'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 64, color: data.color),
          ),
          const SizedBox(height: 36),
          Text(data.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4)),
          const SizedBox(height: 12),
          Text(data.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5)),
        ],
      ),
    );
  }
}
