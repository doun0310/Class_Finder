import 'dart:math';
import '../models/course.dart';
import '../models/user_preference.dart';

class Timetable {
  final List<Course> courses;
  final double score;
  final Map<String, double> scoreBreakdown;

  const Timetable({
    required this.courses,
    required this.score,
    this.scoreBreakdown = const {},
  });

  int get totalCredits => courses.fold(0, (s, c) => s + c.credit);

  double get hardScore => scoreBreakdown['hard'] ?? 1.0;
  double get conflictScore => scoreBreakdown['conflict'] ?? 1.0;
  double get boundsScore => scoreBreakdown['bounds'] ?? 1.0;
  double get freeDayScore => scoreBreakdown['freeDay'] ?? 1.0;
  double get softScore => scoreBreakdown['soft'] ?? score;

  bool get hasNoConflicts => conflictScore >= 1.0;
  bool get satisfiesTimeBounds => boundsScore >= 1.0;
  bool get satisfiesFreeDays => freeDayScore >= 1.0;

  int get freeDays {
    const days = ['월', '화', '수', '목', '금'];
    return days.where((d) => courses.every((c) => c.timeSlots.every((s) => s.day != d))).length;
  }

  bool get hasLunchBreak {
    const days = ['월', '화', '수', '목', '금'];
    return days.every((day) {
      final slots = courses.expand((c) => c.timeSlots).where((s) => s.day == day);
      return !slots.any((s) => s.startHour < 13 && s.endHour > 12);
    });
  }

  int get consecutiveMax {
    const days = ['월', '화', '수', '목', '금'];
    int maxStreak = 0;
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
      if (best > maxStreak) maxStreak = best;
    }
    return maxStreak;
  }
}

// ── 유전 알고리즘 (Where-Got-TimeTable 구조 참조) ─────────────────
// 핵심 구조: composite = hardFitness * softFitness
//   hardFitness = conflictScore * boundsScore * freeDayScore  (각 1/(위반+1))
//   softFitness = 정규화된 가중합 * 점심점수 * 연속수업페널티
class GeneticAlgorithmService {
  static const int _popSize = 200;
  static const int _maxGenerations = 200;
  static const double _mutationRate = 0.15;
  static const int _eliteCount = 20;
  static const int _convergenceWindow = 30; // 30세대 이상 개선 없으면 종료

  final Random _rng = Random();

  List<Timetable> run(List<Course> allCourses, UserPreference pref) {
    final eligible = allCourses.where((c) => c.grade == 0 || c.grade <= pref.grade).toList();
    final required = eligible.where((c) => pref.requiredCourseIds.contains(c.id)).toList();
    final electives = eligible.where((c) => !pref.requiredCourseIds.contains(c.id)).toList();

    if (electives.isEmpty && required.isEmpty) return [];

    var population = _initPopulation(required, electives, pref);

    double bestScore = 0;
    int noImprovementCount = 0;

    for (int g = 0; g < _maxGenerations; g++) {
      population.sort((a, b) => b.score.compareTo(a.score));

      final currentBest = population.first.score;
      if (currentBest > bestScore + 1e-6) {
        bestScore = currentBest;
        noImprovementCount = 0;
      } else {
        noImprovementCount++;
      }

      // 수렴 감지: 50세대 이후 30세대 개선 없으면 조기 종료
      if (g > 50 && noImprovementCount >= _convergenceWindow) break;

      final next = population.take(_eliteCount).toList();
      while (next.length < _popSize) {
        final p1 = _weightedSelect(population);
        final p2 = _weightedSelect(population);
        var child = _crossover(p1, p2, required, electives, pref);
        child = _mutate(child, electives, pref);
        next.add(child);
      }
      population = next;
    }

    population.sort((a, b) => b.score.compareTo(a.score));

    final seen = <String>{};
    final unique = <Timetable>[];
    for (final t in population) {
      final key = (t.courses.map((c) => c.id).toList()..sort()).join(',');
      if (seen.add(key)) unique.add(t);
      if (unique.length == 5) break;
    }
    return unique;
  }

  // ── 초기 집단 생성 ────────────────────────────────────────────
  List<Timetable> _initPopulation(
      List<Course> required, List<Course> electives, UserPreference pref) {
    return List.generate(_popSize, (_) {
      final shuffled = [...electives]..shuffle(_rng);
      final selected = [...required];
      for (final c in shuffled) {
        if (_totalCredits(selected) + c.credit > pref.maxCredits) continue;
        if (_hasSameCourse(selected, c)) continue; // 같은 과목 다른 분반 중복 방지
        if (!_hasTimeConflict([...selected, c])) selected.add(c);
      }
      return _evaluate(selected, pref);
    });
  }

  // ── 가중 랜덤 선택 (Where-Got-TimeTable: weighted random selection) ─
  Timetable _weightedSelect(List<Timetable> pop) {
    final candidates = pop.take(60).toList();
    final total = candidates.fold(0.0, (s, t) => s + t.score);
    if (total <= 0) return candidates[_rng.nextInt(candidates.length)];
    double r = _rng.nextDouble() * total;
    for (final t in candidates) {
      r -= t.score;
      if (r <= 0) return t;
    }
    return candidates.last;
  }

  // ── 단일점 교차 (부모 과목 합집합에서 충돌 없이 선택) ─────────────
  Timetable _crossover(Timetable p1, Timetable p2,
      List<Course> required, List<Course> electives, UserPreference pref) {
    // 두 부모의 선택과목을 합치고 랜덤 순서로 탐욕적 선택
    final pool = ({...p1.courses, ...p2.courses}
          .where((c) => !required.any((r) => r.id == c.id))
          .toList()
        ..shuffle(_rng));
    final selected = [...required];
    for (final c in pool) {
      if (_totalCredits(selected) + c.credit > pref.maxCredits) continue;
      if (_hasSameCourse(selected, c)) continue; // 같은 과목 다른 분반 중복 방지
      if (!_hasTimeConflict([...selected, c])) selected.add(c);
    }
    return _evaluate(selected, pref);
  }

  // ── 돌연변이 (비필수 과목 하나 교체) ─────────────────────────────
  Timetable _mutate(Timetable t, List<Course> electives, UserPreference pref) {
    if (_rng.nextDouble() > _mutationRate) return t;
    final courses = [...t.courses];
    final removable = courses.where((c) => !c.isMajorRequired).toList();
    if (removable.isNotEmpty) {
      courses.remove(removable[_rng.nextInt(removable.length)]);
    }
    final shuffled = [...electives]..shuffle(_rng);
    for (final candidate in shuffled) {
      if (_totalCredits(courses) + candidate.credit <= pref.maxCredits &&
          !_hasSameCourse(courses, candidate) && // 같은 과목 다른 분반 중복 방지
          !_hasTimeConflict([...courses, candidate])) {
        courses.add(candidate);
        break;
      }
    }
    return _evaluate(courses, pref);
  }

  // ── 적합도 평가 (하드 × 소프트 복합 점수) ───────────────────────
  Timetable _evaluate(List<Course> courses, UserPreference pref) {
    if (courses.isEmpty) {
      return Timetable(courses: courses, score: 0, scoreBreakdown: const {});
    }

    // ① 하드 제약 (Where-Got-TimeTable: 1/(violations+1) 방식)
    final conflictSc = _conflictScore(courses);
    final boundsSc = _boundsScore(courses, pref);
    final freeDaySc = _freeDayScore(courses, pref);
    final hardSc = conflictSc * boundsSc * freeDaySc;

    // ② 소프트 제약 (정규화 가중합)
    final softSc = _softScore(courses, pref);

    // ③ 복합 점수 = hard × soft (하드 위반 시 급격히 감소)
    final composite = hardSc * softSc;

    return Timetable(
      courses: courses,
      score: composite,
      scoreBreakdown: {
        'hard': hardSc,
        'conflict': conflictSc,
        'bounds': boundsSc,
        'freeDay': freeDaySc,
        'soft': softSc,
      },
    );
  }

  // ── 하드 제약 ①: 시간 충돌 (1/(충돌수+1)) ────────────────────────
  double _conflictScore(List<Course> courses) {
    int conflicts = 0;
    final slots = courses.expand((c) => c.timeSlots).toList();
    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        if (slots[i].conflictsWith(slots[j])) conflicts++;
      }
    }
    return 1.0 / (conflicts + 1);
  }

  // ── 하드 제약 ②: 시간 범위 (1/(범위초과수+1)) ────────────────────
  double _boundsScore(List<Course> courses, UserPreference pref) {
    int violations = 0;
    for (final c in courses) {
      for (final s in c.timeSlots) {
        if (s.startHour < pref.minStartHour) violations++;
        if (s.endHour > pref.maxEndHour) violations++;
      }
    }
    return 1.0 / (violations + 1);
  }

  // ── 하드 제약 ③: 공강 희망 요일 (1/(위반일수+1)) ─────────────────
  double _freeDayScore(List<Course> courses, UserPreference pref) {
    if (pref.preferredFreeDays.isEmpty) return 1.0;
    int violations = 0;
    for (final day in pref.preferredFreeDays) {
      if (courses.any((c) => c.timeSlots.any((s) => s.day == day))) {
        violations++;
      }
    }
    return 1.0 / (violations + 1);
  }

  // ── 소프트 제약: 정규화 가중합 × 점심 × 연속수업 ─────────────────
  double _softScore(List<Course> courses, UserPreference pref) {
    if (courses.isEmpty) return 0;

    final freeScore = _freeTimeScore(courses, pref);
    final ratingScore =
        courses.fold(0.0, (s, c) => s + c.rating) / courses.length / 5.0;
    final diffScore = 1.0 -
        (courses.fold(0.0, (s, c) => s + c.difficulty) /
            courses.length /
            5.0);

    // 팀플 점수: avoidTeamProject 시 20% 가중치 부여
    final teamWeight = pref.avoidTeamProject ? 0.2 : 0.0;
    final teamScore = pref.avoidTeamProject
        ? courses.where((c) => !c.hasTeamProject).length / courses.length
        : 0.0;

    // 정규화: 총 가중치로 나눔
    final totalWeight =
        pref.freeTimeWeight + pref.ratingWeight + pref.difficultyWeight + teamWeight;
    if (totalWeight <= 0) return 0;

    final raw = (pref.freeTimeWeight * freeScore +
            pref.ratingWeight * ratingScore +
            pref.difficultyWeight * diffScore +
            teamWeight * teamScore) /
        totalWeight;

    // 점심시간 확보 소프트 보너스 (Where-Got-TimeTable: check_lunch_break)
    final lunchFactor = pref.requireLunchBreak ? _lunchScore(courses) : 1.0;

    // 연속 수업 3시간 이상 페널티
    final t = Timetable(courses: courses, score: 0);
    final consecutivePenalty = t.consecutiveMax > 3 ? 0.85 : 1.0;

    return raw * lunchFactor * consecutivePenalty;
  }

  // ── 점심시간 확보 점수 (12~13 블록 여부, 1/(차단 요일수+1)) ────────
  double _lunchScore(List<Course> courses) {
    const days = ['월', '화', '수', '목', '금'];
    int blocked = 0;
    for (final day in days) {
      final daySlots =
          courses.expand((c) => c.timeSlots).where((s) => s.day == day);
      if (daySlots.any((s) => s.startHour < 13 && s.endHour > 12)) {
        blocked++;
      }
    }
    return 1.0 / (blocked + 1);
  }

  // ── 공강/오전 선호 점수 ───────────────────────────────────────
  double _freeTimeScore(List<Course> courses, UserPreference pref) {
    const days = ['월', '화', '수', '목', '금'];
    double score = 0;
    for (final day in days) {
      final daySlots = courses
          .expand((c) => c.timeSlots)
          .where((s) => s.day == day)
          .toList();
      if (daySlots.isEmpty) {
        score += 1.0; // 공강일
      } else if (pref.preferMorning) {
        // 오전 선호: 오전 수업이 있으면 보너스, 오후만 있으면 감점
        final hasMorning = daySlots.any((s) => s.startHour < 12);
        score += hasMorning ? 0.7 : 0.2;
      } else {
        score += 0.5; // 수업 있음 (중립)
      }
    }
    return score / 5.0;
  }

  // ── 헬퍼 ──────────────────────────────────────────────────────
  int _totalCredits(List<Course> courses) =>
      courses.fold(0, (s, c) => s + c.credit);

  // 동일 과목(분반 무관) 중복 여부: courseCode(ID에서 분반 제외 부분)가 같으면 중복
  bool _hasSameCourse(List<Course> courses, Course candidate) =>
      courses.any((c) => c.courseCode == candidate.courseCode);

  bool _hasTimeConflict(List<Course> courses) {
    final slots = courses.expand((c) => c.timeSlots).toList();
    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        if (slots[i].conflictsWith(slots[j])) return true;
      }
    }
    return false;
  }
}
