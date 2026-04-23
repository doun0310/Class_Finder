import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_text_field.dart';

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
  String _department = '컴퓨터공학';
  int _grade = 1;

  static const _departments = [
    '컴퓨터공학',
    '소프트웨어',
    '전자공학',
    '기계공학',
    '경영학',
    '경제학',
    '기타',
  ];

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.lastError ?? '회원가입에 실패했습니다.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('계정 정보',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppTextField(
                controller: _email,
                label: '이메일',
                hint: 'name@example.com',
                icon: Icons.mail_outline,
                isEmail: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return '이메일을 입력해주세요';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(v)) {
                    return '올바른 이메일 형식이 아닙니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: _password,
                label: '비밀번호 (6자 이상)',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.length < 6) return '6자 이상 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: _passwordConfirm,
                label: '비밀번호 확인',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (v) {
                  if (v != _password.text) return '비밀번호가 일치하지 않습니다';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text('프로필 정보',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AppTextField(
                controller: _name,
                label: '이름',
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '이름을 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: _studentId,
                label: '학번',
                hint: '예: 20231234',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '학번을 입력해주세요';
                  if (v.length < 6) return '학번은 6자리 이상입니다';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              // 학과 선택
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
                  style: const ButtonStyle(
                      visualDensity: VisualDensity.compact),
                ),
              ]),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: auth.isLoading ? null : _signUp,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('가입하고 시작하기'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
