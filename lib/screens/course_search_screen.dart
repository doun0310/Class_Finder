import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/real_courses.dart';

enum SortMode { name, rating, difficulty, credit }

class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  int? _gradeFilter;       // null = 전체
  bool? _requiredFilter;   // null=전체, true=전필, false=전선
  bool? _teamFilter;       // null=전체, true=팀플, false=비팀플
  SortMode _sort = SortMode.name;

  List<Course> get _filtered {
    var list = realCourses.where((c) {
      if (_query.isNotEmpty &&
          !c.name.contains(_query) &&
          !c.professor.contains(_query)) { return false; }
      if (_gradeFilter != null && c.grade != _gradeFilter) return false;
      if (_requiredFilter != null && c.isMajorRequired != _requiredFilter) return false;
      if (_teamFilter != null && c.hasTeamProject != _teamFilter) return false;
      return true;
    }).toList();

    switch (_sort) {
      case SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortMode.difficulty:
        list.sort((a, b) => a.difficulty.compareTo(b.difficulty));
      case SortMode.credit:
        list.sort((a, b) => b.credit.compareTo(a.credit));
    }
    return list;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('과목 탐색'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _ctrl,
              hintText: '과목명 또는 교수명 검색',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: Column(children: [
        _FilterBar(
          gradeFilter: _gradeFilter,
          requiredFilter: _requiredFilter,
          teamFilter: _teamFilter,
          sort: _sort,
          onGrade: (v) => setState(() => _gradeFilter = v),
          onRequired: (v) => setState(() => _requiredFilter = v),
          onTeam: (v) => setState(() => _teamFilter = v),
          onSort: (v) => setState(() => _sort = v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            Text('${courses.length}개 과목',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
          ]),
        ),
        Expanded(
          child: courses.isEmpty
              ? const Center(child: Text('검색 결과가 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: courses.length,
                  itemBuilder: (_, i) => _CourseCard(course: courses[i]),
                ),
        ),
      ]),
    );
  }
}

// ── 필터 바 ───────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final int? gradeFilter;
  final bool? requiredFilter;
  final bool? teamFilter;
  final SortMode sort;
  final ValueChanged<int?> onGrade;
  final ValueChanged<bool?> onRequired;
  final ValueChanged<bool?> onTeam;
  final ValueChanged<SortMode> onSort;

  const _FilterBar({
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        // 학년 필터
        _FilterChipGroup<int?>(
          label: '학년',
          options: const [null, 1, 2, 3, 4],
          labels: const ['전체', '1학년', '2학년', '3학년', '4학년'],
          selected: gradeFilter,
          onSelected: onGrade,
        ),
        const SizedBox(width: 8),
        _FilterChipGroup<bool?>(
          label: '이수구분',
          options: const [null, true, false],
          labels: const ['전체', '전필', '전선'],
          selected: requiredFilter,
          onSelected: onRequired,
        ),
        const SizedBox(width: 8),
        _FilterChipGroup<bool?>(
          label: '팀플',
          options: const [null, true, false],
          labels: const ['전체', '있음', '없음'],
          selected: teamFilter,
          onSelected: onTeam,
        ),
        const SizedBox(width: 12),
        const VerticalDivider(width: 1, indent: 4, endIndent: 4),
        const SizedBox(width: 12),
        // 정렬
        DropdownButton<SortMode>(
          value: sort,
          isDense: true,
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: SortMode.name, child: Text('이름순')),
            DropdownMenuItem(value: SortMode.rating, child: Text('평점 높은순')),
            DropdownMenuItem(value: SortMode.difficulty, child: Text('난이도 낮은순')),
            DropdownMenuItem(value: SortMode.credit, child: Text('학점 높은순')),
          ],
          onChanged: (v) { if (v != null) onSort(v); },
        ),
      ]),
    );
  }
}

class _FilterChipGroup<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelected;

  const _FilterChipGroup({
    required this.label,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (i) {
        final isSelected = selected == options[i];
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FilterChip(
            label: Text(labels[i]),
            selected: isSelected,
            onSelected: (_) => onSelected(options[i]),
            visualDensity: VisualDensity.compact,
            labelStyle: const TextStyle(fontSize: 12),
            padding: const EdgeInsets.symmetric(horizontal: 2),
          ),
        );
      }),
    );
  }
}

// ── 과목 카드 ─────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  static const _gradeColors = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple
  ];

  @override
  Widget build(BuildContext context) {
    final gradeColor = course.grade > 0
        ? _gradeColors[(course.grade - 1) % _gradeColors.length]
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // 학년 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.grade > 0 ? '${course.grade}학년' : '공통',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (course.isMajorRequired)
                _SmallBadge('전필', Theme.of(context).colorScheme.error),
              if (course.hasTeamProject) ...[
                const SizedBox(width: 4),
                _SmallBadge('팀플', Colors.orange.shade700),
              ],
              const Spacer(),
              Text('${course.credit}학점',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(course.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('${course.professor} · ${course.timeSummary}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 8),
            Row(children: [
              // 별점
              ...List.generate(5, (i) => Icon(
                i < course.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: Colors.amber,
              )),
              const SizedBox(width: 4),
              Text(course.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 16),
              // 난이도
              Text('난이도', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 4),
              ...List.generate(5, (i) => Icon(
                Icons.circle,
                size: 8,
                color: i < course.difficulty
                    ? Colors.deepOrange
                    : Colors.grey.shade300,
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CourseDetailSheet(course: course),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _SmallBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      );
}

// ── 과목 상세 바텀시트 ─────────────────────────────────────────
class _CourseDetailSheet extends StatelessWidget {
  final Course course;
  const _CourseDetailSheet({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 과목명
          Text(course.name,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(course.professor,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline)),
          const SizedBox(height: 16),
          // 핵심 수치
          Row(children: [
            _InfoTile('학점', '${course.credit}학점', Icons.credit_card, theme),
            const SizedBox(width: 8),
            _InfoTile('학년', '${course.grade}학년', Icons.school, theme),
            const SizedBox(width: 8),
            _InfoTile('이수구분', course.isMajorRequired ? '전필' : '전선',
                Icons.check_circle_outline, theme),
          ]),
          const SizedBox(height: 12),
          // 평점 & 난이도
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [
                    Text('강의 평점', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(course.rating.toStringAsFixed(1),
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                      Text(' / 5.0', style: theme.textTheme.bodySmall),
                    ]),
                  ]),
                  Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                  Column(children: [
                    Text('강의 난이도', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Row(children: [
                      ...List.generate(5, (i) => Icon(
                        Icons.circle,
                        size: 14,
                        color: i < course.difficulty
                            ? Colors.deepOrange
                            : Colors.grey.shade300,
                      )),
                      const SizedBox(width: 6),
                      Text('${course.difficulty}/5',
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 강의 시간
          Text('강의 시간', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...course.timeSlots.map((s) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(s.day,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer)),
            ),
            title: Text('${s.startHour}:00 ~ ${s.endHour}:00',
                style: theme.textTheme.bodyMedium),
            subtitle: Text('${s.endHour - s.startHour}시간',
                style: theme.textTheme.bodySmall),
          )),
          const SizedBox(height: 12),
          // 팀플 여부
          if (course.hasTeamProject)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.group, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('팀 프로젝트가 포함된 강의입니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange.shade800)),
              ]),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;
  const _InfoTile(this.label, this.value, this.icon, this.theme);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.labelSmall),
          ]),
        ),
      );
}
