import 'package:flutter/material.dart';

import '../models/course.dart';
import '../services/real_courses.dart';
import '../theme/app_theme.dart';
import '../widgets/rating_source_badge.dart';

enum SortMode { rating, name, difficulty, credit }

enum CourseScopeFilter {
  all,
  majorRequired,
  majorElective,
  coreLiberalArts,
  balancedLiberalArts,
  generalElective,
}

extension on CourseScopeFilter {
  String get label => switch (this) {
    CourseScopeFilter.all => '전체',
    CourseScopeFilter.majorRequired => '전공필수',
    CourseScopeFilter.majorElective => '전공선택',
    CourseScopeFilter.coreLiberalArts => '핵심교양',
    CourseScopeFilter.balancedLiberalArts => '균형교양',
    CourseScopeFilter.generalElective => '일반교양',
  };

  bool matches(Course course) => switch (this) {
    CourseScopeFilter.all => true,
    CourseScopeFilter.majorRequired =>
      course.category == CourseCategory.majorRequired,
    CourseScopeFilter.majorElective =>
      course.category == CourseCategory.majorElective,
    CourseScopeFilter.coreLiberalArts =>
      course.category == CourseCategory.coreLiberalArts,
    CourseScopeFilter.balancedLiberalArts =>
      course.category == CourseCategory.balancedLiberalArts,
    CourseScopeFilter.generalElective =>
      course.category == CourseCategory.generalElective,
  };
}

class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final _controller = TextEditingController();
  late final Map<String, String> _searchIndex = {
    for (final course in realCourses)
      course.id: [
        course.name,
        course.professor,
        course.courseCode,
        course.categoryLabel,
        course.timeSummary,
      ].join(' ').toLowerCase(),
  };
  late final int _totalSections = realCourses.length;
  late final int _majorRequiredCount = realCourses
      .where((course) => course.category == CourseCategory.majorRequired)
      .length;
  late final int _majorElectiveCount = realCourses
      .where((course) => course.category == CourseCategory.majorElective)
      .length;
  late final int _coreLiberalArtsCount = realCourses
      .where((course) => course.category == CourseCategory.coreLiberalArts)
      .length;
  late final int _balancedLiberalArtsCount = realCourses
      .where((course) => course.category == CourseCategory.balancedLiberalArts)
      .length;
  late final int _unscheduledCount = realCourses
      .where((course) => !course.hasTimeSlots)
      .length;
  String _query = '';
  int? _gradeFilter;
  bool? _teamFilter;
  bool? _scheduledFilter;
  CourseScopeFilter _scopeFilter = CourseScopeFilter.all;
  SortMode _sort = SortMode.rating;

  List<Course> get _filtered {
    final query = _query.trim().toLowerCase();

    final filtered = realCourses.where((course) {
      if (query.isNotEmpty) {
        if (!_searchIndex[course.id]!.contains(query)) {
          return false;
        }
      }

      if (_gradeFilter != null && course.grade != _gradeFilter) {
        return false;
      }
      if (!_scopeFilter.matches(course)) {
        return false;
      }
      if (_teamFilter != null && course.hasTeamProject != _teamFilter) {
        return false;
      }
      if (_scheduledFilter != null && course.hasTimeSlots != _scheduledFilter) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case SortMode.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      case SortMode.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.difficulty:
        filtered.sort((a, b) => a.difficulty.compareTo(b.difficulty));
      case SortMode.credit:
        filtered.sort((a, b) => b.credit.compareTo(a.credit));
    }

    return filtered;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filtered;
    final theme = Theme.of(context);
    final totalSections = _totalSections;
    final majorRequiredCount = _majorRequiredCount;
    final majorElectiveCount = _majorElectiveCount;
    final coreLiberalArtsCount = _coreLiberalArtsCount;
    final balancedLiberalArtsCount = _balancedLiberalArtsCount;
    final unscheduledCount = _unscheduledCount;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('강의 탐색', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      '추가한 모든 강의를 한 화면에서 보고, 분반별 평점과 시간표 상태까지 바로 비교할 수 있습니다.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _SummaryChip(
                          icon: Icons.library_books_rounded,
                          label: '전체 $totalSections개',
                          color: AppTheme.blue,
                        ),
                        _SummaryChip(
                          icon: Icons.push_pin_rounded,
                          label: '전필 $majorRequiredCount개',
                          color: AppTheme.coral,
                        ),
                        _SummaryChip(
                          icon: Icons.memory_rounded,
                          label: '전선 $majorElectiveCount개',
                          color: AppTheme.blue,
                        ),
                        _SummaryChip(
                          icon: Icons.menu_book_rounded,
                          label: '핵심교양 $coreLiberalArtsCount개',
                          color: AppTheme.cyan,
                        ),
                        _SummaryChip(
                          icon: Icons.auto_stories_rounded,
                          label: '균형교양 $balancedLiberalArtsCount개',
                          color: AppTheme.leaf,
                        ),
                        _SummaryChip(
                          icon: Icons.event_busy_rounded,
                          label: '시간표 미지정 $unscheduledCount개',
                          color: AppTheme.slate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('평점 근거', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        RatingSourceBadge(
                          source: RatingSource.officialEstimate,
                        ),
                        RatingSourceBadge(source: RatingSource.userInput),
                        RatingSourceBadge(source: RatingSource.reviewBacked),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '공개 자료 기반 추정, 직접 입력, 실제 리뷰 반영 여부를 배지로 구분합니다.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SearchBar(
                      controller: _controller,
                      hintText: '과목명, 교수명, 과목코드, 시간으로 검색',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_query.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _FilterPanel(
                gradeFilter: _gradeFilter,
                teamFilter: _teamFilter,
                scheduledFilter: _scheduledFilter,
                scopeFilter: _scopeFilter,
                sort: _sort,
                onGrade: (value) => setState(() => _gradeFilter = value),
                onTeam: (value) => setState(() => _teamFilter = value),
                onScheduled: (value) =>
                    setState(() => _scheduledFilter = value),
                onScope: (value) => setState(() => _scopeFilter = value),
                onSort: (value) => setState(() => _sort = value),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '검색 결과 ${courses.length}개 분반',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          if (courses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 42,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '조건에 맞는 강의가 없습니다.',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '필터를 일부 해제하거나 검색어를 줄여서 다시 확인해 보세요.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: courses.length,
                itemBuilder: (context, index) =>
                    _CourseCard(course: courses[index]),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
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

class _FilterPanel extends StatelessWidget {
  final int? gradeFilter;
  final bool? teamFilter;
  final bool? scheduledFilter;
  final CourseScopeFilter scopeFilter;
  final SortMode sort;
  final ValueChanged<int?> onGrade;
  final ValueChanged<bool?> onTeam;
  final ValueChanged<bool?> onScheduled;
  final ValueChanged<CourseScopeFilter> onScope;
  final ValueChanged<SortMode> onSort;

  const _FilterPanel({
    required this.gradeFilter,
    required this.teamFilter,
    required this.scheduledFilter,
    required this.scopeFilter,
    required this.sort,
    required this.onGrade,
    required this.onTeam,
    required this.onScheduled,
    required this.onScope,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterGroup<int?>(
            title: '학년',
            selected: gradeFilter,
            options: const [null, 1, 2, 3, 4],
            labelBuilder: (value) => value == null ? '전체' : '$value학년',
            onSelected: onGrade,
          ),
          const SizedBox(height: 14),
          _FilterGroup<CourseScopeFilter>(
            title: '구분',
            selected: scopeFilter,
            options: CourseScopeFilter.values,
            labelBuilder: (value) => value.label,
            onSelected: onScope,
          ),
          const SizedBox(height: 14),
          _FilterGroup<bool?>(
            title: '시간표 상태',
            selected: scheduledFilter,
            options: const [null, true, false],
            labelBuilder: (value) {
              if (value == null) {
                return '전체';
              }
              return value ? '시간표 있음' : '시간표 미지정';
            },
            onSelected: onScheduled,
          ),
          const SizedBox(height: 14),
          _FilterGroup<bool?>(
            title: '팀프로젝트',
            selected: teamFilter,
            options: const [null, true, false],
            labelBuilder: (value) {
              if (value == null) {
                return '전체';
              }
              return value ? '포함' : '없음';
            },
            onSelected: onTeam,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('정렬', style: theme.textTheme.titleSmall),
              const Spacer(),
              DropdownButton<SortMode>(
                value: sort,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(18),
                items: const [
                  DropdownMenuItem(
                    value: SortMode.rating,
                    child: Text('평점 높은 순'),
                  ),
                  DropdownMenuItem(
                    value: SortMode.difficulty,
                    child: Text('난이도 낮은 순'),
                  ),
                  DropdownMenuItem(
                    value: SortMode.credit,
                    child: Text('학점 높은 순'),
                  ),
                  DropdownMenuItem(value: SortMode.name, child: Text('이름 순')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onSort(value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterGroup<T> extends StatelessWidget {
  final String title;
  final T selected;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  const _FilterGroup({
    required this.title,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            return ChoiceChip(
              selected: selected == option,
              label: Text(labelBuilder(option)),
              onSelected: (_) => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => _showDetail(context),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag(
                          text: _gradeLabel(course.grade),
                          color: AppTheme.blue,
                        ),
                        _Tag(
                          text: course.categoryLabel,
                          color: switch (course.category) {
                            CourseCategory.majorRequired => AppTheme.coral,
                            CourseCategory.majorElective => AppTheme.blue,
                            CourseCategory.coreLiberalArts => AppTheme.cyan,
                            CourseCategory.balancedLiberalArts => AppTheme.leaf,
                            CourseCategory.generalElective => AppTheme.slate,
                          },
                        ),
                        if (course.hasTeamProject)
                          const _Tag(text: '팀프로젝트', color: AppTheme.cyan),
                        if (!course.hasTimeSlots)
                          const _Tag(text: '시간표 미지정', color: AppTheme.leaf),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${course.credit}학점',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppTheme.coral,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(course.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '${course.professor} · ${course.section}분반 · ${course.timeSummary}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RatingSourceBadge(source: course.ratingSource, compact: true),
                  Text(
                    '과목코드 ${course.courseCode}',
                    style: theme.textTheme.labelMedium,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CourseDetailSheet(course: course),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _CourseDetailSheet extends StatelessWidget {
  final Course course;

  const _CourseDetailSheet({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.64,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(course.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${course.professor} · ${course.section}분반',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '과목코드 ${course.courseCode}',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: '학점',
                    value: '${course.credit}학점',
                    icon: Icons.credit_score_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    label: '학년',
                    value: _gradeLabel(course.grade),
                    icon: Icons.school_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    label: '구분',
                    value: course.categoryLabel,
                    icon: Icons.category_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('강의 평점', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 8),
                        Text(
                          course.rating.toStringAsFixed(1),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 54,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('난이도', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.circle,
                              size: 10,
                              color: index < course.difficulty
                                  ? AppTheme.coral
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('평점 근거', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 10),
                  RatingSourceBadge(source: course.ratingSource),
                  const SizedBox(height: 10),
                  Text(
                    course.ratingSource.description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('수업 시간', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            if (course.hasTimeSlots)
              ...course.timeSlots.map(
                (slot) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot.day,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${slot.startHour}:00 ~ ${slot.endHour}:00 (${slot.durationHours}시간)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.leaf.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded, color: AppTheme.leaf),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '이 과목은 공식 시간표에 강의 시간이 지정되지 않아 탐색 목록에서만 표시됩니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.leaf,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (course.hasTeamProject) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: AppTheme.cyan),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '이 강의에는 팀프로젝트가 포함되어 있습니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

String _gradeLabel(int grade) => grade <= 0 ? '공통' : '$grade학년';
