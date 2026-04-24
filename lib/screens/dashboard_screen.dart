import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_timetable.dart';
import '../services/auth_service.dart';
import '../services/timetable_repository.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = TimetableRepository();
  List<SavedTimetable> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().user;
    if (user != null) {
      _saved = await _repository.listByUser(user.id);
    } else {
      _saved = [];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().user;
    final greeting = _greeting(DateTime.now().hour);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _HeroPanel(
                  greeting: greeting,
                  name: user?.name ?? '게스트',
                  department: user?.department ?? '빠른 시간표 탐색',
                  savedCount: _saved.length,
                  onNotifications: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('새 알림이 없습니다.')),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        color: AppTheme.blue,
                        icon: Icons.auto_awesome_rounded,
                        title: '시간표 추천',
                        subtitle: '선호 조건을 기반으로 상위 조합을 생성합니다.',
                        onTap: () => widget.onNavigate?.call(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        color: AppTheme.cyan,
                        icon: Icons.search_rounded,
                        title: '강의 탐색',
                        subtitle: '학년, 평점, 팀프로젝트 기준으로 비교합니다.',
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                child: Row(
                  children: [
                    Text('최근 저장한 시간표', style: theme.textTheme.titleLarge),
                    const Spacer(),
                    if (_saved.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/saved',
                        ).then((_) => _load()),
                        child: const Text('전체 보기'),
                      ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_saved.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _EmptyState(
                    onCreate: () => widget.onNavigate?.call(1),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverList.separated(
                  itemCount: _saved.take(3).length,
                  itemBuilder: (context, index) {
                    final saved = _saved[index];
                    return _SavedTimetableCard(
                      saved: saved,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/saved',
                      ).then((_) => _load()),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) {
      return '좋은 아침이에요';
    }
    if (hour < 18) {
      return '좋은 오후예요';
    }
    return '좋은 저녁이에요';
  }
}

class _HeroPanel extends StatelessWidget {
  final String greeting;
  final String name;
  final String department;
  final int savedCount;
  final VoidCallback onNotifications;

  const _HeroPanel({
    required this.greeting,
    required this.name,
    required this.department,
    required this.savedCount,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153EA8), Color(0xFF0F6CBD), Color(0xFF1D8FB8)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onNotifications,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            greeting,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$name 님을 위한 시간표 브리핑',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            department,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(label: '저장된 시간표', value: '$savedCount개'),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _MetricTile(label: '추천 엔진', value: 'GA + 보정'),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _MetricTile(label: '주요 기준', value: '공강 + 평점'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedTimetableCard extends StatelessWidget {
  final SavedTimetable saved;
  final VoidCallback onTap;

  const _SavedTimetableCard({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.blue.withValues(alpha: 0.18),
                      AppTheme.cyan.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(saved.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${saved.totalCredits}학점 · 공강 ${saved.freeDays}일 · 적합도 ${(saved.score * 100).toStringAsFixed(0)}점',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text('아직 저장된 시간표가 없습니다.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '선호 조건을 입력하면 상위 추천 시간표를 바로 확인할 수 있습니다.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('첫 추천 시작하기'),
          ),
        ],
      ),
    );
  }
}
