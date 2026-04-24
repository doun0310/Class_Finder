import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course.dart';
import '../models/user_preference.dart';
import '../services/app_state.dart';
import '../services/real_courses.dart';
import '../theme/app_theme.dart';
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

  int _minStartHour = 9;
  int _maxEndHour = 20;
  final Set<String> _preferredFreeDays = {};
  bool _requireLunchBreak = false;

  List<Course> get _requiredCourses => realCourses
      .where((course) => course.isMajorRequired && course.grade <= _grade)
      .toList();

  List<List<Course>> get _requiredCourseGroups {
    final grouped = <String, List<Course>>{};
    for (final course in _requiredCourses) {
      grouped.putIfAbsent(course.courseCode, () => []).add(course);
    }

    final groups = grouped.values.toList()
      ..sort((a, b) => a.first.name.compareTo(b.first.name));
    for (final group in groups) {
      group.sort(
        (a, b) =>
            a.timeSlots.first.startHour.compareTo(b.timeSlots.first.startHour),
      );
    }
    return groups;
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _grade = prefs.getInt('grade') ?? 2;
      _maxCredits = prefs.getInt('maxCredits') ?? 18;
      _preferMorning = prefs.getBool('morning') ?? false;
      _avoidTeamProject = prefs.getBool('avoidTeam') ?? false;
      _freeTimeWeight = prefs.getDouble('wFree') ?? 0.4;
      _ratingWeight = prefs.getDouble('wRating') ?? 0.3;
      _difficultyWeight = prefs.getDouble('wDiff') ?? 0.2;
      _minStartHour = prefs.getInt('minStart') ?? 9;
      _maxEndHour = prefs.getInt('maxEnd') ?? 20;
      _requireLunchBreak = prefs.getBool('lunchBreak') ?? false;
      _requiredIds
        ..clear()
        ..addAll(prefs.getStringList('requiredIds') ?? []);
      _preferredFreeDays
        ..clear()
        ..addAll(prefs.getStringList('freeDays') ?? []);
      _dropInvalidSelections();
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('grade', _grade);
    await prefs.setInt('maxCredits', _maxCredits);
    await prefs.setBool('morning', _preferMorning);
    await prefs.setBool('avoidTeam', _avoidTeamProject);
    await prefs.setDouble('wFree', _freeTimeWeight);
    await prefs.setDouble('wRating', _ratingWeight);
    await prefs.setDouble('wDiff', _difficultyWeight);
    await prefs.setInt('minStart', _minStartHour);
    await prefs.setInt('maxEnd', _maxEndHour);
    await prefs.setBool('lunchBreak', _requireLunchBreak);
    await prefs.setStringList('requiredIds', _requiredIds.toList());
    await prefs.setStringList('freeDays', _preferredFreeDays.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AppState>(
      builder: (context, state, _) {
        return Stack(
          children: [
            Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: _PreferenceHero(
                        grade: _grade,
                        maxCredits: _maxCredits,
                        preferredFreeDays: _preferredFreeDays.length,
                        requireLunchBreak: _requireLunchBreak,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SectionCard(
                          title: '기본 조건',
                          subtitle: '학년과 최대 학점을 정하면 추천 엔진이 가능한 후보군을 먼저 정리합니다.',
                          icon: Icons.tune_rounded,
                          child: Column(
                            children: [
                              _ChoiceGroup<int>(
                                label: '학년',
                                value: _grade,
                                options: const [1, 2, 3, 4],
                                labelBuilder: (value) => '$value학년',
                                onChanged: (value) {
                                  setState(() {
                                    _grade = value;
                                    _dropInvalidSelections();
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              _ChoiceGroup<int>(
                                label: '최대 학점',
                                value: _maxCredits,
                                options: const [12, 15, 18, 21],
                                labelBuilder: (value) => '$value학점',
                                onChanged: (value) =>
                                    setState(() => _maxCredits = value),
                              ),
                              const SizedBox(height: 20),
                              _PreferenceToggle(
                                icon: Icons.wb_sunny_outlined,
                                title: '오전 수업 선호',
                                subtitle: '이른 시간대 수업을 더 높은 우선순위로 반영합니다.',
                                value: _preferMorning,
                                onChanged: (value) =>
                                    setState(() => _preferMorning = value),
                              ),
                              const SizedBox(height: 12),
                              _PreferenceToggle(
                                icon: Icons.group_off_outlined,
                                title: '팀프로젝트 최소화',
                                subtitle: '팀 기반 과목의 비중을 낮춰 더 안정적인 시간표를 만듭니다.',
                                value: _avoidTeamProject,
                                onChanged: (value) =>
                                    setState(() => _avoidTeamProject = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: '시간 제약',
                          subtitle:
                              '불가능한 시간대는 강하게 제외하고, 점심 시간과 공강 요일은 우선적으로 맞춥니다.',
                          icon: Icons.schedule_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ChoiceGroup<int>(
                                label: '최소 시작',
                                value: _minStartHour,
                                options: const [9, 10, 11],
                                labelBuilder: (value) => '$value:00',
                                onChanged: (value) =>
                                    setState(() => _minStartHour = value),
                              ),
                              const SizedBox(height: 18),
                              _ChoiceGroup<int>(
                                label: '최대 종료',
                                value: _maxEndHour,
                                options: const [18, 19, 20, 21],
                                labelBuilder: (value) => '$value:00',
                                onChanged: (value) =>
                                    setState(() => _maxEndHour = value),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '비우고 싶은 요일',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: weekdays.map((day) {
                                  final selected = _preferredFreeDays.contains(
                                    day,
                                  );
                                  return FilterChip(
                                    label: Text('$day요일'),
                                    selected: selected,
                                    onSelected: (_) {
                                      setState(() {
                                        if (selected) {
                                          _preferredFreeDays.remove(day);
                                        } else {
                                          _preferredFreeDays.add(day);
                                        }
                                      });
                                    },
                                    showCheckmark: false,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 18),
                              _PreferenceToggle(
                                icon: Icons.lunch_dining_outlined,
                                title: '점심 시간 확보',
                                subtitle: '12시부터 1시 사이 수업 배치를 가능한 한 피합니다.',
                                value: _requireLunchBreak,
                                onChanged: (value) =>
                                    setState(() => _requireLunchBreak = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: '추천 가중치',
                          subtitle: '점수식이 어떤 기준을 더 강하게 반영할지 직접 조절할 수 있습니다.',
                          icon: Icons.equalizer_rounded,
                          child: Column(
                            children: [
                              _WeightSlider(
                                title: '공강과 여유 시간',
                                value: _freeTimeWeight,
                                color: AppTheme.blue,
                                onChanged: (value) =>
                                    setState(() => _freeTimeWeight = value),
                              ),
                              _WeightSlider(
                                title: '강의 평점',
                                value: _ratingWeight,
                                color: AppTheme.cyan,
                                onChanged: (value) =>
                                    setState(() => _ratingWeight = value),
                              ),
                              _WeightSlider(
                                title: '난이도 안정성',
                                value: _difficultyWeight,
                                color: AppTheme.coral,
                                onChanged: (value) =>
                                    setState(() => _difficultyWeight = value),
                              ),
                              const SizedBox(height: 6),
                              _WeightSummary(
                                freeTimeWeight: _freeTimeWeight,
                                ratingWeight: _ratingWeight,
                                difficultyWeight: _difficultyWeight,
                                avoidTeamProject: _avoidTeamProject,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_requiredCourseGroups.isNotEmpty)
                          _SectionCard(
                            title: '필수 과목 분반 선택',
                            subtitle:
                                '같은 과목의 여러 분반을 동시에 넣지 않도록 과목별 한 분반만 선택됩니다.',
                            icon: Icons.library_books_rounded,
                            child: Column(
                              children: _requiredCourseGroups
                                  .map(
                                    (group) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _RequiredCourseSelector(
                                        courses: group,
                                        selectedId: _selectedIdFor(group),
                                        onSelect: (course) => setState(
                                          () => _selectRequiredCourse(course),
                                        ),
                                        onClear: () => setState(
                                          () => _clearRequiredCourse(
                                            group.first.courseCode,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => _run(context, state),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('추천 시간표 생성'),
                    ),
                  ),
                ),
              ),
            ),
            if (state.isLoading) const MatchingLoadingOverlay(),
          ],
        );
      },
    );
  }

  String? _selectedIdFor(List<Course> group) {
    for (final course in group) {
      if (_requiredIds.contains(course.id)) {
        return course.id;
      }
    }
    return null;
  }

  void _selectRequiredCourse(Course course) {
    _requiredIds.removeWhere((id) => id.startsWith(course.courseCode));
    _requiredIds.add(course.id);
  }

  void _clearRequiredCourse(String courseCode) {
    _requiredIds.removeWhere((id) => id.startsWith(courseCode));
  }

  void _dropInvalidSelections() {
    final validIds = _requiredCourses.map((course) => course.id).toSet();
    _requiredIds.removeWhere((id) => !validIds.contains(id));
  }

  Future<void> _run(BuildContext context, AppState state) async {
    await _savePrefs();

    state.updatePref(
      UserPreference(
        major: '컴퓨터공학과',
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
      ),
    );
    await state.runMatching();
    if (context.mounted) {
      Navigator.pushNamed(context, '/results');
    }
  }
}

class _PreferenceHero extends StatelessWidget {
  final int grade;
  final int maxCredits;
  final int preferredFreeDays;
  final bool requireLunchBreak;

  const _PreferenceHero({
    required this.grade,
    required this.maxCredits,
    required this.preferredFreeDays,
    required this.requireLunchBreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '개인화 추천 설정',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '조건을 더 정확하게 입력할수록 추천 정합도가 올라갑니다.',
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: -0.6),
          ),
          const SizedBox(height: 10),
          Text(
            '유전 알고리즘이 분반 조합을 탐색한 뒤, 공강 집중도와 학점 충실도까지 다시 보정합니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(icon: Icons.school_rounded, label: '$grade학년 기준'),
              _HeroPill(
                icon: Icons.credit_score_rounded,
                label: '$maxCredits학점 상한',
              ),
              _HeroPill(
                icon: Icons.event_available_rounded,
                label: '공강 희망 $preferredFreeDays일',
              ),
              _HeroPill(
                icon: Icons.lunch_dining_rounded,
                label: requireLunchBreak ? '점심 시간 우선' : '점심 제약 없음',
              ),
            ],
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
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
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceGroup<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  const _ChoiceGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final selected = value == option;
            return ChoiceChip(
              label: Text(labelBuilder(option)),
              selected: selected,
              onSelected: (_) => onChanged(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _WeightSlider({
    required this.title,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${(value * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ],
            ),
            Slider(
              value: value,
              onChanged: onChanged,
              min: 0,
              max: 1,
              divisions: 10,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightSummary extends StatelessWidget {
  final double freeTimeWeight;
  final double ratingWeight;
  final double difficultyWeight;
  final bool avoidTeamProject;

  const _WeightSummary({
    required this.freeTimeWeight,
    required this.ratingWeight,
    required this.difficultyWeight,
    required this.avoidTeamProject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamWeight = avoidTeamProject ? 0.2 : 0.0;
    final total = freeTimeWeight + ratingWeight + difficultyWeight + teamWeight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        avoidTeamProject
            ? '팀프로젝트 회피 보정까지 포함해 총 ${(total * 100).round()}% 비중으로 점수를 계산합니다.'
            : '설정한 세 가중치를 중심으로 점수를 계산합니다. 현재 총합은 ${(total * 100).round()}%입니다.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _RequiredCourseSelector extends StatelessWidget {
  final List<Course> courses;
  final String? selectedId;
  final ValueChanged<Course> onSelect;
  final VoidCallback onClear;

  const _RequiredCourseSelector({
    required this.courses,
    required this.selectedId,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = courses.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${course.grade}학년 · ${course.credit}학점',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selectedId != null)
                TextButton(onPressed: onClear, child: const Text('선택 해제')),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: courses.map((section) {
              final selected = selectedId == section.id;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                label: Text('${section.section}분반 · ${section.timeSummary}'),
                onSelected: (_) => onSelect(section),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
