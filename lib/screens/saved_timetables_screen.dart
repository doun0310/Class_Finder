import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_timetable.dart';
import '../services/auth_service.dart';
import '../services/timetable_repository.dart';
import '../widgets/timetable_grid.dart';

class SavedTimetablesScreen extends StatefulWidget {
  const SavedTimetablesScreen({super.key});

  @override
  State<SavedTimetablesScreen> createState() => _SavedTimetablesScreenState();
}

class _SavedTimetablesScreenState extends State<SavedTimetablesScreen> {
  List<SavedTimetable> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().user;
    final repository = context.read<TimetableRepository>();

    try {
      if (user != null) {
        _list = await repository.listByUser(user);
      } else {
        _list = [];
      }
    } on TimetableRepositoryException catch (error) {
      _list = [];
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete(SavedTimetable timetable) async {
    final user = context.read<AuthService>().user;
    if (user == null) {
      return;
    }

    try {
      await context.read<TimetableRepository>().delete(
        user: user,
        id: timetable.id,
      );
      await _load();
      _showMessage('시간표를 삭제했습니다.');
    } on TimetableRepositoryException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _rename(SavedTimetable timetable) async {
    final controller = TextEditingController(text: timetable.name);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '시간표 이름'),
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
      ),
    );

    if (result == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final user = context.read<AuthService>().user;
    if (user == null) {
      return;
    }

    try {
      await context.read<TimetableRepository>().rename(
        user: user,
        id: timetable.id,
        newName: result,
      );
      await _load();
      _showMessage('시간표 이름을 변경했습니다.');
    } on TimetableRepositoryException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _confirmDelete(SavedTimetable timetable) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('삭제'),
        content: Text('"${timetable.name}" 시간표를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _delete(timetable);
    }
  }

  void _openDetail(SavedTimetable timetable) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SavedTimetableDetailScreen(saved: timetable),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('저장한 시간표'), centerTitle: false),
      backgroundColor: theme.colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
          ? const _EmptyView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _list.length,
                itemBuilder: (context, index) {
                  final timetable = _list[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SavedTimetableCard(
                      saved: timetable,
                      onOpen: () => _openDetail(timetable),
                      onRename: () => _rename(timetable),
                      onDelete: () => _confirmDelete(timetable),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _SavedTimetableCard extends StatelessWidget {
  final SavedTimetable saved;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _SavedTimetableCard({
    required this.saved,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      saved.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        onRename();
                      }
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('이름 변경'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '삭제',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_horiz,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(saved.savedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MetricChip(
                    icon: Icons.credit_card_outlined,
                    label: '${saved.totalCredits}학점',
                  ),
                  const SizedBox(width: 6),
                  _MetricChip(
                    icon: Icons.coffee_outlined,
                    label: '공강 ${saved.freeDays}일',
                  ),
                  const SizedBox(width: 6),
                  _MetricChip(
                    icon: Icons.emoji_events_outlined,
                    label: '${(saved.score * 100).toStringAsFixed(0)}점',
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...saved.courses.take(4).map(
                    (course) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (saved.courses.length > 4)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${saved.courses.length - 4}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
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

  String _formatDate(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);

    if (diff.inMinutes < 1) {
      return '방금 전';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}시간 전';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MetricChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            '저장한 시간표가 없습니다',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '시간표 결과 화면에서 저장해 두면 여기에서 다시 볼 수 있습니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SavedTimetableDetailScreen extends StatelessWidget {
  final SavedTimetable saved;

  const _SavedTimetableDetailScreen({required this.saved});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timetable = TimetableRepository.toTimetable(saved);

    return Scaffold(
      appBar: AppBar(title: Text(saved.name)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailStat('학점', '${saved.totalCredits}', Icons.credit_card),
                _DetailStat('공강', '${saved.freeDays}일', Icons.coffee),
                _DetailStat(
                  '점수',
                  (saved.score * 100).toStringAsFixed(0),
                  Icons.emoji_events,
                  highlight: true,
                ),
                _DetailStat('과목', '${saved.courses.length}', Icons.menu_book),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: TimetableGrid(timetable: timetable),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _DetailStat(
    this.label,
    this.value,
    this.icon, {
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}
