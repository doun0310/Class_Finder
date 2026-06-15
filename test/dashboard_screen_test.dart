import 'package:class_finder/models/course.dart';
import 'package:class_finder/models/saved_timetable.dart';
import 'package:class_finder/models/user.dart';
import 'package:class_finder/screens/dashboard_screen.dart';
import 'package:class_finder/services/auth_repository.dart';
import 'package:class_finder/services/auth_service.dart';
import 'package:class_finder/services/genetic_algorithm.dart';
import 'package:class_finder/services/social_auth_service.dart';
import 'package:class_finder/services/timetable_repository.dart';
import 'package:class_finder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth.token': 'token'});
  });

  testWidgets('dashboard status action opens actionable status sheet', (
    tester,
  ) async {
    final user = _sampleUser();
    final authService = AuthService(
      _SeededAuthRepository(user: user),
      socialAuth: _FakeSocialAuthService(),
    );
    await authService.loadSession();

    await tester.pumpWidget(
      _DashboardHarness(
        authService: authService,
        repository: _FakeTimetableRepository(saved: [_sampleSaved(user)]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('진행 상태'));
    await tester.pumpAndSettle();

    expect(find.text('진행 상태'), findsOneWidget);
    expect(find.text('프로필 준비 완료'), findsOneWidget);
    expect(find.text('저장한 시간표 1개'), findsOneWidget);
    expect(find.textContaining('월수 공강 시간표'), findsOneWidget);
  });

  testWidgets('dashboard and status sheet stay stable on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final user = _sampleUser();
    final authService = AuthService(
      _SeededAuthRepository(user: user),
      socialAuth: _FakeSocialAuthService(),
    );
    await authService.loadSession();

    await tester.pumpWidget(
      _DashboardHarness(
        authService: authService,
        repository: _FakeTimetableRepository(saved: [_sampleSaved(user)]),
        textScale: 1.2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('진행 상태'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _DashboardHarness extends StatelessWidget {
  final AuthService authService;
  final TimetableRepository repository;
  final double textScale;

  const _DashboardHarness({
    required this.authService,
    required this.repository,
    this.textScale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        Provider<TimetableRepository>.value(value: repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        routes: {
          '/saved': (_) => const Scaffold(body: Text('saved timetables')),
        },
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQueryData.fromView(
                View.of(context),
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const DashboardScreen(),
            );
          },
        ),
      ),
    );
  }
}

class _FakeTimetableRepository extends TimetableRepository {
  final List<SavedTimetable> saved;

  const _FakeTimetableRepository({required this.saved});

  @override
  Future<List<SavedTimetable>> listByUser(User user) async => saved;

  @override
  Future<SavedTimetable> save({
    required User user,
    required String name,
    required Timetable timetable,
  }) async {
    throw StateError('Unexpected save in dashboard test');
  }

  @override
  Future<void> delete({required User user, required String id}) async {}

  @override
  Future<void> rename({
    required User user,
    required String id,
    required String newName,
  }) async {}
}

class _SeededAuthRepository implements AuthRepository {
  final User user;

  const _SeededAuthRepository({required this.user});

  @override
  Future<User?> getCurrentUser() async => user;

  @override
  Future<String> requestPasswordReset({required String email}) {
    throw StateError('Unexpected password reset in dashboard test');
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) {
    throw StateError('Unexpected sign in in dashboard test');
  }

  @override
  Future<AuthResult> signInWithProvider(
    AuthProvider provider, {
    SocialAuthPayload? payload,
  }) {
    throw StateError('Unexpected social sign in in dashboard test');
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String department,
    required int grade,
  }) {
    throw StateError('Unexpected sign up in dashboard test');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<User> updateProfile(User user) async => user;
}

class _FakeSocialAuthService implements SocialAuthGateway {
  @override
  Future<SocialAuthPayload> authenticate(AuthProvider provider) async {
    return SocialAuthPayload(provider: provider);
  }
}

User _sampleUser() {
  return User(
    id: 'user-1',
    email: 'student@example.com',
    name: '학생',
    studentId: '20230001',
    department: '컴퓨터공학부',
    grade: 2,
    createdAt: DateTime(2026, 1, 1),
  );
}

SavedTimetable _sampleSaved(User user) {
  return SavedTimetable(
    id: 'saved-1',
    userId: user.id,
    name: '월수 공강 시간표',
    courses: const [
      Course(
        id: 'CSE201-001',
        name: '자료구조',
        professor: '김교수',
        credit: 3,
        rating: 4.3,
        difficulty: 3,
        hasTeamProject: false,
        isMajorRequired: true,
        category: CourseCategory.majorRequired,
        ratingSource: RatingSource.officialEstimate,
        grade: 2,
        timeSlots: [TimeSlot(day: '월', startHour: 9, endHour: 12)],
      ),
    ],
    score: 0.92,
    scoreBreakdown: const {'hard': 1, 'conflict': 1, 'freeDay': 0.8},
    savedAt: DateTime(2026, 6, 9, 13, 20),
  );
}
