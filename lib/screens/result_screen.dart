import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../services/genetic_algorithm.dart';
import '../services/timetable_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/timetable_grid.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Future<void> _saveCurrent(BuildContext context, Timetable timetable) async {
    final user = context.read<AuthService>().user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 시간표를 저장할 수 있습니다.')));
      return;
    }

    final controller = TextEditingController(
      text: '추천 시간표 ${DateTime.now().month}/${DateTime.now().day}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('시간표 저장'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '이름',
              hintText: '예: 2학기 기본안',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (name == null) {
      return;
    }

    await TimetableRepository().save(
      userId: user.id,
      name: name,
      timetable: timetable,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('시간표를 저장했습니다.'),
          action: SnackBarAction(
            label: '보기',
            onPressed: () => Navigator.pushNamed(context, '/saved'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.results.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('추천 결과')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.search_off_rounded,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '조건에 맞는 시간표를 찾지 못했습니다.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '공강 요일이나 시작 시간을 조금 완화하면 결과가 나올 가능성이 높아집니다.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final selected = state.selectedTimetable!;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '추천 결과',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _saveCurrent(context, selected),
                        icon: const Icon(Icons.bookmark_add_outlined),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        ),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('조건 수정'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      _ResultHero(timetable: selected),
                      const SizedBox(height: 14),
                      _RankBar(
                        results: state.results,
                        selected: state.selectedResultIndex,
                        onSelect: state.selectResult,
                      ),
                      const SizedBox(height: 14),
                      _ConstraintPanel(timetable: selected),
                      const SizedBox(height: 14),
                      _TimetableSection(
                        timetable: selected,
                        minHour: state.pref.minStartHour,
                        maxHour: state.pref.maxEndHour,
                      ),
                      const SizedBox(height: 14),
                      _CourseList(courses: selected.courses),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultHero extends StatelessWidget {
  final Timetable timetable;

  const _ResultHero({required this.timetable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, AppTheme.cyan],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가장 잘 맞는 시간표를 골랐습니다.',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '하드 제약 충족도와 선호 점수를 함께 반영한 결과입니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: '적합도',
                  value: '${(timetable.score * 100).toStringAsFixed(1)}점',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: '총 학점',
                  value: '${timetable.totalCredits}학점',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: '평균 평점',
                  value: timetable.averageRating.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.event_available_rounded,
                label: '공강 ${timetable.freeDays}일',
              ),
              _HeroPill(
                icon: Icons.restaurant_rounded,
                label: timetable.hasLunchBreak ? '점심 시간 확보' : '점심 수업 포함',
              ),
              _HeroPill(
                icon: Icons.compress_rounded,
                label:
                    '평균 공백 ${timetable.averageGapHours.toStringAsFixed(1)}시간',
              ),
              _HeroPill(
                icon: Icons.schedule_rounded,
                label: '최장 연속 ${timetable.consecutiveMax}시간',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
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

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _RankBar extends StatelessWidget {
  final List<Timetable> results;
  final int selected;
  final ValueChanged<int> onSelect;

  const _RankBar({
    required this.results,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 134,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: results.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final timetable = results[index];
          final isSelected = index == selected;
          final accent = isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline;

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onSelect(index),
            child: Ink(
              width: 176,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${index + 1}위 추천',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        Icon(
                          timetable.hasNoConflicts
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          size: 18,
                          color: timetable.hasNoConflicts
                              ? AppTheme.leaf
                              : AppTheme.coral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(timetable.score * 100).toStringAsFixed(1)}점',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${timetable.totalCredits}학점 · 공강 ${timetable.freeDays}일 · 평점 ${timetable.averageRating.toStringAsFixed(1)}',
                              softWrap: false,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConstraintPanel extends StatelessWidget {
  final Timetable timetable;

  const _ConstraintPanel({required this.timetable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('추천 근거', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '하드 제약을 먼저 만족시키고, 이후 공강 밀도와 평점 가중치를 반영해 점수를 매겼습니다.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusChip(ok: timetable.hasNoConflicts, label: '시간 충돌'),
                _StatusChip(ok: timetable.satisfiesTimeBounds, label: '시간 범위'),
                _StatusChip(ok: timetable.satisfiesFreeDays, label: '희망 공강일'),
                _StatusChip(ok: timetable.satisfiesCreditLimit, label: '학점 제한'),
              ],
            ),
            const SizedBox(height: 18),
            _ProgressRow(
              label: '하드 제약',
              value: timetable.hardScore,
              color: AppTheme.blue,
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              label: '선호 반영',
              value: timetable.softScore,
              color: AppTheme.cyan,
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              label: '시간표 밀도',
              value: timetable.compactnessScore,
              color: AppTheme.coral,
            ),
            const SizedBox(height: 10),
            _ProgressRow(
              label: '학점 충실도',
              value: timetable.creditFitScore,
              color: AppTheme.leaf,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool ok;
  final String label;

  const _StatusChip({required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppTheme.leaf : AppTheme.coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(value * 100).toStringAsFixed(0)}%',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _TimetableSection extends StatelessWidget {
  final Timetable timetable;
  final int minHour;
  final int maxHour;

  const _TimetableSection({
    required this.timetable,
    required this.minHour,
    required this.maxHour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('주간 시간표', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '추천 시간표가 실제 주간 배치에서 어떻게 보이는지 바로 확인할 수 있습니다.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            TimetableGrid(
              timetable: timetable,
              highlightMinHour: minHour,
              highlightMaxHour: maxHour,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  final List<Course> courses;

  const _CourseList({required this.courses});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('과목 구성', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '추천 시간표를 구성하는 과목과 분반, 평점, 난이도를 한 번에 볼 수 있습니다.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            ...courses.asMap().entries.map((entry) {
              final course = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == courses.length - 1 ? 0 : 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${course.credit}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course.name,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                if (course.isMajorRequired)
                                  _Badge(text: '전공필수', color: AppTheme.coral),
                                if (course.hasTeamProject) ...[
                                  const SizedBox(width: 6),
                                  _Badge(text: '팀프로젝트', color: AppTheme.cyan),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${course.professor} · ${course.section}분반 · ${course.timeSummary}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppTheme.coral,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  course.rating.toStringAsFixed(1),
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(width: 16),
                                Text('난이도', style: theme.textTheme.labelMedium),
                                const SizedBox(width: 8),
                                ...List.generate(
                                  5,
                                  (index) => Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: index < course.difficulty
                                        ? AppTheme.coral
                                        : theme.colorScheme.outlineVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
