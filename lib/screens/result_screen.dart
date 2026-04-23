import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/genetic_algorithm.dart';
import '../widgets/timetable_grid.dart';
import '../models/course.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      if (state.results.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: const Text('추천 시간표')),
          body: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('조건에 맞는 시간표를 찾지 못했습니다.',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('제약 조건을 완화해 보세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('추천 시간표'),
          centerTitle: true,
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.popUntil(ctx, (r) => r.isFirst),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('다시 설정'),
            ),
          ],
        ),
        body: Column(children: [
          _RankBar(
              results: state.results,
              selected: state.selectedResultIndex,
              onSelect: state.selectResult),
          if (state.selectedTimetable != null)
            Expanded(child: _TimetableDetail(timetable: state.selectedTimetable!)),
        ]),
      );
    });
  }
}

// ── 순위 선택 바 ──────────────────────────────────────────────────
class _RankBar extends StatelessWidget {
  final List<Timetable> results;
  final int selected;
  final ValueChanged<int> onSelect;
  const _RankBar(
      {required this.results, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: results.length,
        itemBuilder: (_, i) {
          final t = results[i];
          final isSelected = selected == i;
          final hardOk = t.hardScore >= 0.99;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                hardOk ? Icons.verified_rounded : Icons.warning_amber_rounded,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : hardOk
                        ? Colors.green
                        : Colors.orange,
              ),
              label: Text(
                  '${i + 1}순위 · ${(t.score * 100).toStringAsFixed(0)}점'),
              selected: isSelected,
              onSelected: (_) => onSelect(i),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : null),
            ),
          );
        },
      ),
    );
  }
}

// ── 시간표 상세 ───────────────────────────────────────────────────
class _TimetableDetail extends StatelessWidget {
  final Timetable timetable;
  const _TimetableDetail({required this.timetable});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        _SummaryBanner(timetable: timetable),
        _ConstraintBar(timetable: timetable),
        const TabBar(tabs: [
          Tab(icon: Icon(Icons.grid_view_rounded), text: '시간표'),
          Tab(icon: Icon(Icons.list_alt_rounded), text: '과목 목록'),
        ]),
        Expanded(
          child: TabBarView(children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: TimetableGrid(timetable: timetable),
            ),
            _CourseList(courses: timetable.courses),
          ]),
        ),
      ]),
    );
  }
}

// ── 요약 배너 ─────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final Timetable timetable;
  const _SummaryBanner({required this.timetable});

  @override
  Widget build(BuildContext context) {
    final avgRating = timetable.courses.isEmpty
        ? 0.0
        : timetable.courses.fold(0.0, (s, c) => s + c.rating) /
            timetable.courses.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatChip(Icons.credit_card_outlined, '${timetable.totalCredits}학점'),
        _StatChip(Icons.coffee_outlined, '공강 ${timetable.freeDays}일'),
        _StatChip(Icons.star_rounded, '평점 ${avgRating.toStringAsFixed(1)}',
            color: Colors.amber),
        _StatChip(Icons.emoji_events_rounded,
            '${(timetable.score * 100).toStringAsFixed(1)}점',
            highlight: true),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final Color? color;
  const _StatChip(this.icon, this.label, {this.highlight = false, this.color});

  @override
  Widget build(BuildContext context) {
    final baseColor = highlight
        ? Theme.of(context).colorScheme.primary
        : color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: baseColor),
      const SizedBox(width: 4),
      Text(label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: baseColor,
              fontWeight: highlight ? FontWeight.bold : null)),
    ]);
  }
}

// ── 제약 만족도 바 (하드/소프트 분리 표시) ────────────────────────
class _ConstraintBar extends StatelessWidget {
  final Timetable timetable;
  const _ConstraintBar({required this.timetable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('제약 만족도',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const Spacer(),
          // 하드 제약 상태 배지들
          _HardBadge(
              ok: timetable.hasNoConflicts,
              label: '시간충돌',
              okLabel: '없음'),
          const SizedBox(width: 6),
          _HardBadge(
              ok: timetable.satisfiesTimeBounds,
              label: '시간범위',
              okLabel: '충족'),
          const SizedBox(width: 6),
          _HardBadge(
              ok: timetable.satisfiesFreeDays,
              label: '공강요일',
              okLabel: '충족'),
        ]),
        const SizedBox(height: 6),
        // 소프트 점수 진행 바
        Row(children: [
          SizedBox(
              width: 56,
              child: Text('하드 제약',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timetable.hardScore,
                minHeight: 6,
                color: _hardColor(timetable.hardScore),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(timetable.hardScore * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: _hardColor(timetable.hardScore))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          SizedBox(
              width: 56,
              child: Text('소프트 점수',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timetable.softScore.clamp(0.0, 1.0),
                minHeight: 6,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(timetable.softScore * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        ]),
      ]),
    );
  }

  Color _hardColor(double score) {
    if (score >= 0.99) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

class _HardBadge extends StatelessWidget {
  final bool ok;
  final String label;
  final String okLabel;
  const _HardBadge(
      {required this.ok, required this.label, required this.okLabel});

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 10, color: color),
        const SizedBox(width: 3),
        Text(ok ? '$label $okLabel' : '$label 위반',
            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ── 과목 목록 ─────────────────────────────────────────────────────
class _CourseList extends StatelessWidget {
  final List<Course> courses;
  const _CourseList({required this.courses});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: courses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final c = courses[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Text('${c.credit}',
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold)),
            ),
            title: Row(children: [
              Expanded(
                  child: Text(c.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600))),
              if (c.isMajorRequired)
                _Badge('전필', Theme.of(context).colorScheme.error),
              if (c.hasTeamProject) ...[
                const SizedBox(width: 4),
                _Badge('팀플', Colors.orange.shade700),
              ],
            ]),
            subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text('${c.professor} · ${c.timeSummary}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Row(children: [
                    _StarRow(c.rating),
                    const SizedBox(width: 12),
                    _DifficultyBar(c.difficulty),
                  ]),
                ]),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold)),
      );
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow(this.rating);
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _DifficultyBar extends StatelessWidget {
  final int difficulty;
  const _DifficultyBar(this.difficulty);
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('난이도 ', style: Theme.of(context).textTheme.bodySmall),
        ...List.generate(
            5,
            (i) => Icon(Icons.circle,
                size: 8,
                color: i < difficulty
                    ? Colors.deepOrange
                    : Colors.grey.shade300)),
      ]);
}
