import 'dart:async';

import 'package:class_finder/models/course.dart';
import 'package:class_finder/models/saved_timetable.dart';
import 'package:class_finder/models/user.dart';
import 'package:class_finder/models/user_preference.dart';
import 'package:class_finder/screens/result_screen.dart';
import 'package:class_finder/services/app_state.dart';
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

  testWidgets('result screen blocks duplicate timetable saves', (tester) async {
    final user = _sampleUser();
    final authService = AuthService(
      _SeededAuthRepository(user: user),
      socialAuth: _FakeSocialAuthService(),
    );
    await authService.loadSession();

    final timetable = _sampleTimetable();
    final repository = _BlockingTimetableRepository(user: user);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authService),
          ChangeNotifierProvider<AppState>(
            create: (_) => _SeededAppState(timetable),
          ),
          Provider<TimetableRepository>.value(value: repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          routes: {
            '/saved': (_) => const Scaffold(body: Text('saved timetables')),
          },
          home: const ResultScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const ValueKey('save-timetable-button'));
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('시간표 저장'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(repository.saveCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pump();

    expect(repository.saveCalls, 1);

    repository.completeSave(timetable);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('시간표를 저장했습니다.'), findsOneWidget);
    expect(repository.saveCalls, 1);
  });
}

class _SeededAppState extends AppState {
  final Timetable timetable;

  _SeededAppState(this.timetable);

  @override
  UserPreference get pref =>
      const UserPreference(major: '컴퓨터공학부', grade: 2, maxCredits: 18);

  @override
  List<Timetable> get results => [timetable];

  @override
  int get selectedResultIndex => 0;

  @override
  Timetable? get selectedTimetable => timetable;

  @override
  void selectResult(int index) {}
}

class _BlockingTimetableRepository extends TimetableRepository {
  final User user;
  int saveCalls = 0;
  Completer<SavedTimetable>? _saveCompleter;

  _BlockingTimetableRepository({required this.user});

  @override
  Future<List<SavedTimetable>> listByUser(User user) async => [];

  @override
  Future<SavedTimetable> save({
    required User user,
    required String name,
    required Timetable timetable,
  }) {
    saveCalls += 1;
    _saveCompleter = Completer<SavedTimetable>();
    return _saveCompleter!.future;
  }

  void completeSave(Timetable timetable) {
    _saveCompleter!.complete(
      SavedTimetable(
        id: 'saved-1',
        userId: user.id,
        name: '시간표',
        courses: timetable.courses,
        score: timetable.score,
        scoreBreakdown: timetable.scoreBreakdown,
        savedAt: DateTime(2026, 6, 9),
      ),
    );
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
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signInWithProvider(
    AuthProvider provider, {
    SocialAuthPayload? payload,
  }) {
    throw UnimplementedError();
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
    throw UnimplementedError();
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

Timetable _sampleTimetable() {
  return Timetable(
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
    score: 0.91,
    scoreBreakdown: const {
      'hard': 1,
      'conflict': 1,
      'bounds': 1,
      'freeDay': 1,
      'creditLimit': 1,
      'soft': 0.91,
      'compactness': 0.8,
      'creditFit': 0.9,
      'lunch': 1,
    },
  );
}
