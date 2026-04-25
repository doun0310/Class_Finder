import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: const Text('프로필'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton.filledTonal(
                  onPressed: () => _showEditSheet(context, user),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '프로필 수정',
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                children: [
                  _ProfileHeroCard(
                    user: user,
                    onEdit: () => _showEditSheet(context, user),
                    onSaved: () => Navigator.pushNamed(context, '/saved'),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: '계정 정보',
                    subtitle: '추천과 저장 흐름에 연결되는 기본 프로필입니다.',
                    child: Column(
                      children: [
                        _DetailTile(
                          icon: Icons.person_outline_rounded,
                          label: '이름',
                          value: user.name,
                        ),
                        _DetailTile(
                          icon: Icons.mail_outline_rounded,
                          label: '이메일',
                          value: user.email,
                        ),
                        _DetailTile(
                          icon: Icons.badge_outlined,
                          label: '학번',
                          value: user.studentId,
                        ),
                        _DetailTile(
                          icon: Icons.school_outlined,
                          label: '학과 / 학년',
                          value: '${user.department} · ${user.grade}학년',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: '바로가기',
                    subtitle: '자주 확인하는 정보와 기능을 빠르게 열 수 있습니다.',
                    child: Column(
                      children: [
                        _ActionTile(
                          icon: Icons.bookmark_added_outlined,
                          title: '저장한 시간표',
                          subtitle: '보관 중인 추천 결과와 비교용 시간표를 확인합니다.',
                          onTap: () => Navigator.pushNamed(context, '/saved'),
                        ),
                        _ActionTile(
                          icon: Icons.info_outline_rounded,
                          title: '앱 버전',
                          subtitle: '현재 설치된 버전은 1.0.0 입니다.',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: '보안',
                    subtitle: '현재 기기 세션과 계정 연결 상태를 관리합니다.',
                    child: _DangerZone(
                      onSignOut: () => _confirmSignOut(context),
                    ),
                  ),
                ],
              ),
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
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text('이 기기에서 로그아웃', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '저장한 시간표와 프로필 정보는 유지되며, 다시 로그인하면 이어서 사용할 수 있습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _SignOutInfoRow(
                icon: Icons.shield_outlined,
                text: '현재 기기 세션만 종료됩니다.',
              ),
              _SignOutInfoRow(
                icon: Icons.bookmark_outline_rounded,
                text: '저장한 시간표와 추천 기록은 유지됩니다.',
              ),
              _SignOutInfoRow(
                icon: Icons.login_rounded,
                text: '언제든 다시 로그인해서 바로 이어갈 수 있습니다.',
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await context.read<AuthService>().signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (_) => false,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('로그아웃'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onSaved;

  const _ProfileHeroCard({
    required this.user,
    required this.onEdit,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer.withValues(alpha: 0.86),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;

              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroIdentity(user: user),
                        const SizedBox(height: 18),
                        _HeroActions(onEdit: onEdit, onSaved: onSaved),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _HeroIdentity(user: user)),
                        const SizedBox(width: 16),
                        _HeroActions(onEdit: onEdit, onSaved: onSaved),
                      ],
                    );
            },
          ),
          const SizedBox(height: 22),
          Text(
            '추천과 저장 흐름이 계정에 연결되어 있습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 880
                  ? 3
                  : width >= 560
                  ? 2
                  : 1;
              final cardWidth = (width - (12 * (columns - 1))) / columns;

              final items = [
                _HeroStat(
                  label: '학과 / 학년',
                  value: '${user.department} · ${user.grade}학년',
                ),
                _HeroStat(label: '학번', value: user.studentId),
                _HeroStat(
                  label: '가입 시점',
                  value: _formatJoinedAt(user.createdAt),
                ),
              ];

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: cardWidth,
                        child: _HeroStatCard(item: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroIdentity extends StatelessWidget {
  final User user;

  const _HeroIdentity({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Center(
            child: Text(
              user.initial,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    icon: Icons.school_outlined,
                    label: user.department,
                  ),
                  _HeroChip(
                    icon: Icons.auto_awesome_rounded,
                    label: '${user.grade}학년 개인화 프로필',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onSaved;

  const _HeroActions({required this.onEdit, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('정보 수정'),
        ),
        OutlinedButton.icon(
          onPressed: onSaved,
          icon: const Icon(Icons.bookmark_added_outlined, size: 18),
          label: const Text('저장 시간표'),
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});
}

class _HeroStatCard extends StatelessWidget {
  final _HeroStat item;

  const _HeroStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 20, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, size: 20, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
                ],
              ),
            ),
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DangerZone extends StatelessWidget {
  final VoidCallback onSignOut;

  const _DangerZone({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.onErrorContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.shield_moon_outlined,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '현재 기기 세션 종료',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '로그아웃하면 이 기기에서만 세션이 종료됩니다. 저장한 시간표와 추천 결과는 유지되며 다시 로그인해 이어서 사용할 수 있습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onErrorContainer.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _SecurityChip(label: '현재 기기 세션 종료'),
              _SecurityChip(label: '저장 데이터 유지'),
              _SecurityChip(label: '재로그인 즉시 복귀'),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onSignOut,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _SecurityChip extends StatelessWidget {
  final String label;

  const _SecurityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SignOutInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SignOutInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    '컴퓨터공학과',
    '소프트웨어학과',
    '전자공학과',
    '기계공학과',
    '경영학과',
    '경제학과',
    '기타',
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
    final messenger = ScaffoldMessenger.of(context);

    await auth.updateProfile(
      name: _name.text.trim(),
      studentId: _studentId.text.trim(),
      department: _department,
      grade: _grade,
    );

    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('프로필이 업데이트되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('프로필 수정', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '추천과 저장 흐름에 연결되는 기본 정보를 업데이트합니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            AppTextField(
              controller: _name,
              label: '이름',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _studentId,
              label: '학번',
              hint: '예: 20231234',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _department,
              decoration: const InputDecoration(
                labelText: '학과',
                prefixIcon: Icon(Icons.school_outlined, size: 20),
              ),
              items: _departments
                  .map(
                    (department) => DropdownMenuItem(
                      value: department,
                      child: Text(department),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _department = value ?? '기타'),
            ),
            const SizedBox(height: 16),
            Text('학년', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: [1, 2, 3, 4]
                  .map(
                    (grade) =>
                        ButtonSegment(value: grade, label: Text('$grade학년')),
                  )
                  .toList(),
              selected: {_grade},
              onSelectionChanged: (selection) {
                setState(() => _grade = selection.first);
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('변경사항 저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatJoinedAt(DateTime dateTime) {
  final year = dateTime.year.toString();
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$year.$month';
}
