import 'package:flutter/material.dart';

import '../services/department_options.dart';

class DepartmentPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const DepartmentPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '학과',
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DepartmentPickerSheet(initialValue: value),
    );

    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = normalizeDepartment(value);
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '$label 선택',
      value: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPicker(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.school_outlined, size: 20),
            suffixIcon: const Icon(Icons.expand_more_rounded),
          ),
          child: Text(
            selected,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _DepartmentPickerSheet extends StatefulWidget {
  final String initialValue;

  const _DepartmentPickerSheet({required this.initialValue});

  @override
  State<_DepartmentPickerSheet> createState() => _DepartmentPickerSheetState();
}

class _DepartmentPickerSheetState extends State<_DepartmentPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = _search.text.trim();
    final filtered = query.isEmpty
        ? departmentOptions
        : departmentOptions
              .where((department) => department.contains(query))
              .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('학과 선택', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '경상국립대학교 전공 시간표 기준 ${departmentOptions.length}개 학과',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '학과명 검색',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final department = filtered[index];
                        final selected = department == widget.initialValue;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(department),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: scheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, department),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
