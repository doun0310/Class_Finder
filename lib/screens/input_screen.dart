import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  List<dynamic> get _requiredCourses => realCourses
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
      _grade         = p.getInt('grade')        ?? 2;
      _maxCredits    = p.getInt('maxCredits')   ?? 18;
      _preferMorning = p.getBool('morning')     ?? false;
      _avoidTeamProject = p.getBool('avoidTeam') ?? false;
      _freeTimeWeight   = p.getDouble('wFree')  ?? 0.4;
      _ratingWeight     = p.getDouble('wRating')  ?? 0.3;
      _difficultyWeight = p.getDouble('wDiff')  ?? 0.2;
      final ids = p.getStringList('requiredIds') ?? [];
      _requiredIds
        ..clear()
        ..addAll(ids);
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
    await p.setStringList('requiredIds', _requiredIds.toList());
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
                        child: Text('AI 기반 맞춤 시간표 자동 매칭',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8))),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionCard(
                        title: '기본 정보',
                        icon: Icons.person_outline,
                        children: [
                          _GradeSelector(
                              value: _grade,
                              onChanged: (v) => setState(() {
                                    _grade = v;
                                    _requiredIds.removeWhere((id) => !_requiredCourses
                                        .any((c) => c.id == id));
                                  })),
                          const SizedBox(height: 12),
                          _CreditSelector(
                              value: _maxCredits,
                              onChanged: (v) =>
                                  setState(() => _maxCredits = v)),
                          const Divider(height: 24),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('오전 수업 선호'),
                            subtitle:
                                const Text('오전에 수업이 배치되도록 최적화'),
                            secondary: const Icon(Icons.wb_sunny_outlined),
                            value: _preferMorning,
                            onChanged: (v) =>
                                setState(() => _preferMorning = v),
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
                      _SectionCard(
                        title: '선호도 가중치',
                        icon: Icons.tune,
                        children: [
                          _WeightSlider(
                              '공강 시간',
                              Icons.free_breakfast_outlined,
                              _freeTimeWeight,
                              (v) =>
                                  setState(() => _freeTimeWeight = v)),
                          _WeightSlider(
                              '강의 평점',
                              Icons.star_outline,
                              _ratingWeight,
                              (v) =>
                                  setState(() => _ratingWeight = v)),
                          _WeightSlider(
                              '낮은 난이도',
                              Icons.school_outlined,
                              _difficultyWeight,
                              (v) =>
                                  setState(() => _difficultyWeight = v)),
                          const SizedBox(height: 4),
                          _WeightSumIndicator(
                              sum: _freeTimeWeight +
                                  _ratingWeight +
                                  _difficultyWeight +
                                  0.1),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_requiredCourses.isNotEmpty)
                        _SectionCard(
                          title: '전공 필수 과목 선택',
                          icon: Icons.check_circle_outline,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '포함할 전필 과목을 선택하세요. 선택한 과목은 반드시 시간표에 포함됩니다.',
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
          // 로딩 오버레이
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
      teamProjectWeight: 0.1,
      requiredCourseIds: _requiredIds.toList(),
    ));
    await state.runMatching();
    if (ctx.mounted) Navigator.pushNamed(ctx, '/results');
  }
}

// ── 섹션 카드 ─────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              ...children,
            ]),
      ),
    );
  }
}

// ── 학년 선택 ─────────────────────────────────────────────────
class _GradeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _GradeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text('학년'),
      const Spacer(),
      SegmentedButton<int>(
        segments: [1, 2, 3, 4]
            .map((g) => ButtonSegment(value: g, label: Text('$g학년')))
            .toList(),
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    ]);
  }
}

// ── 학점 선택 ─────────────────────────────────────────────────
class _CreditSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _CreditSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text('최대 학점'),
      const Spacer(),
      SegmentedButton<int>(
        segments: [12, 15, 18, 21]
            .map((c) => ButtonSegment(value: c, label: Text('$c')))
            .toList(),
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    ]);
  }
}

// ── 가중치 슬라이더 ───────────────────────────────────────────
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
          width: 80,
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

// ── 가중치 합계 표시 ──────────────────────────────────────────
class _WeightSumIndicator extends StatelessWidget {
  final double sum;
  const _WeightSumIndicator({required this.sum});

  @override
  Widget build(BuildContext context) {
    final over = sum > 1.05;
    return Row(children: [
      Icon(over ? Icons.warning_amber : Icons.info_outline,
          size: 14, color: over ? Colors.orange : Colors.grey),
      const SizedBox(width: 4),
      Text('팀플 가중치(10%) 포함 합계: ${(sum * 100).round()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: over ? Colors.orange : Colors.grey)),
    ]);
  }
}
