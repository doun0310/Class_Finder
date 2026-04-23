import 'dart:math';
import '../models/course.dart';
import '../models/user_preference.dart';

class Timetable {
  final List<Course> courses;
  final double score;
  final Map<String, double> scoreBreakdown;

  const Timetable({required this.courses, required this.score, this.scoreBreakdown = const {}});

  int get totalCredits => courses.fold(0, (s, c) => s + c.credit);

  bool get hasTimeConflict {
    final slots = courses.expand((c) => c.timeSlots).toList();
    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        if (slots[i].conflictsWith(slots[j])) return true;
      }
    }
    return false;
  }

  int get freeDays {
    const days = ['월', '화', '수', '목', '금'];
    return days.where((d) => courses.every((c) => c.timeSlots.every((s) => s.day != d))).length;
  }

  int get consecutiveMax {
    const days = ['월', '화', '수', '목', '금'];
    int max = 0;
    for (final day in days) {
      final hours = courses
          .expand((c) => c.timeSlots)
          .where((s) => s.day == day)
          .expand((s) => List.generate(s.endHour - s.startHour, (i) => s.startHour + i))
          .toSet()
          .toList()
        ..sort();
      int streak = 0, best = 0;
      for (int i = 0; i < hours.length; i++) {
        streak = (i > 0 && hours[i] == hours[i - 1] + 1) ? streak + 1 : 1;
        if (streak > best) best = streak;
      }
      if (best > max) max = best;
    }
    return max;
  }
}

class GeneticAlgorithmService {
  static const int _popSize = 150;
  static const int _generations = 80;
  static const double _mutationRate = 0.12;
  final Random _rng = Random();

  List<Timetable> run(List<Course> allCourses, UserPreference pref) {
    // 학년 필터: 사용자 학년 이하 과목만 사용
    final eligible = allCourses.where((c) => c.grade == 0 || c.grade <= pref.grade).toList();
    final required = eligible.where((c) => pref.requiredCourseIds.contains(c.id)).toList();
    final electives = eligible.where((c) => !pref.requiredCourseIds.contains(c.id)).toList();

    var population = _initPopulation(required, electives, pref);
    for (int g = 0; g < _generations; g++) {
      population.sort((a, b) => b.score.compareTo(a.score));
      // 엘리트 보존 + 새 세대 생성
      final next = population.take(15).toList();
      while (next.length < _popSize) {
        final p1 = _tournamentSelect(population);
        final p2 = _tournamentSelect(population);
        var child = _crossover(p1, p2, required, electives, pref);
        child = _mutate(child, electives, pref);
        next.add(child);
      }
      population = next;
    }
    population.sort((a, b) => b.score.compareTo(a.score));
    // 중복 제거 (같은 과목 조합 제외)
    final seen = <String>{};
    final unique = <Timetable>[];
    for (final t in population) {
      final key = (t.courses.map((c) => c.id).toList()..sort()).join(',');
      if (seen.add(key)) unique.add(t);
      if (unique.length == 5) break;
    }
    return unique;
  }

  List<Timetable> _initPopulation(List<Course> required, List<Course> electives, UserPreference pref) {
    return List.generate(_popSize, (_) {
      final shuffled = [...electives]..shuffle(_rng);
      final selected = [...required];
      for (final c in shuffled) {
        if (_totalCredits(selected) + c.credit > pref.maxCredits) continue;
        if (!_hasConflict([...selected, c])) selected.add(c);
      }
      return _evaluate(selected, pref);
    });
  }

  int _totalCredits(List<Course> courses) => courses.fold(0, (s, c) => s + c.credit);

  bool _hasConflict(List<Course> courses) {
    final slots = courses.expand((c) => c.timeSlots).toList();
    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        if (slots[i].conflictsWith(slots[j])) return true;
      }
    }
    return false;
  }

  Timetable _tournamentSelect(List<Timetable> pop) {
    final a = pop[_rng.nextInt(min(30, pop.length))];
    final b = pop[_rng.nextInt(min(30, pop.length))];
    return a.score >= b.score ? a : b;
  }

  Timetable _crossover(Timetable p1, Timetable p2, List<Course> required,
      List<Course> electives, UserPreference pref) {
    final pool = {...p1.courses, ...p2.courses}.toList()..shuffle(_rng);
    final selected = [...required];
    for (final c in pool) {
      if (required.any((r) => r.id == c.id)) continue;
      if (_totalCredits(selected) + c.credit > pref.maxCredits) continue;
      if (!_hasConflict([...selected, c])) selected.add(c);
    }
    return _evaluate(selected, pref);
  }

  Timetable _mutate(Timetable t, List<Course> electives, UserPreference pref) {
    if (_rng.nextDouble() > _mutationRate) return t;
    final courses = [...t.courses];
    // 필수 과목이 아닌 것만 제거
    final removable = courses.where((c) => !c.isMajorRequired).toList();
    if (removable.isNotEmpty) courses.remove(removable[_rng.nextInt(removable.length)]);
    final candidate = electives[_rng.nextInt(electives.length)];
    if (_totalCredits(courses) + candidate.credit <= pref.maxCredits &&
        !_hasConflict([...courses, candidate])) {
      courses.add(candidate);
    }
    return _evaluate(courses, pref);
  }

  Timetable _evaluate(List<Course> courses, UserPreference pref) {
    if (courses.isEmpty) return Timetable(courses: courses, score: 0);

    final freeScore = _freeTimeScore(courses, pref);
    final ratingScore = courses.fold(0.0, (s, c) => s + c.rating) / courses.length / 5.0;
    final diffScore = 1.0 - (courses.fold(0.0, (s, c) => s + c.difficulty) / courses.length / 5.0);
    final teamScore = pref.avoidTeamProject
        ? courses.where((c) => !c.hasTeamProject).length / courses.length
        : 1.0;
    // 연속 수업 3시간 이상 페널티
    final t = Timetable(courses: courses, score: 0);
    final consecutivePenalty = t.consecutiveMax > 3 ? 0.8 : 1.0;

    final raw = pref.freeTimeWeight * freeScore +
        pref.ratingWeight * ratingScore +
        pref.difficultyWeight * diffScore +
        pref.teamProjectWeight * teamScore;

    final breakdown = {
      'freeTime': freeScore,
      'rating': ratingScore,
      'difficulty': diffScore,
      'teamProject': teamScore,
    };

    return Timetable(courses: courses, score: raw * consecutivePenalty, scoreBreakdown: breakdown);
  }

  double _freeTimeScore(List<Course> courses, UserPreference pref) {
    const days = ['월', '화', '수', '목', '금'];
    double score = 0;
    for (final day in days) {
      final hasClass = courses.any((c) => c.timeSlots.any((s) => s.day == day));
      if (!hasClass) {
        score += 1.0;
      } else if (pref.preferMorning) {
        // 오전 선호: 오후 수업만 있는 날 감점
        final onlyAfternoon = courses
            .expand((c) => c.timeSlots)
            .where((s) => s.day == day)
            .every((s) => s.startHour >= 13);
        if (onlyAfternoon) { score += 0.3; } else { score += 0.6; }
      } else {
        score += 0.5;
      }
    }
    return score / 5.0;
  }
}
