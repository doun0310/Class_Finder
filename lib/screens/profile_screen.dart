import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            automaticallyImplyLeading: false,
            title: const Text('프로필'),
            backgroundColor: theme.colorScheme.surface,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(children: [
                // ── 아바타 카드 ────────────────────────────
                _ProfileAvatarCard(user: user),
                const SizedBox(height: 16),

                // ── 기본 정보 ──────────────────────────────
                _InfoSection(
                  title: '계정 정보',
                  tiles: [
                    _InfoTileData(
                      icon: Icons.person_outline,
                      label: '이름',
                      value: user.name,
                    ),
                    _InfoTileData(
                      icon: Icons.mail_outline,
                      label: '이메일',
                      value: user.email,
                    ),
                    _InfoTileData(
                      icon: Icons.badge_outlined,
                      label: '학번',
                      value: user.studentId,
                    ),
                    _InfoTileData(
                      icon: Icons.school_outlined,
                      label: '학과',
                      value: '${user.department} · ${user.grade}학년',
                    ),
                  ],
                  trailing: TextButton.icon(
                    onPressed: () => _showEditSheet(context, user),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('수정'),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 앱 설정 ────────────────────────────────
                _InfoSection(
                  title: '앱 설정',
                  tiles: [
                    _InfoTileData(
                      icon: Icons.bookmark_outline,
                      label: '저장된 시간표',
                      value: '보기',
                      onTap: () => Navigator.pushNamed(context, '/saved'),
                    ),
                    _InfoTileData(
                      icon: Icons.info_outline,
                      label: '앱 버전',
                      value: '1.0.0',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── 로그아웃 ───────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: Icon(Icons.logout,
                      size: 18, color: theme.colorScheme.error),
                  label: Text('로그아웃',
                      style: TextStyle(color: theme.colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('취소'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              Navigator.pop(dCtx);
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false);
              }
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

// ── 아바타 카드 ───────────────────────────────────────────────────
class _ProfileAvatarCard extends StatelessWidget {
  final User user;
  const _ProfileAvatarCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(user.initial,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(user.email,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(children: [
              _ProfileBadge(user.department, theme.colorScheme.primary),
              const SizedBox(width: 6),
              _ProfileBadge('${user.grade}학년', theme.colorScheme.secondary),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _ProfileBadge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700)),
      );
}

// ── 정보 섹션 ─────────────────────────────────────────────────────
class _InfoTileData {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _InfoTileData({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoTileData> tiles;
  final Widget? trailing;
  const _InfoSection({required this.title, required this.tiles, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          ?trailing,
        ]),
        const SizedBox(height: 4),
        ...tiles.asMap().entries.map((e) {
          final isLast = e.key == tiles.length - 1;
          final t = e.value;
          return Column(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              dense: true,
              leading: Icon(t.icon,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
              title: Text(t.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              subtitle: Text(t.value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              trailing: t.onTap != null
                  ? Icon(Icons.chevron_right,
                      color: theme.colorScheme.outline)
                  : null,
              onTap: t.onTap,
            ),
            if (!isLast)
              Divider(
                  height: 1, color: theme.colorScheme.outlineVariant),
          ]);
        }),
      ]),
    );
  }
}

// ── 프로필 수정 시트 ──────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final User user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _studentId;
  late String _department;
  late int _grade;

  static const _departments = [
    '컴퓨터공학', '소프트웨어', '전자공학', '기계공학', '경영학', '경제학', '기타',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _studentId = TextEditingController(text: widget.user.studentId);
    _department = widget.user.department;
    _grade = widget.user.grade;
  }

  @override
  void dispose() {
    _name.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthService>();
    await auth.updateProfile(
      name: _name.text.trim(),
      studentId: _studentId.text.trim(),
      department: _department,
      grade: _grade,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('프로필 수정',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '이름',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _studentId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '학번',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _department,
            decoration: const InputDecoration(
              labelText: '학과',
              prefixIcon: Icon(Icons.school_outlined, size: 20),
            ),
            items: _departments
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _department = v ?? '기타'),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text('학년', style: theme.textTheme.bodyMedium),
            const Spacer(),
            SegmentedButton<int>(
              segments: [1, 2, 3, 4]
                  .map((g) =>
                      ButtonSegment(value: g, label: Text('$g학년')))
                  .toList(),
              selected: {_grade},
              onSelectionChanged: (s) => setState(() => _grade = s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('취소'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: auth.isLoading ? null : _save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('저장'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
