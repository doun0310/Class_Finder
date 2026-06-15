import 'dart:convert';

import 'package:class_finder/models/course.dart';
import 'package:class_finder/models/user.dart';
import 'package:class_finder/services/api_client.dart';
import 'package:class_finder/services/genetic_algorithm.dart';
import 'package:class_finder/services/timetable_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalTimetableRepository', () {
    test('saves, lists, renames, and deletes timetables per user', () async {
      const repository = LocalTimetableRepository();
      final user = _sampleUser();
      final otherUser = _sampleUser(
        id: 'user-2',
        email: 'other@example.com',
        name: 'Other User',
      );

      final first = await repository.save(
        user: user,
        name: '  ',
        timetable: _sampleTimetable(
          courseId: 'CSE101-001',
          courseName: 'Programming Basics',
        ),
      );
      final second = await repository.save(
        user: user,
        name: 'Evening Plan',
        timetable: _sampleTimetable(
          courseId: 'CSE201-001',
          courseName: 'Data Structures',
          day: '수',
        ),
      );
      await repository.save(
        user: otherUser,
        name: 'Other User Plan',
        timetable: _sampleTimetable(
          courseId: 'LIB101-001',
          courseName: 'Writing',
          day: '금',
        ),
      );

      final listed = await repository.listByUser(user);
      expect(listed, hasLength(2));
      expect(listed.first.id, second.id);
      expect(listed.first.name, 'Evening Plan');
      expect(listed.last.id, first.id);
      expect(listed.last.name, 'Saved Timetable');

      await repository.rename(user: user, id: second.id, newName: '   ');
      final renamed = await repository.listByUser(user);
      expect(renamed.first.name, 'Saved Timetable');

      await repository.delete(user: user, id: first.id);
      final afterDelete = await repository.listByUser(user);
      expect(afterDelete, hasLength(1));
      expect(afterDelete.single.id, second.id);
    });
  });

  group('RemoteTimetableRepository', () {
    test('lists timetables with the stored bearer token', () async {
      SharedPreferences.setMockInitialValues({'auth.token': 'server-token'});
      final user = _sampleUser();
      final client = ApiClient(
        baseUrl: 'http://example.com',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.toString(),
            'http://example.com/users/${user.id}/timetables',
          );
          expect(
            request.headers['authorization'] ??
                request.headers['Authorization'],
            'Bearer server-token',
          );
          return http.Response(
            jsonEncode({
              'timetables': [
                {
                  'id': 'saved-1',
                  'userId': user.id,
                  'name': 'Server Plan',
                  'score': 91.4,
                  'scoreBreakdown': {'soft': 0.91},
                  'savedAt': DateTime.utc(2026, 5, 31).toIso8601String(),
                  'courses': [_sampleCourse().toJson()],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final repository = RemoteTimetableRepository(client: client);

      final listed = await repository.listByUser(user);

      expect(listed, hasLength(1));
      expect(listed.single.name, 'Server Plan');
      expect(listed.single.courses.single.name, 'Algorithms');
      repository.dispose();
    });

    test(
      'saves, renames, and deletes timetables through the backend API',
      () async {
        SharedPreferences.setMockInitialValues({'auth.token': 'server-token'});
        final user = _sampleUser();
        final calls = <String>[];
        final client = ApiClient(
          baseUrl: 'http://example.com',
          client: MockClient((request) async {
            calls.add('${request.method} ${request.url.path}');
            expect(
              request.headers['authorization'] ??
                  request.headers['Authorization'],
              'Bearer server-token',
            );

            if (request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['name'], 'Morning Plan');
              expect(body['courses'], isA<List>());
              expect((body['courses'] as List).single['id'], 'CSE301-001');
              return http.Response(
                jsonEncode({
                  'timetable': {
                    'id': 'saved-remote-1',
                    'userId': user.id,
                    'name': 'Morning Plan',
                    'score': 88.2,
                    'scoreBreakdown': {'soft': 0.88},
                    'savedAt': DateTime.utc(2026, 5, 31, 9).toIso8601String(),
                    'courses': [_sampleCourse(id: 'CSE301-001').toJson()],
                  },
                }),
                201,
                headers: {'content-type': 'application/json'},
              );
            }

            if (request.method == 'PATCH') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              expect(body['name'], 'Renamed Plan');
              return http.Response(
                jsonEncode({
                  'timetable': {
                    'id': 'saved-remote-1',
                    'userId': user.id,
                    'name': 'Renamed Plan',
                    'score': 88.2,
                    'scoreBreakdown': {'soft': 0.88},
                    'savedAt': DateTime.utc(2026, 5, 31, 9).toIso8601String(),
                    'courses': [_sampleCourse(id: 'CSE301-001').toJson()],
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response('', 200);
          }),
        );
        final repository = RemoteTimetableRepository(client: client);

        final saved = await repository.save(
          user: user,
          name: 'Morning Plan',
          timetable: _sampleTimetable(courseId: 'CSE301-001'),
        );
        expect(saved.id, 'saved-remote-1');
        expect(saved.name, 'Morning Plan');

        await repository.rename(
          user: user,
          id: saved.id,
          newName: 'Renamed Plan',
        );
        await repository.delete(user: user, id: saved.id);

        expect(
          calls,
          containsAllInOrder([
            'POST /users/${user.id}/timetables',
            'PATCH /users/${user.id}/timetables/${saved.id}',
            'DELETE /users/${user.id}/timetables/${saved.id}',
          ]),
        );
        repository.dispose();
      },
    );

    test(
      'surfaces a readable message when the backend is unreachable',
      () async {
        SharedPreferences.setMockInitialValues({'auth.token': 'server-token'});
        final repository = RemoteTimetableRepository(
          client: ApiClient(
            baseUrl: 'http://example.com',
            client: MockClient((_) async {
              throw http.ClientException('offline');
            }),
          ),
        );

        await expectLater(
          repository.listByUser(_sampleUser()),
          throwsA(
            isA<TimetableRepositoryException>().having(
              (error) => error.message,
              'message',
              '서버에 연결할 수 없습니다. 백엔드 실행 상태와 네트워크를 확인해 주세요.',
            ),
          ),
        );
        repository.dispose();
      },
    );
  });
}

User _sampleUser({
  String id = 'user-1',
  String email = 'student@example.com',
  String name = 'Student Kim',
}) {
  return User(
    id: id,
    email: email,
    name: name,
    studentId: '20230001',
    department: '컴퓨터공학부',
    grade: 2,
    createdAt: DateTime.utc(2026, 5, 31),
  );
}

Course _sampleCourse({
  String id = 'CSE401-001',
  String courseName = 'Algorithms',
  String day = '월',
}) {
  return Course(
    id: id,
    name: courseName,
    professor: 'Prof. Kim',
    credit: 3,
    rating: 4.3,
    difficulty: 3,
    hasTeamProject: false,
    isMajorRequired: false,
    category: CourseCategory.majorElective,
    ratingSource: RatingSource.officialEstimate,
    grade: 3,
    timeSlots: [TimeSlot(day: day, startHour: 9, endHour: 11)],
  );
}

Timetable _sampleTimetable({
  String courseId = 'CSE401-001',
  String courseName = 'Algorithms',
  String day = '월',
}) {
  return Timetable(
    courses: [_sampleCourse(id: courseId, courseName: courseName, day: day)],
    score: 0.882,
    scoreBreakdown: const {'soft': 0.882, 'hard': 1.0},
  );
}
