import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_timetable.dart';
import '../services/auth_service.dart';
import '../services/timetable_repository.dart';

class DashboardScreen extends StatefulWidget {
  /// 홈 탭 전환용 콜백 (탭 인덱스 전달)
  final ValueChanged<int>? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = TimetableRepository();
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
      _saved = await _repo.listByUser(user.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().user;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              automaticallyImplyLeading: false,
              title: const Text('홈'),
              backgroundColor: theme.colorScheme.surface,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('새로운 알림이 없습니다'),
                    ));
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 인사 헤더 ─────────────────────────────
                  _GreetingHeader(name: user?.name ?? '사용자'),
                  const SizedBox(height: 20),

                  // ── 프로필 요약 카드 ──────────────────────
                  if (user != null) _ProfileSummaryCard(
                    name: user.name,
                    department: user.department,
                    grade: user.grade,
                    studentId: user.studentId,
                  ),
                  const SizedBox(height: 16),

                  // ── 빠른 액션 ─────────────────────────────
                  Text('빠른 시작',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.auto_awesome_rounded,
                        label: '시간표 매칭',
                        color: const Color(0xFF3B6BFF),
                        onTap: () => widget.onNavigate?.call(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.search_rounded,
                        label: '과목 탐색',
                        color: const Color(0xFF14B8A6),
                        onTap: () => widget.onNavigate?.call(2),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── 저장된 시간표 섹션 ──────────────────────
                  Row(children: [
                    Text('저장된 시간표',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_saved.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/saved')
                                .then((_) => _load()),
                        child: const Text('전체보기'),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_saved.isEmpty)
                    _EmptyState(
                      onCreate: () => widget.onNavigate?.call(1),
                    )
                  else
                    ..._saved.take(3).map((t) => _SavedTimetablePreview(
                          saved: t,
                          onTap: () => Navigator.pushNamed(
                              context, '/saved').then((_) => _load()),
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 인사 헤더 ─────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final String name;
  const _GreetingHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '좋은 아침이에요'
        : hour < 18
            ? '좋은 오후예요'
            : '좋은 저녁이에요';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(greeting,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Text('$name 님 👋',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
    ]);
  }
}

// ── 프로필 요약 카드 ──────────────────────────────────────────────
class _ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String department;
  final int grade;
  final String studentId;
  const _ProfileSummaryCard({
    required this.name,
    required this.department,
    required this.grade,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(
            name.isEmpty ? '?' : name.substring(0, 1),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$department · $grade학년',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            const SizedBox(height: 2),
            Text(studentId,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('학생',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

// ── 액션 카드 ─────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('바로가기',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

// ── 저장된 시간표 미리보기 ────────────────────────────────────────
class _SavedTimetablePreview extends StatelessWidget {
  final SavedTimetable saved;
  final VoidCallback onTap;
  const _SavedTimetablePreview({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: theme.colorScheme.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(saved.name,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        '${saved.totalCredits}학점 · 공강 ${saved.freeDays}일 · ${(saved.score * 100).toStringAsFixed(0)}점',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(children: [
        Icon(Icons.inbox_outlined,
            size: 40, color: theme.colorScheme.outline),
        const SizedBox(height: 8),
        Text('아직 저장된 시간표가 없어요',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('AI 매칭으로 첫 시간표를 만들어보세요',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline)),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('시간표 매칭 시작'),
        ),
      ]),
    );
  }
}
