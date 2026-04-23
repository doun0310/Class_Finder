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
  final _repo = TimetableRepository();
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
    if (user != null) {
      _list = await _repo.listByUser(user.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(SavedTimetable t) async {
    await _repo.delete(t.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시간표가 삭제되었습니다')));
    }
  }

  Future<void> _rename(SavedTimetable t) async {
    final controller = TextEditingController(text: t.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '시간표 이름'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _repo.rename(t.id, result);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('저장된 시간표'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _EmptyView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final t = _list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SavedTimetableCard(
                          saved: t,
                          onOpen: () => _openDetail(t),
                          onRename: () => _rename(t),
                          onDelete: () => _confirmDelete(t),
                        ),
                      );
                    },
                  ),
                ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  void _openDetail(SavedTimetable t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SavedTimetableDetailScreen(saved: t),
      ),
    );
  }

  Future<void> _confirmDelete(SavedTimetable t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('삭제'),
        content: Text('"${t.name}" 시간표를 삭제하시겠어요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('취소')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true) _delete(t);
  }
}

// ── 저장 시간표 카드 ──────────────────────────────────────────────
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(saved.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'rename') onRename();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'rename',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('이름 변경'),
                      ])),
                  PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text('삭제',
                            style: TextStyle(color: theme.colorScheme.error)),
                      ])),
                ],
                icon: Icon(Icons.more_horiz,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 6),
            Text(_formatDate(saved.savedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(children: [
              _MetricChip(
                  icon: Icons.credit_card_outlined,
                  label: '${saved.totalCredits}학점'),
              const SizedBox(width: 6),
              _MetricChip(
                  icon: Icons.coffee_outlined,
                  label: '공강 ${saved.freeDays}일'),
              const SizedBox(width: 6),
              _MetricChip(
                icon: Icons.emoji_events_outlined,
                label: '${(saved.score * 100).toStringAsFixed(0)}점',
                highlight: true,
              ),
            ]),
            const SizedBox(height: 10),
            // 과목 수 표시
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: saved.courses.take(4).map((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(c.name,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500)),
              )).toList()
                ..addAll(saved.courses.length > 4
                    ? [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('+${saved.courses.length - 4}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      theme.colorScheme.onPrimaryContainer)),
                        )
                      ]
                    : []),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bookmark_outline,
            size: 64, color: theme.colorScheme.outline),
        const SizedBox(height: 12),
        Text('저장된 시간표가 없습니다',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 4),
        Text('시간표 매칭 결과에서 저장해보세요',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline)),
      ]),
    );
  }
}

// ── 저장 시간표 상세 화면 ─────────────────────────────────────────
class _SavedTimetableDetailScreen extends StatelessWidget {
  final SavedTimetable saved;
  const _SavedTimetableDetailScreen({required this.saved});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timetable = TimetableRepository.toTimetable(saved);
    return Scaffold(
      appBar: AppBar(title: Text(saved.name)),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _DetailStat('학점', '${saved.totalCredits}', Icons.credit_card),
            _DetailStat('공강', '${saved.freeDays}일', Icons.coffee),
            _DetailStat('점수', (saved.score * 100).toStringAsFixed(0),
                Icons.emoji_events,
                highlight: true),
            _DetailStat('과목', '${saved.courses.length}', Icons.menu_book),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: TimetableGrid(timetable: timetable),
          ),
        ),
      ]),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _DetailStat(this.label, this.value, this.icon,
      {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Column(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 4),
      Text(value,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      Text(label,
          style:
              theme.textTheme.labelSmall?.copyWith(color: color)),
    ]);
  }
}
