import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_timetable.dart';
import '../models/user.dart';
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
  List<SavedTimetable> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    setState(() => _loading = true);
    final user = context.read<AuthService>().user;
    final repository = context.read<TimetableRepository>();

    try {
      if (user != null) {
        _saved = await repository.listByUser(user);
      } else {
        _saved = [];
      }
    } on TimetableRepositoryException catch (error) {
      _saved = [];
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
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
                  department: user?.department ?? '강의와 시간표를 한곳에서 확인',
                  savedCount: _saved.length,
                  onStatusTap: () => _openStatusSheet(user),
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
                        icon: Icons.calendar_view_week_rounded,
                        title: '시간표 만들기',
                        subtitle: '선택한 조건에 맞는 시간표 조합을 빠르게 확인합니다.',
                        onTap: () => widget.onNavigate?.call(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        color: AppTheme.cyan,
                        icon: Icons.manage_search_rounded,
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _FlowGuideCard(
                  onStart: () => widget.onNavigate?.call(1),
                  onExplore: () => widget.onNavigate?.call(2),
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
                        onPressed: _openSaved,
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
                    return _SavedTimetableCard(saved: saved, onTap: _openSaved);
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

  Future<void> _openSaved() async {
    await Navigator.pushNamed(context, '/saved');
    if (mounted) {
      await _load();
    }
  }

  void _openStatusSheet(User? user) {
    final savedSnapshot = List<SavedTimetable>.unmodifiable(_saved);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _DashboardStatusSheet(
        user: user,
        saved: savedSnapshot,
        onCreate: () {
          Navigator.pop(sheetContext);
          widget.onNavigate?.call(1);
        },
        onProfile: () {
          Navigator.pop(sheetContext);
          widget.onNavigate?.call(3);
        },
        onSaved: () {
          Navigator.pop(sheetContext);
          _openSaved();
        },
      ),
    );
  }
}

class _DashboardStatusSheet extends StatelessWidget {
  final User? user;
  final List<SavedTimetable> saved;
  final VoidCallback onCreate;
  final VoidCallback onProfile;
  final VoidCallback onSaved;

  const _DashboardStatusSheet({
    required this.user,
    required this.saved,
    required this.onCreate,
    required this.onProfile,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileReady =
        user != null && user!.profileComplete && user!.hasRequiredProfile;
    final latest = saved.isEmpty ? null : saved.first;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('진행 상태', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('추천 전에 확인할 항목입니다.', style: theme.textTheme.bodySmall),
              const SizedBox(height: 18),
              _StatusRow(
                icon: profileReady
                    ? Icons.verified_user_outlined
                    : Icons.assignment_ind_outlined,
                color: profileReady ? AppTheme.leaf : AppTheme.coral,
                title: profileReady ? '프로필 준비 완료' : '프로필 정보 필요',
                body: profileReady
                    ? '${user!.department} · ${user!.grade}학년 기준으로 시간표를 만들 수 있습니다.'
                    : '학번, 학과, 학년을 입력해야 전공 조건을 맞출 수 있습니다.',
              ),
              _StatusRow(
                icon: saved.isEmpty
                    ? Icons.bookmark_border_rounded
                    : Icons.bookmark_added_outlined,
                color: saved.isEmpty ? AppTheme.cyan : AppTheme.blue,
                title: saved.isEmpty
                    ? '저장한 시간표 없음'
                    : '저장한 시간표 ${saved.length}개',
                body: saved.isEmpty
                    ? '결과 화면에서 마음에 드는 시간표를 저장하세요.'
                    : '저장 목록에서 이름 변경과 삭제를 할 수 있습니다.',
              ),
              _StatusRow(
                icon: Icons.history_rounded,
                color: theme.colorScheme.tertiary,
                title: latest == null ? '최근 저장 기록 없음' : '최근 저장: ${latest.name}',
                body: latest == null
                    ? '조건을 입력해 첫 시간표를 만들어 보세요.'
                    : '${_formatSavedAt(latest.savedAt)} · ${latest.totalCredits}학점 · 적합도 ${(latest.score * 100).toStringAsFixed(0)}점',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (!profileReady)
                    FilledButton.icon(
                      onPressed: onProfile,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('프로필 수정'),
                    ),
                  if (saved.isEmpty)
                    FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.calendar_view_week_rounded),
                      label: const Text('시간표 만들기'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: onSaved,
                      icon: const Icon(Icons.bookmark_added_outlined),
                      label: const Text('저장 목록'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSavedAt(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day} $hour:$minute';
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String greeting;
  final String name;
  final String department;
  final int savedCount;
  final VoidCallback onStatusTap;

  const _HeroPanel({
    required this.greeting,
    required this.name,
    required this.department,
    required this.savedCount,
    required this.onStatusTap,
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
                  Icons.calendar_view_week_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: '진행 상태',
                onPressed: onStatusTap,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.fact_check_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$name 님의 시간표 현황',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            department,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                child: _MetricTile(label: '생성 방식', value: '조건 기반'),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _MetricTile(label: '중점 항목', value: '공강 · 평점'),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowGuideCard extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onExplore;

  const _FlowGuideCard({required this.onStart, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('처음이라면 이렇게 시작하세요', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '조건을 정하고, 결과를 비교한 뒤 마음에 드는 시간표를 저장하면 됩니다.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _GuideStep(
            number: '1',
            title: '학년과 공강 조건 선택',
            body: '전공필수는 기본 반영되고, 전공·교양은 필요할 때만 고정합니다.',
          ),
          const SizedBox(height: 10),
          const _GuideStep(
            number: '2',
            title: '결과 비교',
            body: '점수, 공강, 평점, 시간표 배치를 한 화면에서 확인합니다.',
          ),
          const SizedBox(height: 10),
          const _GuideStep(
            number: '3',
            title: '저장 후 다시 확인',
            body: '저장한 시간표는 홈과 저장 목록에서 다시 엽니다.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.calendar_view_week_rounded),
                label: const Text('시간표 만들기'),
              ),
              OutlinedButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.manage_search_rounded),
                label: const Text('강의 먼저 보기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            number,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(body, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
                    Text(
                      saved.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${saved.totalCredits}학점 · 공강 ${saved.freeDays}일 · 적합도 ${(saved.score * 100).toStringAsFixed(0)}점',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              Icons.calendar_today_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text('아직 저장된 시간표가 없습니다.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '조건을 입력하면 시간표 후보를 만들 수 있습니다.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('첫 시간표 만들기'),
          ),
        ],
      ),
    );
  }
}
