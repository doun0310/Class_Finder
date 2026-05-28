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
  final Set<String> _selectedMajorIds = {};
  final Set<String> _selectedLiberalArtsIds = {};
  final Map<int, List<_CourseSelectionGroup>> _automaticRequiredGroupsCache =
      {};
  final Map<int, List<_CourseSelectionGroup>> _majorGroupsCache = {};
  late final List<_CourseSelectionGroup> _liberalArtsGroups = _groupCourses(
    realCourses.where(
      (course) => course.category == CourseCategory.coreLiberalArts,
    ),
  );

  int _minStartHour = 9;
  int _maxEndHour = 20;
  final Set<String> _preferredFreeDays = {};
  bool _requireLunchBreak = false;

  List<_CourseSelectionGroup> get _automaticRequiredGroups =>
      _automaticRequiredGroupsFor(_grade);

  List<_CourseSelectionGroup> get _majorGroups => _majorGroupsFor(_grade);

  List<Course> get _selectedMajorCourses =>
      _selectedCourses(_selectedMajorIds, _majorGroups);

  List<Course> get _selectedLiberalArtsCourses =>
      _selectedCourses(_selectedLiberalArtsIds, _liberalArtsGroups);

  List<_CourseSelectionGroup> _automaticRequiredGroupsFor(int grade) {
    return _automaticRequiredGroupsCache.putIfAbsent(grade, () {
      final groups = _groupCourses(
        realCourses.where(
          (course) =>
              course.category == CourseCategory.majorRequired &&
              course.grade == grade,
        ),
      );
      groups.sort((a, b) {
        final gradeCompare = a.grade.compareTo(b.grade);
        if (gradeCompare != 0) {
          return gradeCompare;
        }
        return a.name.compareTo(b.name);
      });
      return List.unmodifiable(groups);
    });
  }

  List<_CourseSelectionGroup> _majorGroupsFor(int grade) {
    return _majorGroupsCache.putIfAbsent(grade, () {
      final groups = _groupCourses(
        realCourses.where(
          (course) =>
              course.category == CourseCategory.majorElective &&
              course.hasTimeSlots &&
              (course.grade == 0 || course.grade <= grade),
        ),
      );
      groups.sort((a, b) {
        final gradeCompare = a.grade.compareTo(b.grade);
        if (gradeCompare != 0) {
          return gradeCompare;
        }
        return a.name.compareTo(b.name);
      });
      return List.unmodifiable(groups);
    });
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
      _selectedMajorIds
        ..clear()
        ..addAll(prefs.getStringList('selectedMajorIds') ?? const []);
      _selectedLiberalArtsIds
        ..clear()
        ..addAll(prefs.getStringList('selectedLiberalIds') ?? const []);
      _preferredFreeDays
        ..clear()
        ..addAll(prefs.getStringList('freeDays') ?? const []);
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
    await prefs.setStringList(
      'selectedMajorIds',
      _selectedMajorIds.toList()..sort(),
    );
    await prefs.setStringList(
      'selectedLiberalIds',
      _selectedLiberalArtsIds.toList()..sort(),
    );
    await prefs.setStringList('freeDays', _preferredFreeDays.toList()..sort());
    await prefs.remove('requiredIds');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final automaticRequiredGroups = _automaticRequiredGroups;
    final selectedMajorCourses = _selectedMajorCourses;
    final selectedLiberalArtsCourses = _selectedLiberalArtsCourses;

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
                        automaticRequiredCount: automaticRequiredGroups.length,
                        selectedMajorCount: selectedMajorCourses.length,
                        selectedLiberalCount: selectedLiberalArtsCourses.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SectionCard(
                          title: '기본 조건',
                          subtitle: '학년과 최대 학점을 기준으로 먼저 추천 범위를 잡습니다.',
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
                                subtitle: '이른 시간 수업을 상대적으로 우선 배치합니다.',
                                value: _preferMorning,
                                onChanged: (value) =>
                                    setState(() => _preferMorning = value),
                              ),
                              const SizedBox(height: 12),
                              _PreferenceToggle(
                                icon: Icons.group_off_outlined,
                                title: '팀프로젝트 최소화',
                                subtitle: '팀 기반 과목의 비중을 줄여 보다 안정적인 시간표를 찾습니다.',
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
                          subtitle: '수업 가능 시간과 비워두고 싶은 요일을 함께 반영합니다.',
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
                                subtitle: '12시부터 1시 사이에 수업이 겹치지 않는 조합을 우선합니다.',
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
                          subtitle: '무엇을 더 중요하게 볼지 직접 조정할 수 있습니다.',
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
                        _SectionCard(
                          title: '자동 반영 전공필수',
                          subtitle:
                              '전공필수는 학년 기준으로 자동 포함되며, 추천 엔진이 충돌 없는 분반을 고릅니다.',
                          icon: Icons.auto_fix_high_rounded,
                          child: automaticRequiredGroups.isEmpty
                              ? _SelectionEmptyState(
                                  icon: Icons.school_outlined,
                                  message: '현재 학년 기준으로 자동 반영할 전공필수가 없습니다.',
                                )
                              : Column(
                                  children: automaticRequiredGroups
                                      .map(
                                        (group) => _AutomaticRequiredTile(
                                          group: group,
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 14),
                        _SelectableCoursePanel(
                          title: '전공 선택',
                          subtitle: '전공 선택 과목은 원하는 분반을 직접 고정해서 포함할 수 있습니다.',
                          icon: Icons.memory_rounded,
                          actionLabel: '전공 분반 선택',
                          accentColor: AppTheme.blue,
                          selectedCourses: selectedMajorCourses,
                          emptyMessage: '선택한 전공 과목이 없습니다.',
                          onEdit: () => _openSelectionSheet(
                            title: '전공 선택',
                            subtitle: '전공선택 과목에서 원하는 분반을 고정으로 포함합니다.',
                            groups: _majorGroups,
                            initialSelectedIds: _selectedMajorIds,
                            accentColor: AppTheme.blue,
                            onApplied: (selectedIds) {
                              _selectedMajorIds
                                ..clear()
                                ..addAll(selectedIds);
                            },
                          ),
                          onClear: selectedMajorCourses.isEmpty
                              ? null
                              : () => setState(_selectedMajorIds.clear),
                          onRemove: (course) => setState(
                            () => _selectedMajorIds.remove(course.id),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SelectableCoursePanel(
                          title: '교양 선택',
                          subtitle: '추가한 핵심교양 데이터에서 원하는 분반을 따로 선택할 수 있습니다.',
                          icon: Icons.menu_book_rounded,
                          actionLabel: '교양 분반 선택',
                          accentColor: AppTheme.cyan,
                          selectedCourses: selectedLiberalArtsCourses,
                          emptyMessage: '선택한 교양 과목이 없습니다.',
                          onEdit: () => _openSelectionSheet(
                            title: '교양 선택',
                            subtitle: '핵심교양 과목에서 원하는 분반을 고정으로 포함합니다.',
                            groups: _liberalArtsGroups,
                            initialSelectedIds: _selectedLiberalArtsIds,
                            accentColor: AppTheme.cyan,
                            onApplied: (selectedIds) {
                              _selectedLiberalArtsIds
                                ..clear()
                                ..addAll(selectedIds);
                            },
                          ),
                          onClear: selectedLiberalArtsCourses.isEmpty
                              ? null
                              : () => setState(_selectedLiberalArtsIds.clear),
                          onRemove: (course) => setState(
                            () => _selectedLiberalArtsIds.remove(course.id),
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
            if (state.isLoading)
              MatchingLoadingOverlay(
                expectedDuration: state.estimatedMatchingDuration,
                recentDuration: state.lastMatchingDuration,
              ),
          ],
        );
      },
    );
  }

  List<_CourseSelectionGroup> _groupCourses(Iterable<Course> courses) {
    final grouped = <String, List<Course>>{};
    for (final course in courses) {
      grouped.putIfAbsent(course.courseCode, () => []).add(course);
    }

    final groups = grouped.entries.map((entry) {
      final sections = List<Course>.of(entry.value)
        ..sort((a, b) {
          final startCompare = a.earliestStartHour.compareTo(
            b.earliestStartHour,
          );
          if (startCompare != 0) {
            return startCompare;
          }
          final endCompare = a.latestEndHour.compareTo(b.latestEndHour);
          if (endCompare != 0) {
            return endCompare;
          }
          return a.section.compareTo(b.section);
        });
      final sample = sections.first;
      return _CourseSelectionGroup(
        courseCode: entry.key,
        name: sample.name,
        credit: sample.credit,
        grade: sample.grade,
        category: sample.category,
        sections: sections,
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return groups;
  }

  List<Course> _selectedCourses(
    Set<String> selectedIds,
    List<_CourseSelectionGroup> groups,
  ) {
    final selectedCourses = <Course>[];
    for (final group in groups) {
      final selected = group.selectedCourse(selectedIds);
      if (selected != null) {
        selectedCourses.add(selected);
      }
    }
    return selectedCourses;
  }

  Set<String> _normalizeSelections(
    Iterable<String> selectedIds,
    List<_CourseSelectionGroup> groups,
  ) {
    final rawIds = selectedIds.toSet();
    final normalized = <String>{};

    for (final group in groups) {
      for (final course in group.sections) {
        if (rawIds.contains(course.id)) {
          normalized.add(course.id);
          break;
        }
      }
    }

    return normalized;
  }

  void _dropInvalidSelections() {
    final normalizedMajor = _normalizeSelections(
      _selectedMajorIds,
      _majorGroups,
    );
    final normalizedLiberal = _normalizeSelections(
      _selectedLiberalArtsIds,
      _liberalArtsGroups,
    );

    _selectedMajorIds
      ..clear()
      ..addAll(normalizedMajor);
    _selectedLiberalArtsIds
      ..clear()
      ..addAll(normalizedLiberal);
  }

  Future<void> _openSelectionSheet({
    required String title,
    required String subtitle,
    required List<_CourseSelectionGroup> groups,
    required Set<String> initialSelectedIds,
    required Color accentColor,
    required ValueChanged<Set<String>> onApplied,
  }) async {
    final selectedIds = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseSelectionSheet(
        title: title,
        subtitle: subtitle,
        groups: groups,
        initialSelectedIds: initialSelectedIds,
        accentColor: accentColor,
      ),
    );

    if (!mounted || selectedIds == null) {
      return;
    }

    setState(() {
      onApplied(_normalizeSelections(selectedIds, groups));
    });
  }

  Future<void> _run(BuildContext context, AppState state) async {
    await _savePrefs();

    state.updatePref(
      UserPreference(
        major: '컴퓨터공학부',
        grade: _grade,
        maxCredits: _maxCredits,
        preferMorning: _preferMorning,
        avoidTeamProject: _avoidTeamProject,
        freeTimeWeight: _freeTimeWeight,
        ratingWeight: _ratingWeight,
        difficultyWeight: _difficultyWeight,
        selectedMajorCourseIds: _selectedMajorIds.toList()..sort(),
        selectedLiberalArtsCourseIds: _selectedLiberalArtsIds.toList()..sort(),
        minStartHour: _minStartHour,
        maxEndHour: _maxEndHour,
        preferredFreeDays: _preferredFreeDays.toList()..sort(),
        requireLunchBreak: _requireLunchBreak,
      ),
    );
    await state.runMatching();
    if (context.mounted) {
      Navigator.pushNamed(context, '/results');
    }
  }
}

class _CourseSelectionGroup {
  final String courseCode;
  final String name;
  final int credit;
  final int grade;
  final CourseCategory category;
  final List<Course> sections;

  const _CourseSelectionGroup({
    required this.courseCode,
    required this.name,
    required this.credit,
    required this.grade,
    required this.category,
    required this.sections,
  });

  Course? selectedCourse(Iterable<String> selectedIds) {
    for (final section in sections) {
      if (selectedIds.contains(section.id)) {
        return section;
      }
    }
    return null;
  }
}

class _PreferenceHero extends StatelessWidget {
  final int grade;
  final int maxCredits;
  final int automaticRequiredCount;
  final int selectedMajorCount;
  final int selectedLiberalCount;

  const _PreferenceHero({
    required this.grade,
    required this.maxCredits,
    required this.automaticRequiredCount,
    required this.selectedMajorCount,
    required this.selectedLiberalCount,
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
              '맞춤 시간표 설정',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '전공과 교양을 분리해서 고르고, 전공필수는 자동으로 반영합니다.',
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: -0.6),
          ),
          const SizedBox(height: 10),
          Text(
            '선택한 전공과 교양 분반은 고정으로 포함하고, 전공필수는 충돌 없는 분반 조합으로 자동 배치합니다.',
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
                icon: Icons.auto_fix_high_rounded,
                label: '전공필수 $automaticRequiredCount과목',
              ),
              _HeroPill(
                icon: Icons.memory_rounded,
                label: '전공 선택 $selectedMajorCount과목',
              ),
              _HeroPill(
                icon: Icons.menu_book_rounded,
                label: '교양 선택 $selectedLiberalCount과목',
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
            : '설정한 세 가지 가중치를 중심으로 점수를 계산합니다. 현재 총합은 ${(total * 100).round()}%입니다.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _AutomaticRequiredTile extends StatelessWidget {
  final _CourseSelectionGroup group;

  const _AutomaticRequiredTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
                  child: Text(group.name, style: theme.textTheme.titleSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '자동 반영',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoBadge(label: _gradeLabel(group.grade)),
                _InfoBadge(label: '${group.credit}학점'),
                _InfoBadge(label: '${group.sections.length}개 분반'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableCoursePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final Color accentColor;
  final List<Course> selectedCourses;
  final String emptyMessage;
  final VoidCallback onEdit;
  final VoidCallback? onClear;
  final ValueChanged<Course> onRemove;

  const _SelectableCoursePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.accentColor,
    required this.selectedCourses,
    required this.emptyMessage,
    required this.onEdit,
    required this.onRemove,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${selectedCourses.length}개 선택',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (onClear != null)
                TextButton(onPressed: onClear, child: const Text('전체 해제')),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedCourses.isEmpty)
            _SelectionEmptyState(icon: icon, message: emptyMessage)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: selectedCourses.map((course) {
                    return InputChip(
                      label: Text('${course.name} ${course.section}분반'),
                      tooltip: '${course.timeSummary} · ${course.professor}',
                      onDeleted: () => onRemove(course),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  '선택한 분반은 시간표 생성 시 반드시 포함됩니다.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SelectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SelectionEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _CourseSelectionSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<_CourseSelectionGroup> groups;
  final Set<String> initialSelectedIds;
  final Color accentColor;

  const _CourseSelectionSheet({
    required this.title,
    required this.subtitle,
    required this.groups,
    required this.initialSelectedIds,
    required this.accentColor,
  });

  @override
  State<_CourseSelectionSheet> createState() => _CourseSelectionSheetState();
}

class _CourseSelectionSheetState extends State<_CourseSelectionSheet> {
  late final Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initialSelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredGroups = widget.groups.where((group) {
      if (_query.trim().isEmpty) {
        return true;
      }

      final query = _query.trim().toLowerCase();
      if (group.name.toLowerCase().contains(query) ||
          group.courseCode.toLowerCase().contains(query)) {
        return true;
      }

      return group.sections.any(
        (section) =>
            section.professor.toLowerCase().contains(query) ||
            section.timeSummary.toLowerCase().contains(query),
      );
    }).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          top: 18,
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.88,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(widget.subtitle, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          hintText: '과목명, 교수명, 시간 검색',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredGroups.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '검색 조건에 맞는 과목이 없습니다.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemBuilder: (context, index) {
                            final group = filteredGroups[index];
                            final selectedCourse = group.selectedCourse(
                              _selectedIds,
                            );

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              group.name,
                                              style: theme.textTheme.titleSmall,
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _InfoBadge(
                                                  label: _gradeLabel(
                                                    group.grade,
                                                  ),
                                                ),
                                                _InfoBadge(
                                                  label: '${group.credit}학점',
                                                ),
                                                _InfoBadge(
                                                  label:
                                                      '${group.sections.length}개 분반',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (selectedCourse != null)
                                        TextButton(
                                          onPressed: () => _clearGroup(group),
                                          child: const Text('해제'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: group.sections.map((section) {
                                      final selected = _selectedIds.contains(
                                        section.id,
                                      );
                                      return ChoiceChip(
                                        selected: selected,
                                        showCheckmark: false,
                                        onSelected: (_) =>
                                            _toggleSection(group, section),
                                        label: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 220,
                                          ),
                                          child: Text(
                                            '${section.section}분반 · ${section.timeSummary}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemCount: filteredGroups.length,
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedIds.length}개 과목 선택',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(_selectedIds.clear),
                        child: const Text('초기화'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          Set<String>.from(_selectedIds),
                        ),
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSection(_CourseSelectionGroup group, Course section) {
    setState(() {
      final isSelected = _selectedIds.contains(section.id);
      _selectedIds.removeWhere(
        (selectedId) => group.sections.any((course) => course.id == selectedId),
      );
      if (!isSelected) {
        _selectedIds.add(section.id);
      }
    });
  }

  void _clearGroup(_CourseSelectionGroup group) {
    setState(() {
      _selectedIds.removeWhere(
        (selectedId) => group.sections.any((course) => course.id == selectedId),
      );
    });
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;

  const _InfoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}

String _gradeLabel(int grade) {
  if (grade <= 0) {
    return '공통';
  }
  return '$grade학년';
}
