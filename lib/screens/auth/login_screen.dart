import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  void _clearAuthError() {
    final auth = context.read<AuthService>();
    if (auth.lastError != null) {
      auth.clearError();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  Future<void> _signInWithProvider(AuthProvider provider) async {
    final auth = context.read<AuthService>();
    final ok = await auth.signInWithProvider(provider);

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  void _openPasswordReset() {
    context.read<AuthService>().clearError();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => PasswordResetSheet(initialEmail: _emailCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final errorState = _LoginErrorState.from(
      theme: theme,
      code: auth.lastErrorCode,
      message: auth.lastError,
    );

    return AuthShell(
      badge: 'Campus Account',
      title: '저장한 시간표로 바로 돌아가기',
      subtitle: '추천 기록과 선호 조건을 불러와서 다음 시간표 생성까지 바로 이어갑니다.',
      heroTitle: '수강신청 직전까지 이어지는\n개인화 추천 경험',
      heroSubtitle:
          '학기별 선호 시간, 공강 요일, 저장한 시간표를 한 계정에서 관리하고 필요한 순간 바로 다시 불러올 수 있습니다.',
      icon: Icons.lock_person_rounded,
      features: const [
        AuthFeatureItem(
          icon: Icons.schedule_send_rounded,
          title: '선호 조건 즉시 복원',
          description: '시작 시간, 종료 시간, 공강, 최소 학점 설정을 그대로 이어받습니다.',
        ),
        AuthFeatureItem(
          icon: Icons.bookmark_added_rounded,
          title: '추천 결과 안전 보관',
          description: '마음에 든 시간표와 비교 대상 결과를 학기별로 다시 확인할 수 있습니다.',
        ),
        AuthFeatureItem(
          icon: Icons.verified_user_rounded,
          title: '계정 기반 사용 흐름',
          description: '기기 교체나 재설치 이후에도 이전 상태를 빠르게 이어갈 수 있습니다.',
        ),
      ],
      metrics: const [
        AuthMetricItem(value: '즉시', label: '추천 이력 복원'),
        AuthMetricItem(value: '1계정', label: '선호 조건 통합 관리'),
        AuthMetricItem(value: '학기별', label: '저장 시간표 히스토리'),
      ],
      footer: Text(
        '계정을 만들면 추천 기록과 저장한 시간표를 더 안정적으로 관리할 수 있습니다.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBanner(
              icon: Icons.shield_outlined,
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              title: '보안 연결 사용 중',
              description: '계정에 연결된 추천 조건과 저장 시간표를 안전하게 불러옵니다.',
            ),
            if (errorState != null) ...[
              const SizedBox(height: 14),
              _InfoBanner(
                icon: errorState.icon,
                backgroundColor: errorState.backgroundColor,
                foregroundColor: errorState.foregroundColor,
                title: errorState.title,
                description: errorState.description,
              ),
            ],
            const SizedBox(height: 22),
            AppTextField(
              controller: _emailCtrl,
              label: '이메일',
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              isEmail: true,
              onChanged: (_) => _clearAuthError(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해주세요';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                  return '올바른 이메일 형식이 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordCtrl,
              label: '비밀번호',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              onChanged: (_) => _clearAuthError(),
              textInputAction: TextInputAction.done,
              onEditingComplete: _signIn,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: auth.isLoading ? null : _openPasswordReset,
                icon: const Icon(Icons.lock_reset_rounded, size: 18),
                label: const Text('비밀번호 재설정'),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '로그인 후 저장 시간표, 선호 조건, 추천 결과를 한 번에 이어서 확인할 수 있습니다.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: auth.isLoading ? null : _signIn,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text('로그인'),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '또는',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SocialButton(
              provider: AuthProvider.google,
              onPressed: auth.isLoading
                  ? null
                  : () => _signInWithProvider(AuthProvider.google),
            ),
            const SizedBox(height: 10),
            _SocialButton(
              provider: AuthProvider.kakao,
              onPressed: auth.isLoading
                  ? null
                  : () => _signInWithProvider(AuthProvider.kakao),
            ),
            const SizedBox(height: 10),
            _SocialButton(
              provider: AuthProvider.apple,
              onPressed: auth.isLoading
                  ? null
                  : () => _signInWithProvider(AuthProvider.apple),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: auth.isLoading
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, size: 18),
                  Text('새 계정 만들기'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetSheet extends StatefulWidget {
  final String initialEmail;

  const PasswordResetSheet({super.key, this.initialEmail = ''});

  @override
  State<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<PasswordResetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  String? _successMessage;

  void _clearAuthError() {
    final auth = context.read<AuthService>();
    if (auth.lastError != null) {
      auth.clearError();
    }
  }

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final message = await context.read<AuthService>().requestPasswordReset(
      email: _emailCtrl.text.trim(),
    );

    if (!mounted) return;
    if (message != null) {
      setState(() => _successMessage = message);
    }
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text('비밀번호 재설정', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '가입한 이메일을 입력하면 비밀번호 재설정 안내를 보냅니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            if (_successMessage != null)
              _InfoBanner(
                icon: Icons.check_circle_outline_rounded,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                title: '안내를 전송했습니다',
                description: _successMessage!,
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (auth.lastError != null) ...[
                      _InfoBanner(
                        icon: Icons.error_outline_rounded,
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                        title: '재설정 요청을 완료하지 못했습니다',
                        description: auth.lastError!,
                      ),
                      const SizedBox(height: 14),
                    ],
                    AppTextField(
                      controller: _emailCtrl,
                      label: '이메일',
                      hint: 'name@example.com',
                      icon: Icons.mail_outline_rounded,
                      isEmail: true,
                      onChanged: (_) => _clearAuthError(),
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _submit,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+',
                        ).hasMatch(value)) {
                          return '올바른 이메일 형식이 아닙니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '보안상 계정 존재 여부와 관계없이 동일한 안내 문구를 표시합니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final cancelButton = OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: Text(_successMessage == null ? '취소' : '닫기'),
                );
                final submitButton = FilledButton(
                  onPressed: auth.isLoading ? null : _submit,
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
                      : const Text('재설정 안내 보내기'),
                );

                if (_successMessage != null) {
                  return SizedBox(width: double.infinity, child: cancelButton);
                }

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      submitButton,
                      const SizedBox(height: 12),
                      cancelButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 12),
                    Expanded(child: submitButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final AuthProvider provider;
  final VoidCallback? onPressed;

  const _SocialButton({required this.provider, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _SocialVisuals.from(provider, theme);
    final badge = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: visual.badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          visual.badgeText,
          style: theme.textTheme.titleSmall?.copyWith(
            color: visual.foregroundColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 320;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    badge,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${provider.label}로 계속하기',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 46),
                  child: Text(
                    visual.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              badge,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${provider.label}로 계속하기',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                visual.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String title;
  final String description;

  const _InfoBanner({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: foregroundColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: foregroundColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foregroundColor.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginErrorState {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String title;
  final String description;

  const _LoginErrorState({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.title,
    required this.description,
  });

  static _LoginErrorState? from({
    required ThemeData theme,
    required AuthErrorCode? code,
    required String? message,
  }) {
    if (message == null) return null;

    final scheme = theme.colorScheme;

    switch (code) {
      case AuthErrorCode.userNotFound:
        return _LoginErrorState(
          icon: Icons.person_search_rounded,
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
          title: '가입되지 않은 이메일입니다',
          description: '입력한 주소로는 계정을 찾지 못했습니다. 이메일을 다시 확인하거나 새 계정을 만들어주세요.',
        );
      case AuthErrorCode.wrongPassword:
        return _LoginErrorState(
          icon: Icons.lock_reset_rounded,
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
          title: '비밀번호가 일치하지 않습니다',
          description: message,
        );
      case AuthErrorCode.tooManyAttempts:
        return _LoginErrorState(
          icon: Icons.timer_outlined,
          backgroundColor: scheme.tertiaryContainer,
          foregroundColor: scheme.onTertiaryContainer,
          title: '잠시 후 다시 시도해주세요',
          description: message,
        );
      case AuthErrorCode.network:
        return _LoginErrorState(
          icon: Icons.wifi_off_rounded,
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          title: '연결 상태를 확인해주세요',
          description: '네트워크 상태가 불안정합니다. 연결을 확인한 뒤 다시 시도해주세요.',
        );
      case AuthErrorCode.socialUnavailable:
        return _LoginErrorState(
          icon: Icons.link_off_rounded,
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          title: '소셜 로그인을 사용할 수 없습니다',
          description: message,
        );
      case AuthErrorCode.emailAlreadyInUse:
      case AuthErrorCode.weakPassword:
      case AuthErrorCode.unknown:
      case null:
        return _LoginErrorState(
          icon: Icons.error_outline_rounded,
          backgroundColor: scheme.errorContainer,
          foregroundColor: scheme.onErrorContainer,
          title: '로그인을 완료하지 못했습니다',
          description: message,
        );
    }
  }
}

class _SocialVisuals {
  final String badgeText;
  final String caption;
  final Color badgeColor;
  final Color foregroundColor;

  const _SocialVisuals({
    required this.badgeText,
    required this.caption,
    required this.badgeColor,
    required this.foregroundColor,
  });

  factory _SocialVisuals.from(AuthProvider provider, ThemeData theme) {
    return switch (provider) {
      AuthProvider.google => const _SocialVisuals(
        badgeText: 'G',
        caption: '추천 복원',
        badgeColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      AuthProvider.kakao => const _SocialVisuals(
        badgeText: 'K',
        caption: '간편 시작',
        badgeColor: Color(0xFFFEE500),
        foregroundColor: Color(0xFF111827),
      ),
      AuthProvider.apple => _SocialVisuals(
        badgeText: 'A',
        caption: '빠른 로그인',
        badgeColor: theme.brightness == Brightness.light
            ? const Color(0xFF111827)
            : Colors.white,
        foregroundColor: theme.brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF111827),
      ),
    };
  }
}
