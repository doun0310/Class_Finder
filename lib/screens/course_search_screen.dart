import 'package:flutter/material.dart';

import '../models/course.dart';
import '../services/real_courses.dart';
import '../theme/app_theme.dart';

enum SortMode { name, rating, difficulty, credit }

class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  int? _gradeFilter;
  bool? _requiredFilter;
  bool? _teamFilter;
  SortMode _sort = SortMode.rating;

  List<Course> get _filtered {
    final query = _query.trim();
    final normalized = query.toLowerCase();

    final filtered = realCourses.where((course) {
      if (normalized.isNotEmpty) {
        final matched =
            course.name.toLowerCase().contains(normalized) ||
            course.professor.toLowerCase().contains(normalized) ||
            course.timeSummary.toLowerCase().contains(normalized);
        if (!matched) {
          return false;
        }
      }
      if (_gradeFilter != null && course.grade != _gradeFilter) {
        return false;
      }
      if (_requiredFilter != null &&
          course.isMajorRequired != _requiredFilter) {
        return false;
      }
      if (_teamFilter != null && course.hasTeamProject != _teamFilter) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case SortMode.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
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
                      '학년, 평점, 팀프로젝트 여부까지 빠르게 필터링해 분반을 비교하세요.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SearchBar(
                      controller: _controller,
                      hintText: '과목명, 교수명, 시간대로 검색',
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
                requiredFilter: _requiredFilter,
                teamFilter: _teamFilter,
                sort: _sort,
                onGrade: (value) => setState(() => _gradeFilter = value),
                onRequired: (value) => setState(() => _requiredFilter = value),
                onTeam: (value) => setState(() => _teamFilter = value),
                onSort: (value) => setState(() => _sort = value),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '검색 결과 ${courses.length}개',
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
                        '필터를 일부 해제하거나 검색어를 넓혀 보세요.',
                        style: theme.textTheme.bodySmall,
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

class _FilterPanel extends StatelessWidget {
  final int? gradeFilter;
  final bool? requiredFilter;
  final bool? teamFilter;
  final SortMode sort;
  final ValueChanged<int?> onGrade;
  final ValueChanged<bool?> onRequired;
  final ValueChanged<bool?> onTeam;
  final ValueChanged<SortMode> onSort;

  const _FilterPanel({
    required this.gradeFilter,
    required this.requiredFilter,
    required this.teamFilter,
    required this.sort,
    required this.onGrade,
    required this.onRequired,
    required this.onTeam,
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
          _FilterGroup<bool?>(
            title: '이수 구분',
            selected: requiredFilter,
            options: const [null, true, false],
            labelBuilder: (value) {
              if (value == null) {
                return '전체';
              }
              return value ? '전공필수' : '선택';
            },
            onSelected: onRequired,
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
                  DropdownMenuItem(value: SortMode.name, child: Text('이름순')),
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
                children: [
                  _Tag(text: '${course.grade}학년', color: AppTheme.blue),
                  const SizedBox(width: 8),
                  if (course.isMajorRequired)
                    _Tag(text: '전공필수', color: AppTheme.coral),
                  if (course.hasTeamProject) ...[
                    const SizedBox(width: 8),
                    _Tag(text: '팀프로젝트', color: AppTheme.cyan),
                  ],
                  const Spacer(),
                  Text('${course.credit}학점', style: theme.textTheme.labelLarge),
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
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppTheme.coral,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    course.rating.toStringAsFixed(1),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(width: 18),
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
                    value: '${course.grade}학년',
                    icon: Icons.school_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    label: '구분',
                    value: course.isMajorRequired ? '전공필수' : '선택',
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
            const SizedBox(height: 18),
            Text('수업 시간', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
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
            ),
            if (course.hasTeamProject) ...[
              const SizedBox(height: 8),
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
                        '이 강의는 팀프로젝트가 포함되어 있습니다.',
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
          Text(value, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
