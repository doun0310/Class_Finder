import 'dart:math';

import '../models/course.dart';
import '../models/user_preference.dart';

const _scheduleStartHour = 9;

class Timetable {
  final List<Course> courses;
  final double score;
  final Map<String, double> scoreBreakdown;

  const Timetable({
    required this.courses,
    required this.score,
    this.scoreBreakdown = const {},
  });

  int get totalCredits => courses.fold(0, (sum, course) => sum + course.credit);

  int get totalHours =>
      courses.fold(0, (sum, course) => sum + course.totalHours);

  double get averageRating => courses.isEmpty
      ? 0
      : courses.fold(0.0, (sum, course) => sum + course.rating) /
            courses.length;

  double get averageDifficulty => courses.isEmpty
      ? 0
      : courses.fold(0.0, (sum, course) => sum + course.difficulty) /
            courses.length;

  int get activeDayCount => weekdays
      .where((day) => courses.any((course) => course.occursOn(day)))
      .length;

  int get freeDays => weekdays
      .where((day) => courses.every((course) => !course.occursOn(day)))
      .length;

  int get earliestStartHour {
    if (courses.isEmpty) {
      return 0;
    }

    return courses
        .expand((course) => course.timeSlots)
        .map((slot) => slot.startHour)
        .reduce((value, element) => value < element ? value : element);
  }

  int get latestEndHour {
    if (courses.isEmpty) {
      return 0;
    }

    return courses
        .expand((course) => course.timeSlots)
        .map((slot) => slot.endHour)
        .reduce((value, element) => value > element ? value : element);
  }

  double get averageGapHours {
    double totalGap = 0;
    int activeDays = 0;

    for (final day in weekdays) {
      final daySlots =
          courses
              .expand((course) => course.timeSlots)
              .where((slot) => slot.day == day)
              .toList()
            ..sort((a, b) => a.startHour.compareTo(b.startHour));

      if (daySlots.isEmpty) {
        continue;
      }

      activeDays++;
      final occupiedHours = daySlots.fold<int>(
        0,
        (sum, slot) => sum + slot.durationHours,
      );
      final span = daySlots.last.endHour - daySlots.first.startHour;
      totalGap += max(0, span - occupiedHours);
    }

    return activeDays == 0 ? 0 : totalGap / activeDays;
  }

  double get hardScore => scoreBreakdown['hard'] ?? 1.0;
  double get conflictScore => scoreBreakdown['conflict'] ?? 1.0;
  double get boundsScore => scoreBreakdown['bounds'] ?? 1.0;
  double get freeDayScore => scoreBreakdown['freeDay'] ?? 1.0;
  double get creditLimitScore => scoreBreakdown['creditLimit'] ?? 1.0;
  double get creditCoverageScore => scoreBreakdown['creditCoverage'] ?? 1.0;
  double get softScore => scoreBreakdown['soft'] ?? score;
  double get compactnessScore => scoreBreakdown['compactness'] ?? 0;
  double get creditFitScore => scoreBreakdown['creditFit'] ?? 0;
  double get sectionFitScore => scoreBreakdown['sectionFit'] ?? 0;
  double get lunchScore => scoreBreakdown['lunch'] ?? 1.0;

  bool get hasNoConflicts => conflictScore >= 0.999;
  bool get satisfiesTimeBounds => boundsScore >= 0.999;
  bool get satisfiesFreeDays => freeDayScore >= 0.999;
  bool get satisfiesCreditLimit => creditLimitScore >= 0.999;
  bool get satisfiesCreditCoverage => creditCoverageScore >= 0.999;

  bool get hasLunchBreak => lunchScore >= 0.999;

  int get consecutiveMax {
    int maxStreak = 0;

    for (final day in weekdays) {
      final hours =
          courses
              .expand((course) => course.timeSlots)
              .where((slot) => slot.day == day)
              .expand(
                (slot) => List.generate(
                  slot.durationHours,
                  (i) => slot.startHour + i,
                ),
              )
              .toSet()
              .toList()
            ..sort();

      int streak = 0;
      int best = 0;
      for (int i = 0; i < hours.length; i++) {
        streak = (i > 0 && hours[i] == hours[i - 1] + 1) ? streak + 1 : 1;
        if (streak > best) {
          best = streak;
        }
      }

      if (best > maxStreak) {
        maxStreak = best;
      }
    }

    return maxStreak;
  }
}

class _RunConfig {
  final int populationSize;
  final int maxGenerations;
  final int eliteCount;
  final int immigrantCount;
  final int stagnationWindow;
  final int tournamentSize;
  final int parentPoolSize;
  final int refinePoolSize;
  final int refinePasses;

  const _RunConfig({
    required this.populationSize,
    required this.maxGenerations,
    required this.eliteCount,
    required this.immigrantCount,
    required this.stagnationWindow,
    required this.tournamentSize,
    required this.parentPoolSize,
    required this.refinePoolSize,
    required this.refinePasses,
  });

  factory _RunConfig.fromElectiveCount(int electiveCount) {
    final scaledElectives = max(1, electiveCount);
    final populationSize = min(144, max(84, scaledElectives * 4));
    final maxGenerations = min(96, max(42, scaledElectives * 2));
    final eliteCount = max(10, populationSize ~/ 6);
    final immigrantCount = max(8, populationSize ~/ 9);

    return _RunConfig(
      populationSize: populationSize,
      maxGenerations: maxGenerations,
      eliteCount: eliteCount,
      immigrantCount: immigrantCount,
      stagnationWindow: max(12, maxGenerations ~/ 4),
      tournamentSize: 4,
      parentPoolSize: max(18, populationSize ~/ 3),
      refinePoolSize: min(18, max(10, scaledElectives ~/ 2)),
      refinePasses: 2,
    );
  }
}

class _CourseStats {
  final double utility;
  final List<int> dayMasks;
  final int boundsViolations;
  final int lunchDayMask;
  final int startHourSum;
  final int slotCount;

  const _CourseStats({
    required this.utility,
    required this.dayMasks,
    required this.boundsViolations,
    required this.lunchDayMask,
    required this.startHourSum,
    required this.slotCount,
  });
}

class _CachedEvaluation {
  final double score;
  final Map<String, double> breakdown;

  const _CachedEvaluation({required this.score, required this.breakdown});
}

class _RunContext {
  final UserPreference preference;
  final _RunConfig config;
  final Map<String, double> utilityById;
  final Map<String, _CourseStats> courseStats;
  final Map<String, Set<String>> conflictsByCourseId;
  final Map<String, _CachedEvaluation> evaluationCache = {};

  _RunContext({
    required this.preference,
    required this.config,
    required this.utilityById,
    required this.courseStats,
    required this.conflictsByCourseId,
  });
}

class GeneticAlgorithmService {
  static const double _mutationRate = 0.2;

  final Random _random;
  late _RunContext _context;

  GeneticAlgorithmService({Random? random}) : _random = random ?? Random();

  List<Timetable> run(List<Course> allCourses, UserPreference preference) {
    final eligible = allCourses
        .where(
          (course) => course.grade == 0 || course.grade <= preference.grade,
        )
        .toList();
    final utilityById = _buildUtilityById(eligible, preference);
    final required = _resolveRequiredCourses(
      eligible,
      preference.requiredCourseIds.toSet(),
      utilityById,
    );
    final fixedIds = required.map((course) => course.id).toSet();
    final electives =
        eligible.where((course) => !fixedIds.contains(course.id)).toList()
          ..sort((a, b) => utilityById[b.id]!.compareTo(utilityById[a.id]!));

    if (eligible.isEmpty || (required.isEmpty && electives.isEmpty)) {
      return [];
    }

    _context = _RunContext(
      preference: preference,
      config: _RunConfig.fromElectiveCount(electives.length),
      utilityById: utilityById,
      courseStats: _buildCourseStats(eligible, preference, utilityById),
      conflictsByCourseId: _buildConflictLookup(eligible),
    );

    var population = _seedPopulation(required, electives, preference);
    double bestScore = -1;
    int stagnantGenerations = 0;

    for (
      int generation = 0;
      generation < _context.config.maxGenerations;
      generation++
    ) {
      population.sort((a, b) => b.score.compareTo(a.score));

      final currentBest = population.first.score;
      if (currentBest > bestScore + 1e-6) {
        bestScore = currentBest;
        stagnantGenerations = 0;
      } else {
        stagnantGenerations++;
      }

      if (generation > 20 &&
          stagnantGenerations >= _context.config.stagnationWindow) {
        break;
      }

      final nextGeneration = <Timetable>[
        ...population.take(_context.config.eliteCount),
        ...List.generate(
          _context.config.immigrantCount,
          (index) => _buildCandidate(
            required,
            electives,
            preference,
            exploratory: index.isEven,
          ),
        ),
      ];

      while (nextGeneration.length < _context.config.populationSize) {
        final parentA = _selectParent(population);
        final parentB = _selectParent(population);
        var child = _crossover(
          parentA,
          parentB,
          required,
          electives,
          preference,
        );
        child = _mutate(child, required, electives, preference);
        child = _refine(child, required, electives, preference);
        nextGeneration.add(child);
      }

      population = nextGeneration;
    }

    population.sort((a, b) => b.score.compareTo(a.score));
    return _pickTopUnique(population);
  }

  List<Timetable> _seedPopulation(
    List<Course> required,
    List<Course> electives,
    UserPreference preference,
  ) {
    return List.generate(
      _context.config.populationSize,
      (index) => _buildCandidate(
        required,
        electives,
        preference,
        exploratory: index % 3 == 0,
      ),
    );
  }

  Timetable _buildCandidate(
    List<Course> required,
    List<Course> electives,
    UserPreference preference, {
    required bool exploratory,
  }) {
    final selected = <Course>[...required];
    final rankedPool = [...electives]
      ..sort((a, b) {
        final aScore =
            _courseUtility(a, preference) +
            _random.nextDouble() * (exploratory ? 0.8 : 0.25);
        final bScore =
            _courseUtility(b, preference) +
            _random.nextDouble() * (exploratory ? 0.8 : 0.25);
        return bScore.compareTo(aScore);
      });

    final creditFloor = _creditFloor(preference.maxCredits);

    for (final candidate in rankedPool) {
      if (!_canAddCourse(selected, candidate, preference)) {
        continue;
      }

      final currentCredits = _totalCredits(selected);
      final mustFillCredits = currentCredits < creditFloor;
      var acceptance = mustFillCredits ? 0.58 : 0.26;
      acceptance += _courseUtility(candidate, preference) * 0.42;

      if (candidate.occursOnAny(preference.preferredFreeDays)) {
        acceptance -= 0.22;
      }

      if (_wouldCreateLargeGap(selected, candidate)) {
        acceptance -= 0.16;
      }

      if (_random.nextDouble() <= acceptance.clamp(0.08, 0.96)) {
        selected.add(candidate);
      }
    }

    final base = _evaluate(selected, preference);
    return _refine(base, required, electives, preference);
  }

  Timetable _selectParent(List<Timetable> population) {
    final limit = min(
      population.length,
      max(_context.config.parentPoolSize, population.length ~/ 2),
    );
    Timetable? best;

    for (int i = 0; i < _context.config.tournamentSize; i++) {
      final candidate = population[_random.nextInt(limit)];
      if (best == null || candidate.score > best.score) {
        best = candidate;
      }
    }

    return best!;
  }

  Timetable _crossover(
    Timetable parentA,
    Timetable parentB,
    List<Course> required,
    List<Course> electives,
    UserPreference preference,
  ) {
    final fixedIds = required.map((course) => course.id).toSet();
    final selected = <Course>[...required];
    final inherited =
        {
          for (final course in [...parentA.courses, ...parentB.courses])
            if (!fixedIds.contains(course.id)) course.id: course,
        }.values.toList()..sort((a, b) {
          final aScore =
              _courseUtility(a, preference) + _random.nextDouble() * 0.2;
          final bScore =
              _courseUtility(b, preference) + _random.nextDouble() * 0.2;
          return bScore.compareTo(aScore);
        });

    for (final course in inherited) {
      final inheritChance =
          _totalCredits(selected) < _creditFloor(preference.maxCredits)
          ? 0.8
          : 0.55;
      if (_random.nextDouble() <= inheritChance &&
          _canAddCourse(selected, course, preference)) {
        selected.add(course);
      }
    }

    final child = _evaluate(selected, preference);
    return _refine(child, required, electives, preference);
  }

  Timetable _mutate(
    Timetable timetable,
    List<Course> required,
    List<Course> electives,
    UserPreference preference,
  ) {
    if (_random.nextDouble() > _mutationRate) {
      return timetable;
    }

    final fixedIds = required.map((course) => course.id).toSet();
    final courses = <Course>[...timetable.courses];
    final removable =
        courses.where((course) => !fixedIds.contains(course.id)).toList()..sort(
          (a, b) => _courseUtility(
            a,
            preference,
          ).compareTo(_courseUtility(b, preference)),
        );

    if (removable.isNotEmpty) {
      final removeCount = removable.length > 3 && _random.nextBool() ? 2 : 1;
      for (int i = 0; i < removeCount; i++) {
        if (removable.isEmpty) {
          break;
        }

        final maxIndex = max(1, removable.length ~/ 2);
        final removed = removable.removeAt(_random.nextInt(maxIndex));
        courses.removeWhere((course) => course.id == removed.id);
      }
    }

    final candidates = [...electives]
      ..sort((a, b) {
        final aScore =
            _courseUtility(a, preference) + _random.nextDouble() * 0.35;
        final bScore =
            _courseUtility(b, preference) + _random.nextDouble() * 0.35;
        return bScore.compareTo(aScore);
      });

    for (final candidate in candidates.take(12)) {
      if (_canAddCourse(courses, candidate, preference)) {
        courses.add(candidate);
        if (_random.nextBool()) {
          break;
        }
      }
    }

    return _evaluate(courses, preference);
  }

  Timetable _refine(
    Timetable seed,
    List<Course> required,
    List<Course> electives,
    UserPreference preference,
  ) {
    var best = _evaluate(
      _rebuildWithRequired(seed.courses, required, preference),
      preference,
    );
    final fixedIds = required.map((course) => course.id).toSet();
    final candidatePool = electives
        .take(_context.config.refinePoolSize)
        .toList();

    bool improved = true;
    int pass = 0;

    while (improved && pass < _context.config.refinePasses) {
      improved = false;
      pass++;

      Timetable? bestAddition;
      for (final candidate in candidatePool) {
        if (best.courses.any((course) => course.id == candidate.id)) {
          continue;
        }
        if (!_canAddCourse(best.courses, candidate, preference)) {
          continue;
        }

        final trial = _evaluate([...best.courses, candidate], preference);
        if (trial.score > best.score + 1e-6 &&
            (bestAddition == null || trial.score > bestAddition.score)) {
          bestAddition = trial;
        }
      }

      if (bestAddition != null) {
        best = bestAddition;
        improved = true;
        continue;
      }

      Timetable? bestSwap;
      final removable = best.courses
          .where((course) => !fixedIds.contains(course.id))
          .toList();

      for (final current in removable) {
        for (final candidate in candidatePool) {
          if (best.courses.any((course) => course.id == candidate.id)) {
            continue;
          }

          final trialCourses = best.courses
              .where((course) => course.id != current.id)
              .toList(growable: true);
          if (!_canAddCourse(trialCourses, candidate, preference)) {
            continue;
          }

          trialCourses.add(candidate);
          final trial = _evaluate(trialCourses, preference);
          if (trial.score > best.score + 1e-6 &&
              (bestSwap == null || trial.score > bestSwap.score)) {
            bestSwap = trial;
          }
        }
      }

      if (bestSwap != null) {
        best = bestSwap;
        improved = true;
        continue;
      }

      Timetable? bestTrim;
      for (final current in removable) {
        final trialCourses = best.courses
            .where((course) => course.id != current.id)
            .toList(growable: false);
        final trial = _evaluate(trialCourses, preference);
        if (trial.score > best.score + 0.01 &&
            (bestTrim == null || trial.score > bestTrim.score)) {
          bestTrim = trial;
        }
      }

      if (bestTrim != null) {
        best = bestTrim;
        improved = true;
      }
    }

    return best;
  }

  Timetable _evaluate(List<Course> courses, UserPreference preference) {
    if (courses.isEmpty) {
      return const Timetable(courses: [], score: 0);
    }

    final evaluationKey = _evaluationKey(courses);
    final cached = _context.evaluationCache[evaluationKey];
    if (cached != null) {
      return Timetable(
        courses: courses,
        score: cached.score,
        scoreBreakdown: cached.breakdown,
      );
    }

    final dayMasks = List<int>.filled(weekdays.length, 0);
    double totalRating = 0;
    double totalDifficulty = 0;
    double utilitySum = 0;
    int totalCredits = 0;
    int nonTeamCount = 0;
    int boundsViolations = 0;
    int lunchDayMask = 0;
    int startHourSum = 0;
    int slotCount = 0;

    for (final course in courses) {
      final stats = _context.courseStats[course.id]!;
      totalRating += course.rating;
      totalDifficulty += course.difficulty;
      totalCredits += course.credit;
      utilitySum += stats.utility;
      if (!course.hasTeamProject) {
        nonTeamCount++;
      }
      boundsViolations += stats.boundsViolations;
      lunchDayMask |= stats.lunchDayMask;
      startHourSum += stats.startHourSum;
      slotCount += stats.slotCount;
      for (int dayIndex = 0; dayIndex < weekdays.length; dayIndex++) {
        dayMasks[dayIndex] |= stats.dayMasks[dayIndex];
      }
    }

    final conflictScore = _conflictScore(courses);
    final boundsScore = 1 / (boundsViolations + 1);
    final freeDayScore = _freeDayScoreFromMasks(dayMasks, preference);
    final creditLimitScore =
        1 / (max(0, totalCredits - preference.maxCredits) + 1);
    final creditCoverageScore = _creditCoverageScoreFromCredits(
      totalCredits,
      preference,
    );
    final hardScore =
        conflictScore *
        boundsScore *
        freeDayScore *
        creditLimitScore *
        creditCoverageScore;

    final freeDayCount = dayMasks.where((mask) => mask == 0).length;
    final gapScore = _gapScoreFromMasks(dayMasks);
    final compactnessScore = _compactnessScoreFromMasks(dayMasks);
    final creditFitScore = _creditFitScoreFromCredits(totalCredits, preference);
    final sectionFitScore = (utilitySum / courses.length)
        .clamp(0.0, 1.0)
        .toDouble();
    final lunchScore = 1 / (_bitCount(lunchDayMask) + 1);
    final morningScore = slotCount == 0
        ? 0.0
        : ((18 - (startHourSum / slotCount)) / 9).clamp(0.0, 1.0);
    final consecutiveMax = _consecutiveMaxFromMasks(dayMasks);
    final softScore = _softScore(
      courseCount: courses.length,
      totalRating: totalRating,
      totalDifficulty: totalDifficulty,
      nonTeamCount: nonTeamCount,
      preference: preference,
      freeDayCount: freeDayCount,
      gapScore: gapScore,
      compactnessScore: compactnessScore,
      creditFitScore: creditFitScore,
      sectionFitScore: sectionFitScore,
      lunchScore: lunchScore,
      morningScore: morningScore,
      consecutiveMax: consecutiveMax,
    );

    final scoreBreakdown = <String, double>{
      'hard': hardScore,
      'conflict': conflictScore,
      'bounds': boundsScore,
      'freeDay': freeDayScore,
      'creditLimit': creditLimitScore,
      'creditCoverage': creditCoverageScore,
      'soft': softScore,
      'compactness': compactnessScore,
      'creditFit': creditFitScore,
      'sectionFit': sectionFitScore,
      'lunch': lunchScore,
      'morning': morningScore,
    };
    final score = hardScore * softScore;

    _context.evaluationCache[evaluationKey] = _CachedEvaluation(
      score: score,
      breakdown: Map.unmodifiable(scoreBreakdown),
    );

    return Timetable(
      courses: courses,
      score: score,
      scoreBreakdown: scoreBreakdown,
    );
  }

  double _conflictScore(List<Course> courses) {
    int conflicts = 0;
    for (int i = 0; i < courses.length; i++) {
      final courseId = courses[i].id;
      for (int j = i + 1; j < courses.length; j++) {
        if (_context.conflictsByCourseId[courseId]!.contains(courses[j].id)) {
          conflicts++;
        }
      }
    }

    return 1 / (conflicts + 1);
  }

  double _freeDayScoreFromMasks(List<int> dayMasks, UserPreference preference) {
    if (preference.preferredFreeDays.isEmpty) {
      return 1.0;
    }

    int violations = 0;
    for (final day in preference.preferredFreeDays) {
      final dayIndex = weekdays.indexOf(day);
      if (dayIndex >= 0 && dayMasks[dayIndex] != 0) {
        violations++;
      }
    }

    return 1 / (violations + 1);
  }

  double _creditCoverageScoreFromCredits(
    int totalCredits,
    UserPreference preference,
  ) {
    final targetFloor = _creditFloor(preference.maxCredits);
    final shortage = max(0, targetFloor - totalCredits);
    return 1 / (shortage ~/ 3 + 1);
  }

  double _softScore({
    required int courseCount,
    required double totalRating,
    required double totalDifficulty,
    required int nonTeamCount,
    required UserPreference preference,
    required int freeDayCount,
    required double gapScore,
    required double compactnessScore,
    required double creditFitScore,
    required double sectionFitScore,
    required double lunchScore,
    required double morningScore,
    required int consecutiveMax,
  }) {
    final freeTimeScore = _freeTimeScore(
      freeDayCount,
      gapScore,
      compactnessScore,
    );
    final ratingScore = totalRating / courseCount / 5;
    final difficultyScore = 1 - (totalDifficulty / courseCount / 5);

    final teamWeight = preference.avoidTeamProject ? 0.2 : 0.0;
    final teamScore = preference.avoidTeamProject
        ? nonTeamCount / courseCount
        : 0.7;

    final preferenceWeight =
        preference.freeTimeWeight +
        preference.ratingWeight +
        preference.difficultyWeight +
        teamWeight;
    final preferenceScore = preferenceWeight == 0
        ? 0.65
        : (preference.freeTimeWeight * freeTimeScore +
                  preference.ratingWeight * ratingScore +
                  preference.difficultyWeight * difficultyScore +
                  teamWeight * teamScore) /
              preferenceWeight;

    final scheduleQuality =
        0.24 * compactnessScore +
        0.18 * gapScore +
        0.34 * creditFitScore +
        0.24 * sectionFitScore;
    final consecutivePenalty = _consecutivePenalty(consecutiveMax);
    final lunchFactor = preference.requireLunchBreak
        ? lunchScore
        : 0.88 + 0.12 * lunchScore;
    final morningFactor = preference.preferMorning
        ? 0.72 + 0.28 * morningScore
        : 1.0;

    final combined =
        (0.68 * preferenceScore + 0.32 * scheduleQuality) *
        lunchFactor *
        morningFactor *
        consecutivePenalty;

    return combined.clamp(0.0, 1.0);
  }

  double _freeTimeScore(int freeDayCount, double gapScore, double compactness) {
    final freeDayRatio = weekdays.isEmpty
        ? 0.0
        : freeDayCount / weekdays.length;
    return (0.2 * freeDayRatio + 0.4 * gapScore + 0.4 * compactness).clamp(
      0.0,
      1.0,
    );
  }

  double _compactnessScoreFromMasks(List<int> dayMasks) {
    double total = 0;
    int activeDays = 0;

    for (final mask in dayMasks) {
      if (mask == 0) {
        continue;
      }

      activeDays++;
      final occupiedHours = _bitCount(mask);
      final span = _maskSpan(mask);
      total += span == 0 ? 1.0 : occupiedHours / span;
    }

    return activeDays == 0 ? 0 : (total / activeDays).clamp(0.0, 1.0);
  }

  double _gapScoreFromMasks(List<int> dayMasks) {
    double totalGap = 0;
    int activeDays = 0;

    for (final mask in dayMasks) {
      if (mask == 0) {
        continue;
      }

      activeDays++;
      final occupiedHours = _bitCount(mask);
      final span = _maskSpan(mask);
      totalGap += max(0, span - occupiedHours);
    }

    if (activeDays == 0) {
      return 1.0;
    }

    final averageGap = totalGap / activeDays;
    return (1 - averageGap / 4).clamp(0.0, 1.0);
  }

  double _creditFitScoreFromCredits(int credits, UserPreference preference) {
    final target = preference.maxCredits;
    if (target <= 0) {
      return 1.0;
    }

    final coverage = credits / target;
    final difference = (target - credits).abs();
    final closeness = (1 - difference / target).clamp(0.0, 1.0);
    return (0.65 * coverage + 0.35 * closeness).clamp(0.0, 1.0);
  }

  double _consecutivePenalty(int consecutiveMax) {
    final overflow = max(0, consecutiveMax - 3);
    return (1 - overflow * 0.05).clamp(0.82, 1.0);
  }

  double _courseUtility(Course course, UserPreference preference) {
    return _context.utilityById[course.id] ??
        _calculateCourseUtility(course, preference);
  }

  double _calculateCourseUtility(Course course, UserPreference preference) {
    final ratingScore = course.rating / 5;
    final difficultyScore = 1 - course.difficulty / 5;
    final inPreferredRangeScore =
        course.timeSlots.every(
          (slot) =>
              slot.startHour >= preference.minStartHour &&
              slot.endHour <= preference.maxEndHour,
        )
        ? 1.0
        : 0.35;
    final lunchCompatibility =
        course.timeSlots.any((slot) => slot.startHour < 13 && slot.endHour > 12)
        ? 0.2
        : 1.0;
    final timeRange = max(1, preference.maxEndHour - preference.minStartHour);
    final startFit =
        ((preference.maxEndHour - course.earliestStartHour) / timeRange).clamp(
          0.0,
          1.0,
        );
    final finishFit =
        ((preference.maxEndHour - course.latestEndHour + 1) / (timeRange + 1))
            .clamp(0.0, 1.0);
    final timePlacementScore = (0.55 * startFit + 0.45 * finishFit).clamp(
      0.0,
      1.0,
    );
    final morningBias = preference.preferMorning
        ? (0.7 * ((18 - course.earliestStartHour) / 9).clamp(0.0, 1.0) +
                  0.3 * timePlacementScore)
              .clamp(0.0, 1.0)
        : timePlacementScore;
    final teamScore = preference.avoidTeamProject && course.hasTeamProject
        ? 0.0
        : 1.0;
    final preferredFreeDayPenalty =
        course.occursOnAny(preference.preferredFreeDays) ? 0.0 : 1.0;

    return (0.24 * ratingScore +
            0.16 * difficultyScore +
            0.2 * inPreferredRangeScore +
            0.12 * lunchCompatibility +
            0.14 * morningBias +
            0.08 * teamScore +
            0.06 * preferredFreeDayPenalty)
        .clamp(0.0, 1.0);
  }

  List<Course> _resolveRequiredCourses(
    List<Course> eligible,
    Set<String> requiredCourseIds,
    Map<String, double> utilityById,
  ) {
    final selected = eligible
        .where((course) => requiredCourseIds.contains(course.id))
        .toList();
    final grouped = <String, List<Course>>{};

    for (final course in selected) {
      grouped.putIfAbsent(course.courseCode, () => []).add(course);
    }

    return grouped.values.map((courses) {
      courses.sort((a, b) => utilityById[b.id]!.compareTo(utilityById[a.id]!));
      return courses.first;
    }).toList();
  }

  List<Course> _rebuildWithRequired(
    List<Course> courses,
    List<Course> required,
    UserPreference preference,
  ) {
    final fixedIds = required.map((course) => course.id).toSet();
    final rebuilt = <Course>[...required];
    final others =
        courses.where((course) => !fixedIds.contains(course.id)).toList()..sort(
          (a, b) => _courseUtility(
            b,
            preference,
          ).compareTo(_courseUtility(a, preference)),
        );

    for (final course in others) {
      if (_canAddCourse(rebuilt, course, preference)) {
        rebuilt.add(course);
      }
    }

    return rebuilt;
  }

  bool _canAddCourse(
    List<Course> courses,
    Course candidate,
    UserPreference preference,
  ) {
    if (courses.any((course) => course.id == candidate.id)) {
      return false;
    }
    if (_hasSameCourse(courses, candidate)) {
      return false;
    }
    if (_totalCredits(courses) + candidate.credit > preference.maxCredits) {
      return false;
    }
    return !_conflictsWithAny(courses, candidate);
  }

  bool _wouldCreateLargeGap(List<Course> courses, Course candidate) {
    for (final slot in candidate.timeSlots) {
      final daySlots = courses
          .expand((course) => course.timeSlots)
          .where((existing) => existing.day == slot.day)
          .toList();

      for (final existing in daySlots) {
        final gapA = (slot.startHour - existing.endHour).abs();
        final gapB = (existing.startHour - slot.endHour).abs();
        if (gapA >= 3 || gapB >= 3) {
          return true;
        }
      }
    }

    return false;
  }

  List<Timetable> _pickTopUnique(List<Timetable> population) {
    final unique = <Timetable>[];
    final seen = <String>{};

    for (final timetable in population) {
      final key =
          (timetable.courses.map((course) => course.id).toList()..sort()).join(
            ',',
          );
      if (!seen.add(key)) {
        continue;
      }

      unique.add(timetable);
      if (unique.length == 5) {
        break;
      }
    }

    return unique;
  }

  int _creditFloor(int maxCredits) =>
      maxCredits <= 3 ? maxCredits : maxCredits - 3;

  int _totalCredits(List<Course> courses) =>
      courses.fold(0, (sum, course) => sum + course.credit);

  bool _hasSameCourse(List<Course> courses, Course candidate) =>
      courses.any((course) => course.courseCode == candidate.courseCode);

  Map<String, double> _buildUtilityById(
    List<Course> courses,
    UserPreference preference,
  ) {
    return {
      for (final course in courses)
        course.id: _calculateCourseUtility(course, preference),
    };
  }

  Map<String, _CourseStats> _buildCourseStats(
    List<Course> courses,
    UserPreference preference,
    Map<String, double> utilityById,
  ) {
    final stats = <String, _CourseStats>{};

    for (final course in courses) {
      final dayMasks = List<int>.filled(weekdays.length, 0);
      int boundsViolations = 0;
      int lunchDayMask = 0;
      int startHourSum = 0;
      int slotCount = 0;

      for (final slot in course.timeSlots) {
        final dayIndex = weekdays.indexOf(slot.day);
        if (dayIndex < 0) {
          continue;
        }

        dayMasks[dayIndex] |= _hourMask(slot.startHour, slot.endHour);
        if (slot.startHour < preference.minStartHour) {
          boundsViolations++;
        }
        if (slot.endHour > preference.maxEndHour) {
          boundsViolations++;
        }
        if (slot.startHour < 13 && slot.endHour > 12) {
          lunchDayMask |= 1 << dayIndex;
        }
        startHourSum += slot.startHour;
        slotCount++;
      }

      stats[course.id] = _CourseStats(
        utility: utilityById[course.id]!,
        dayMasks: dayMasks,
        boundsViolations: boundsViolations,
        lunchDayMask: lunchDayMask,
        startHourSum: startHourSum,
        slotCount: slotCount,
      );
    }

    return stats;
  }

  Map<String, Set<String>> _buildConflictLookup(List<Course> courses) {
    final lookup = {for (final course in courses) course.id: <String>{}};

    for (int i = 0; i < courses.length; i++) {
      for (int j = i + 1; j < courses.length; j++) {
        if (_coursesConflict(courses[i], courses[j])) {
          lookup[courses[i].id]!.add(courses[j].id);
          lookup[courses[j].id]!.add(courses[i].id);
        }
      }
    }

    return lookup;
  }

  bool _coursesConflict(Course left, Course right) {
    for (final leftSlot in left.timeSlots) {
      for (final rightSlot in right.timeSlots) {
        if (leftSlot.conflictsWith(rightSlot)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _conflictsWithAny(List<Course> courses, Course candidate) {
    final conflicts = _context.conflictsByCourseId[candidate.id]!;
    for (final course in courses) {
      if (conflicts.contains(course.id)) {
        return true;
      }
    }
    return false;
  }

  String _evaluationKey(List<Course> courses) =>
      (courses.map((course) => course.id).toList()..sort()).join(',');

  int _hourMask(int startHour, int endHour) {
    int mask = 0;
    for (int hour = startHour; hour < endHour; hour++) {
      mask |= 1 << (hour - _scheduleStartHour);
    }
    return mask;
  }

  int _bitCount(int value) {
    int count = 0;
    int current = value;
    while (current != 0) {
      current &= current - 1;
      count++;
    }
    return count;
  }

  int _maskSpan(int mask) {
    if (mask == 0) {
      return 0;
    }

    int startBit = 0;
    while (((mask >> startBit) & 1) == 0) {
      startBit++;
    }

    int endBit = mask.bitLength - 1;
    while (((mask >> endBit) & 1) == 0) {
      endBit--;
    }

    return endBit - startBit + 1;
  }

  int _consecutiveMaxFromMasks(List<int> dayMasks) {
    int best = 0;

    for (final mask in dayMasks) {
      int currentMask = mask;
      int current = 0;
      int dayBest = 0;

      while (currentMask != 0) {
        if ((currentMask & 1) == 1) {
          current++;
          if (current > dayBest) {
            dayBest = current;
          }
        } else {
          current = 0;
        }
        currentMask >>= 1;
      }

      if (dayBest > best) {
        best = dayBest;
      }
    }

    return best;
  }
}

extension on Course {
  bool occursOnAny(List<String> days) => days.any(occursOn);
}
