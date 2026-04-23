import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/user_preference.dart';
import '../services/app_state.dart';
import '../services/real_courses.dart';
import '../widgets/matching_loading_overlay.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  int _grade = 2;
  int _maxCredits = 18;
  bool _preferMorning = false;
  bool _avoidTeamProject = false;
  double _freeTimeWeight = 0.4;
  double _ratingWeight = 0.3;
  double _difficultyWeight = 0.2;
  final Set<String> _requiredIds = {};

  // 시간 제약 (Where-Got-TimeTable 참조)
  int _minStartHour = 9;
  int _maxEndHour = 20;
  final Set<String> _preferredFreeDays = {};
  bool _requireLunchBreak = false;

  List<Course> get _requiredCourses => realCourses
      .where((c) => c.isMajorRequired && (c.grade == 0 || c.grade <= _grade))
      .toList();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _grade            = p.getInt('grade')       ?? 2;
      _maxCredits       = p.getInt('maxCredits')  ?? 18;
      _preferMorning    = p.getBool('morning')    ?? false;
      _avoidTeamProject = p.getBool('avoidTeam')  ?? false;
      _freeTimeWeight   = p.getDouble('wFree')    ?? 0.4;
      _ratingWeight     = p.getDouble('wRating')  ?? 0.3;
      _difficultyWeight = p.getDouble('wDiff')    ?? 0.2;
      _minStartHour     = p.getInt('minStart')    ?? 9;
      _maxEndHour       = p.getInt('maxEnd')      ?? 20;
      _requireLunchBreak = p.getBool('lunchBreak') ?? false;
      final ids   = p.getStringList('requiredIds')   ?? [];
      final fdays = p.getStringList('freeDays')      ?? [];
      _requiredIds.clear(); _requiredIds.addAll(ids);
      _preferredFreeDays.clear(); _preferredFreeDays.addAll(fdays);
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('grade', _grade);
    await p.setInt('maxCredits', _maxCredits);
    await p.setBool('morning', _preferMorning);
    await p.setBool('avoidTeam', _avoidTeamProject);
    await p.setDouble('wFree', _freeTimeWeight);
    await p.setDouble('wRating', _ratingWeight);
    await p.setDouble('wDiff', _difficultyWeight);
    await p.setInt('minStart', _minStartHour);
    await p.setInt('maxEnd', _maxEndHour);
    await p.setBool('lunchBreak', _requireLunchBreak);
    await p.setStringList('requiredIds', _requiredIds.toList());
    await p.setStringList('freeDays', _preferredFreeDays.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppState>(
      builder: (ctx, state, _) => Stack(
        children: [
          Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: const Text('ClassFinder'),
                  centerTitle: false,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(24),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '유전 알고리즘 기반 맞춤 시간표 자동 매칭',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8)),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 기본 정보 ──────────────────────────────
                      _SectionCard(
                        title: '기본 정보',
                        icon: Icons.person_outline,
                        children: [
                          _LabeledRow(
                            label: '학년',
                            child: SegmentedButton<int>(
                              segments: [1, 2, 3, 4]
                                  .map((g) =>
                                      ButtonSegment(value: g, label: Text('$g학년')))
                                  .toList(),
                              selected: {_grade},
                              onSelectionChanged: (s) => setState(() {
                                _grade = s.first;
                                _requiredIds.removeWhere((id) =>
                                    !_requiredCourses.any((c) => c.id == id));
                              }),
                              style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledRow(
                            label: '최대 학점',
                            child: SegmentedButton<int>(
                              segments: [12, 15, 18, 21]
                                  .map((c) =>
                                      ButtonSegment(value: c, label: Text('$c')))
                                  .toList(),
                              selected: {_maxCredits},
                              onSelectionChanged: (s) =>
                                  setState(() => _maxCredits = s.first),
                              style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact),
                            ),
                          ),
                          const Divider(height: 20),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('오전 수업 선호'),
                            subtitle: const Text('오전에 수업이 배치되도록 최적화'),
                            secondary: const Icon(Icons.wb_sunny_outlined),
                            value: _preferMorning,
                            onChanged: (v) => setState(() => _preferMorning = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('팀 프로젝트 기피'),
                            subtitle: const Text('팀플 과목을 최대한 제외'),
                            secondary: const Icon(Icons.group_off_outlined),
                            value: _avoidTeamProject,
                            onChanged: (v) =>
                                setState(() => _avoidTeamProject = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── 시간 제약 (하드 제약) ──────────────────
                      _SectionCard(
                        title: '시간 제약',
                        icon: Icons.access_time_outlined,
                        subtitle: '하드 제약 — 위반 시 점수가 급격히 감소합니다',
                        children: [
                          _LabeledRow(
                            label: '시작 시간',
                            child: SegmentedButton<int>(
                              segments: [9, 10, 11]
                                  .map((h) => ButtonSegment(
                                      value: h, label: Text('$h시')))
                                  .toList(),
                              selected: {_minStartHour},
                              onSelectionChanged: (s) =>
                                  setState(() => _minStartHour = s.first),
                              style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LabeledRow(
                            label: '종료 시간',
                            child: SegmentedButton<int>(
                              segments: [18, 19, 20, 21]
                                  .map((h) => ButtonSegment(
                                      value: h, label: Text('$h시')))
                                  .toList(),
                              selected: {_maxEndHour},
                              onSelectionChanged: (s) =>
                                  setState(() => _maxEndHour = s.first),
                              style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact),
                            ),
                          ),
                          const Divider(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('공강 희망 요일',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: 8),
                          _FreeDaySelector(
                            selected: _preferredFreeDays,
                            onChanged: (day) => setState(() {
                              _preferredFreeDays.contains(day)
                                  ? _preferredFreeDays.remove(day)
                                  : _preferredFreeDays.add(day);
                            }),
                          ),
                          const Divider(height: 20),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('점심시간 확보'),
                            subtitle: const Text('12~13시 수업 배치 최소화'),
                            secondary: const Icon(Icons.lunch_dining_outlined),
                            value: _requireLunchBreak,
                            onChanged: (v) =>
                                setState(() => _requireLunchBreak = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── 선호도 가중치 (소프트 제약) ────────────
                      _SectionCard(
                        title: '선호도 가중치',
                        icon: Icons.tune,
                        subtitle: '소프트 제약 — 가중합으로 점수에 반영됩니다',
                        children: [
                          _WeightSlider(
                            '공강 시간',
                            Icons.free_breakfast_outlined,
                            _freeTimeWeight,
                            (v) => setState(() => _freeTimeWeight = v),
                          ),
                          _WeightSlider(
                            '강의 평점',
                            Icons.star_outline,
                            _ratingWeight,
                            (v) => setState(() => _ratingWeight = v),
                          ),
                          _WeightSlider(
                            '낮은 난이도',
                            Icons.school_outlined,
                            _difficultyWeight,
                            (v) => setState(() => _difficultyWeight = v),
                          ),
                          const SizedBox(height: 4),
                          _WeightNote(
                            freeW: _freeTimeWeight,
                            ratingW: _ratingWeight,
                            diffW: _difficultyWeight,
                            teamAvoided: _avoidTeamProject,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── 전공 필수 과목 ─────────────────────────
                      if (_requiredCourses.isNotEmpty)
                        _SectionCard(
                          title: '전공 필수 과목 선택',
                          icon: Icons.check_circle_outline,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '선택한 과목은 반드시 시간표에 포함됩니다.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline),
                              ),
                            ),
                            ..._requiredCourses.map((c) => CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(c.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Text(
                                      '${c.professor} · ${c.credit}학점 · ${c.timeSummary}'),
                                  secondary: CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Text('${c.credit}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme
                                                .onPrimaryContainer)),
                                  ),
                                  value: _requiredIds.contains(c.id),
                                  onChanged: (v) => setState(() => v!
                                      ? _requiredIds.add(c.id)
                                      : _requiredIds.remove(c.id)),
                                )),
                          ],
                        ),
                      const SizedBox(height: 24),

                      FilledButton.icon(
                        onPressed:
                            state.isLoading ? null : () => _run(ctx, state),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('시간표 자동 매칭',
                            style: TextStyle(fontSize: 16)),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54)),
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading) const MatchingLoadingOverlay(),
        ],
      ),
    );
  }

  Future<void> _run(BuildContext ctx, AppState state) async {
    await _savePrefs();
    state.updatePref(UserPreference(
      major: '컴퓨터공학',
      grade: _grade,
      maxCredits: _maxCredits,
      preferMorning: _preferMorning,
      avoidTeamProject: _avoidTeamProject,
      freeTimeWeight: _freeTimeWeight,
      ratingWeight: _ratingWeight,
      difficultyWeight: _difficultyWeight,
      requiredCourseIds: _requiredIds.toList(),
      minStartHour: _minStartHour,
      maxEndHour: _maxEndHour,
      preferredFreeDays: _preferredFreeDays.toList(),
      requireLunchBreak: _requireLunchBreak,
    ));
    await state.runMatching();
    if (ctx.mounted) Navigator.pushNamed(ctx, '/results');
  }
}

// ── 섹션 카드 ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── 레이블 + 위젯 행 ──────────────────────────────────────────────
class _LabeledRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
          width: 64,
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium)),
      const SizedBox(width: 8),
      Expanded(child: Align(alignment: Alignment.centerRight, child: child)),
    ]);
  }
}

// ── 공강 요일 선택 칩 ─────────────────────────────────────────────
class _FreeDaySelector extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onChanged;
  const _FreeDaySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금'];
    return Wrap(
      spacing: 8,
      children: days.map((day) {
        final isSelected = selected.contains(day);
        return FilterChip(
          label: Text('$day요일'),
          selected: isSelected,
          onSelected: (_) => onChanged(day),
          showCheckmark: false,
          selectedColor:
              Theme.of(context).colorScheme.primaryContainer,
          labelStyle: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ── 가중치 슬라이더 ───────────────────────────────────────────────
class _WeightSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  const _WeightSlider(this.label, this.icon, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 8),
      SizedBox(
          width: 72,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      Expanded(
          child: Slider(
              value: value,
              onChanged: onChanged,
              divisions: 10,
              min: 0,
              max: 1)),
      SizedBox(
          width: 36,
          child: Text('${(value * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.end)),
    ]);
  }
}

// ── 가중치 안내 ───────────────────────────────────────────────────
class _WeightNote extends StatelessWidget {
  final double freeW, ratingW, diffW;
  final bool teamAvoided;
  const _WeightNote({
    required this.freeW,
    required this.ratingW,
    required this.diffW,
    required this.teamAvoided,
  });

  @override
  Widget build(BuildContext context) {
    final teamW = teamAvoided ? 0.2 : 0.0;
    final total = freeW + ratingW + diffW + teamW;
    return Row(children: [
      Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          teamAvoided
              ? '팀플 기피 가중치(20%) 포함 · 정규화 후 반영됩니다 (합계 ${(total * 100).round()}%)'
              : '가중치는 정규화 후 반영됩니다 (합계 ${(total * 100).round()}%)',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade500),
        ),
      ),
    ]);
  }
}
