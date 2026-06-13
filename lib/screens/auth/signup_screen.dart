import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/department_options.dart';
import '../../services/runtime_config.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_shell.dart';
import '../../widgets/department_picker_field.dart';
import '../../widgets/runtime_mode_notice.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _name = TextEditingController();
  final _studentId = TextEditingController();

  String _department = defaultDepartment;
  int _grade = 1;

  void _clearAuthError() {
    final auth = context.read<AuthService>();
    if (auth.lastError != null) {
      auth.clearError();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _name.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final ok = await auth.signUp(
      email: _email.text.trim(),
      password: _password.text,
      name: _name.text.trim(),
      studentId: _studentId.text.trim(),
      department: _department,
      grade: _grade,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final runtimeConfig = context.watch<RuntimeConfig>();

    return AuthShell(
      badge: '회원가입',
      title: '새 계정을 만들어 주세요',
      subtitle: '기본 정보를 입력하면 시간표 저장과 계정 관리를 바로 시작할 수 있습니다.',
      heroTitle: '학기 동안 계속 쓰는\n내 시간표 계정',
      heroSubtitle: '학과, 학년, 학번 정보를 등록해 두면 저장한 시간표와 계정 정보를 한곳에서 관리할 수 있습니다.',
      icon: Icons.person_add_alt_1_rounded,
      features: const [
        AuthFeatureItem(
          icon: Icons.tune_rounded,
          title: '기본 정보 등록',
          description: '학과와 학년 정보를 입력해 계정 구성을 마칩니다.',
        ),
        AuthFeatureItem(
          icon: Icons.sync_rounded,
          title: '저장 내용 함께 관리',
          description: '저장한 시간표와 계정 정보를 같은 계정으로 유지합니다.',
        ),
        AuthFeatureItem(
          icon: Icons.devices_rounded,
          title: '기기 변경에도 유지',
          description: '다른 기기에서 로그인해도 같은 정보로 이어서 사용할 수 있습니다.',
        ),
      ],
      metrics: const [
        AuthMetricItem(value: '학과/학년', label: '기본 정보'),
        AuthMetricItem(value: '1회 입력', label: '초기 설정'),
        AuthMetricItem(value: '계정 기반', label: '저장 내용 관리'),
      ],
      footer: Text(
        '가입을 완료하면 바로 홈으로 이동하고, 이후 저장 기능과 계정 관리를 계속 사용할 수 있습니다.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.assignment_ind_rounded,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '기본 정보 등록',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '입력한 정보는 계정 생성과 저장 정보 구분에 사용됩니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RuntimeModeNotice(config: runtimeConfig),
            if (auth.lastError != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  auth.lastError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('계정 정보', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            AppTextField(
              controller: _email,
              label: '이메일',
              hint: 'name@example.com',
              icon: Icons.mail_outline_rounded,
              isEmail: true,
              onChanged: (_) => _clearAuthError(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해 주세요';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                  return '올바른 이메일 형식이 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _password,
              label: '비밀번호',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              onChanged: (_) => _clearAuthError(),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return '비밀번호를 6자 이상 입력해 주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordConfirm,
              label: '비밀번호 확인',
              icon: Icons.lock_reset_rounded,
              isPassword: true,
              onChanged: (_) => _clearAuthError(),
              validator: (value) {
                if (value != _password.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('프로필 정보', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            AppTextField(
              controller: _name,
              label: '이름',
              icon: Icons.person_outline_rounded,
              onChanged: (_) => _clearAuthError(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해 주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _studentId,
              label: '학번',
              hint: '예: 20231234',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _clearAuthError(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '학번을 입력해 주세요';
                }
                if (value.length < 6) {
                  return '학번은 6자리 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DepartmentPickerField(
              value: _department,
              onChanged: (value) {
                _clearAuthError();
                setState(() => _department = value);
              },
            ),
            const SizedBox(height: 16),
            Text('학년', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: [1, 2, 3, 4]
                    .map(
                      (grade) =>
                          ButtonSegment(value: grade, label: Text('$grade학년')),
                    )
                    .toList(),
                selected: {_grade},
                onSelectionChanged: (selection) {
                  _clearAuthError();
                  setState(() => _grade = selection.first);
                },
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isLoading ? null : _signUp,
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
                        Text('가입하고 시작하기'),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: auth.isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: const Text('로그인 화면으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
