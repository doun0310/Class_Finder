import 'dart:math';

import '../models/course.dart';
import '../models/user_preference.dart';

const _scheduleStartHour = 9;
const _weekdayCount = 5;

class Timetable {
  final List<Course> courses;
  final double score;
  final Map<String, double> scoreBreakdown;
  late final _TimetableSummary _summary = _TimetableSummary.fromCourses(
    courses,
  );

  Timetable({
    required this.courses,
    required this.score,
    this.scoreBreakdown = const {},
  });

  Timetable.empty() : courses = const [], score = 0, scoreBreakdown = const {};

  int get totalCredits => _summary.totalCredits;

  int get totalHours => _summary.totalHours;

  double get averageRating => _summary.averageRating;

  double get averageDifficulty => _summary.averageDifficulty;

  int get activeDayCount => _summary.activeDayCount;

  int get freeDays => _summary.freeDays;

  int get earliestStartHour => _summary.earliestStartHour;

  int get latestEndHour => _summary.latestEndHour;

  double get averageGapHours => _summary.averageGapHours;

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

  int get consecutiveMax => _summary.consecutiveMax;
}

class _TimetableSummary {
  final int totalCredits;
  final int totalHours;
  final double averageRating;
  final double averageDifficulty;
  final int activeDayCount;
  final int freeDays;
  final int earliestStartHour;
  final int latestEndHour;
  final double averageGapHours;
  final int consecutiveMax;

  const _TimetableSummary({
    required this.totalCredits,
    required this.totalHours,
    required this.averageRating,
    required this.averageDifficulty,
    required this.activeDayCount,
    required this.freeDays,
    required this.earliestStartHour,
    required this.latestEndHour,
    required this.averageGapHours,
    required this.consecutiveMax,
  });

  const _TimetableSummary.empty()
    : totalCredits = 0,
      totalHours = 0,
      averageRating = 0,
      averageDifficulty = 0,
      activeDayCount = 0,
      freeDays = _weekdayCount,
      earliestStartHour = 0,
      latestEndHour = 0,
      averageGapHours = 0,
      consecutiveMax = 0;

  factory _TimetableSummary.fromCourses(List<Course> courses) {
    if (courses.isEmpty) {
      return const _TimetableSummary.empty();
    }

    final dayMasks = List<int>.filled(weekdays.length, 0);
    int totalCredits = 0;
    int totalHours = 0;
    double totalRating = 0;
    double totalDifficulty = 0;
    int earliestStartHour = 24;
    int latestEndHour = 0;

    for (final course in courses) {
      totalCredits += course.credit;
      totalHours += course.totalHours;
      totalRating += course.rating;
      totalDifficulty += course.difficulty;

      for (final slot in course.timeSlots) {
        final dayIndex = weekdays.indexOf(slot.day);
        if (dayIndex < 0) {
          continue;
        }
        dayMasks[dayIndex] |= _summaryHourMask(slot.startHour, slot.endHour);
        earliestStartHour = min(earliestStartHour, slot.startHour);
        latestEndHour = max(latestEndHour, slot.endHour);
      }
    }

    final activeDayCount = dayMasks.where((mask) => mask != 0).length;
    double totalGap = 0;

    for (final mask in dayMasks) {
      if (mask == 0) {
        continue;
      }
      totalGap += max(0, _summaryMaskSpan(mask) - _summaryBitCount(mask));
    }

    return _TimetableSummary(
      totalCredits: totalCredits,
      totalHours: totalHours,
      averageRating: totalRating / courses.length,
      averageDifficulty: totalDifficulty / courses.length,
      activeDayCount: activeDayCount,
      freeDays: weekdays.length - activeDayCount,
      earliestStartHour: earliestStartHour == 24 ? 0 : earliestStartHour,
      latestEndHour: latestEndHour,
      averageGapHours: activeDayCount == 0 ? 0 : totalGap / activeDayCount,
      consecutiveMax: _summaryConsecutiveMax(dayMasks),
    );
  }

  static int _summaryHourMask(int startHour, int endHour) {
    int mask = 0;
    for (int hour = startHour; hour < endHour; hour++) {
      mask |= 1 << (hour - _scheduleStartHour);
    }
    return mask;
  }

  static int _summaryBitCount(int value) {
    int count = 0;
    int current = value;
    while (current != 0) {
      current &= current - 1;
      count++;
    }
    return count;
  }

  static int _summaryMaskSpan(int mask) {
    int startBit = 0;
    while (((mask >> startBit) & 1) == 0) {
      startBit++;
    }

    int endBit = 31;
    while (((mask >> endBit) & 1) == 0) {
      endBit--;
    }

    return endBit - startBit + 1;
  }

  static int _summaryConsecutiveMax(List<int> dayMasks) {
    int maxStreak = 0;

    for (final mask in dayMasks) {
      if (mask == 0) {
        continue;
      }

      int currentMask = mask;
      int streak = 0;
      int best = 0;
      while (currentMask != 0) {
        if ((currentMask & 1) == 1) {
          streak++;
          if (streak > best) {
            best = streak;
          }
        } else {
          streak = 0;
        }
        currentMask >>= 1;
      }
      maxStreak = max(maxStreak, best);
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
      refinePoolSize: min(14, max(8, scaledElectives ~/ 3)),
      refinePasses: 1,
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
  final List<Course> refineCandidates;
  final Map<String, _CachedEvaluation> evaluationCache = {};

  _RunContext({
    required this.preference,
    required this.config,
    required this.utilityById,
    required this.courseStats,
    required this.conflictsByCourseId,
    required this.refineCandidates,
  });
}

class GeneticAlgorithmService {
  static const double _mutationRate = 0.2;

  final Random _random;
  late _RunContext _context;

  GeneticAlgorithmService({Random? random}) : _random = random ?? Random();

  List<Timetable> run(List<Course> allCourses, UserPreference preference) {
    final eligible = allCourses
        .where((course) => _isEligibleCourse(course, preference))
        .toList();
    final utilityById = _buildUtilityById(eligible, preference);
    final selectedCourses = _resolveSelectedCourses(
      eligible,
      preference.selectedCourseIds.toSet(),
      utilityById,
    );
    if (selectedCourses == null) {
      return [];
    }

    final automaticRequiredCourses = _resolveAutomaticRequiredCourses(
      allCourses,
      eligible,
      selectedCourses,
      utilityById,
      preference,
    );
    if (automaticRequiredCourses == null) {
      return [];
    }

    final fixedCourses = [...selectedCourses, ...automaticRequiredCourses];
    final fixedIds = fixedCourses.map((course) => course.id).toSet();
    final fixedCourseCodes = fixedCourses
        .map((course) => course.courseCode)
        .toSet();
    final electives =
        eligible
            .where(
              (course) =>
                  !fixedIds.contains(course.id) &&
                  !fixedCourseCodes.contains(course.courseCode) &&
                  course.category != CourseCategory.majorRequired,
            )
            .toList()
          ..sort((a, b) => utilityById[b.id]!.compareTo(utilityById[a.id]!));

    if (eligible.isEmpty || (fixedCourses.isEmpty && electives.isEmpty)) {
      return [];
    }

    final config = _RunConfig.fromElectiveCount(electives.length);

    _context = _RunContext(
      preference: preference,
      config: config,
      utilityById: utilityById,
      courseStats: _buildCourseStats(eligible, preference, utilityById),
      conflictsByCourseId: _buildConflictLookup(eligible),
      refineCandidates: electives
          .take(config.refinePoolSize)
          .toList(growable: false),
    );

    var population = _seedPopulation(fixedCourses, electives, preference);
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
            fixedCourses,
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
          fixedCourses,
          electives,
          preference,
        );
        child = _mutate(child, fixedCourses, electives, preference);
        child = _refine(child, fixedCourses, preference);
        nextGeneration.add(child);
      }

      population = nextGeneration;
    }

    population.sort((a, b) => b.score.compareTo(a.score));
    return _pickTopUnique(population);
  }

  List<Timetable> _seedPopulation(
    List<Course> fixedCourses,
    List<Course> electives,
    UserPreference preference,
  ) {
    return List.generate(
      _context.config.populationSize,
      (index) => _buildCandidate(
        fixedCourses,
        electives,
        preference,
        exploratory: index % 3 == 0,
      ),
    );
  }

  Timetable _buildCandidate(
    List<Course> fixedCourses,
    List<Course> electives,
    UserPreference preference, {
    required bool exploratory,
  }) {
    final selected = <Course>[...fixedCourses];
    final rankedPool = _candidateOrder(electives, exploratory: exploratory);
    var currentCredits = _totalCredits(selected);

    final creditFloor = _creditFloor(preference.maxCredits);

    for (final candidate in rankedPool) {
      if (!_canAddCourse(
        selected,
        candidate,
        preference,
        currentCredits: currentCredits,
      )) {
        continue;
      }

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
        currentCredits += candidate.credit;
      }
    }

    final base = _evaluate(selected, preference);
    return _refine(base, fixedCourses, preference);
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
    List<Course> fixedCourses,
    List<Course> electives,
    UserPreference preference,
  ) {
    final fixedIds = fixedCourses.map((course) => course.id).toSet();
    final selected = <Course>[...fixedCourses];
    var currentCredits = _totalCredits(selected);
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
      final inheritChance = currentCredits < _creditFloor(preference.maxCredits)
          ? 0.8
          : 0.55;
      if (_random.nextDouble() <= inheritChance &&
          _canAddCourse(
            selected,
            course,
            preference,
            currentCredits: currentCredits,
          )) {
        selected.add(course);
        currentCredits += course.credit;
      }
    }

    final child = _evaluate(selected, preference);
    return _refine(child, fixedCourses, preference);
  }

  Timetable _mutate(
    Timetable timetable,
    List<Course> fixedCourses,
    List<Course> electives,
    UserPreference preference,
  ) {
    if (_random.nextDouble() > _mutationRate) {
      return timetable;
    }

    final fixedIds = fixedCourses.map((course) => course.id).toSet();
    final courses = <Course>[...timetable.courses];
    var currentCredits = timetable.totalCredits;
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
        currentCredits -= removed.credit;
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
      if (_canAddCourse(
        courses,
        candidate,
        preference,
        currentCredits: currentCredits,
      )) {
        courses.add(candidate);
        currentCredits += candidate.credit;
        if (_random.nextBool()) {
          break;
        }
      }
    }

    return _evaluate(courses, preference);
  }

  Timetable _refine(
    Timetable seed,
    List<Course> fixedCourses,
    UserPreference preference,
  ) {
    var best = _evaluate(
      _rebuildWithFixedCourses(seed.courses, fixedCourses, preference),
      preference,
    );
    final fixedIds = fixedCourses.map((course) => course.id).toSet();
    final candidatePool = _context.refineCandidates;

    bool improved = true;
    int pass = 0;

    while (improved && pass < _context.config.refinePasses) {
      improved = false;
      pass++;
      final bestIds = best.courses.map((course) => course.id).toSet();
      final bestCredits = best.totalCredits;

      Timetable? bestAddition;
      for (final candidate in candidatePool) {
        if (bestIds.contains(candidate.id)) {
          continue;
        }
        if (!_canAddCourse(
          best.courses,
          candidate,
          preference,
          currentCredits: bestCredits,
        )) {
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
          if (bestIds.contains(candidate.id)) {
            continue;
          }

          final trialCourses = best.courses
              .where((course) => course.id != current.id)
              .toList(growable: true);
          if (!_canAddCourse(
            trialCourses,
            candidate,
            preference,
            currentCredits: bestCredits - current.credit,
          )) {
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
      return Timetable.empty();
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
    int coreLiberalCount = 0;
    int balancedLiberalCount = 0;
    int generalLiberalCount = 0;
    int majorElectiveCount = 0;
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
      switch (course.category) {
        case CourseCategory.majorRequired:
          break;
        case CourseCategory.majorElective:
          majorElectiveCount++;
          break;
        case CourseCategory.coreLiberalArts:
          coreLiberalCount++;
          break;
        case CourseCategory.balancedLiberalArts:
          balancedLiberalCount++;
          break;
        case CourseCategory.generalElective:
          generalLiberalCount++;
          break;
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
    final courseMixScore = _courseMixScore(
      coreLiberalCount: coreLiberalCount,
      balancedLiberalCount: balancedLiberalCount,
      generalLiberalCount: generalLiberalCount,
      majorElectiveCount: majorElectiveCount,
      preference: preference,
    );
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
      courseMixScore: courseMixScore,
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
      'courseMix': courseMixScore,
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
    required double courseMixScore,
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
        0.19 * compactnessScore +
        0.14 * gapScore +
        0.24 * creditFitScore +
        0.15 * sectionFitScore +
        0.28 * courseMixScore;
    final consecutivePenalty = _consecutivePenalty(consecutiveMax);
    final lunchFactor = preference.requireLunchBreak
        ? lunchScore
        : 0.88 + 0.12 * lunchScore;
    final morningFactor = preference.preferMorning
        ? 0.72 + 0.28 * morningScore
        : 1.0;

    final combined =
        (0.64 * preferenceScore + 0.36 * scheduleQuality) *
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

  double _courseMixScore({
    required int coreLiberalCount,
    required int balancedLiberalCount,
    required int generalLiberalCount,
    required int majorElectiveCount,
    required UserPreference preference,
  }) {
    final liberalArtsCount =
        coreLiberalCount + balancedLiberalCount + generalLiberalCount;

    if (preference.grade <= 2) {
      final minLiberalCount = preference.maxCredits >= 16 ? 2 : 1;
      final maxLiberalCount = preference.maxCredits >= 18 ? 4 : 3;
      final countScore = _rangeScore(
        value: liberalArtsCount,
        min: minLiberalCount,
        max: maxLiberalCount,
        belowPenalty: 0.32,
        abovePenalty: 0.16,
      );
      final coreShare = liberalArtsCount == 0
          ? 0.0
          : coreLiberalCount / liberalArtsCount;
      final coreFocusScore = liberalArtsCount == 0
          ? 0.35
          : (0.42 + 0.58 * coreShare).clamp(0.0, 1.0);
      final balancedPenalty = balancedLiberalCount <= 1
          ? 1.0
          : (1 - (balancedLiberalCount - 1) * 0.12).clamp(0.55, 1.0);
      final majorProgressScore = majorElectiveCount == 0 ? 0.88 : 1.0;

      return (0.4 * countScore +
              0.36 * coreFocusScore +
              0.14 * balancedPenalty +
              0.1 * majorProgressScore)
          .clamp(0.0, 1.0);
    }

    final maxLiberalCount = preference.grade == 3 ? 2 : 1;
    final countScore = _rangeScore(
      value: liberalArtsCount,
      min: 0,
      max: maxLiberalCount,
      belowPenalty: 0.0,
      abovePenalty: 0.22,
    );
    final balancedFocusScore = switch (balancedLiberalCount) {
      0 => 0.84,
      1 => 1.0,
      2 => 0.95,
      _ => (1 - (balancedLiberalCount - 2) * 0.12).clamp(0.5, 1.0),
    };
    final corePenalty = coreLiberalCount == 0
        ? 1.0
        : (1 - coreLiberalCount * 0.18).clamp(0.45, 1.0);
    final generalPenalty = generalLiberalCount == 0
        ? 1.0
        : (1 - generalLiberalCount * 0.14).clamp(0.55, 1.0);

    return (0.42 * countScore +
            0.24 * balancedFocusScore +
            0.18 * corePenalty +
            0.16 * generalPenalty)
        .clamp(0.0, 1.0);
  }

  double _rangeScore({
    required int value,
    required int min,
    required int max,
    required double belowPenalty,
    required double abovePenalty,
  }) {
    if (value < min) {
      return (1 - (min - value) * belowPenalty).clamp(0.3, 1.0);
    }
    if (value > max) {
      return (1 - (value - max) * abovePenalty).clamp(0.35, 1.0);
    }
    return 1.0;
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
    final categoryPreference = _categoryPreferenceScore(course, preference);

    return (0.22 * ratingScore +
            0.15 * difficultyScore +
            0.18 * inPreferredRangeScore +
            0.1 * lunchCompatibility +
            0.12 * morningBias +
            0.07 * teamScore +
            0.06 * preferredFreeDayPenalty +
            0.1 * categoryPreference)
        .clamp(0.0, 1.0);
  }

  double _categoryPreferenceScore(Course course, UserPreference preference) {
    return switch (course.category) {
      CourseCategory.majorRequired => 1.0,
      CourseCategory.majorElective => preference.grade <= 2 ? 0.88 : 1.0,
      CourseCategory.coreLiberalArts =>
        preference.grade <= 2 ? 1.0 : (preference.grade == 3 ? 0.58 : 0.42),
      CourseCategory.balancedLiberalArts =>
        preference.grade <= 2 ? 0.72 : (preference.grade == 3 ? 0.88 : 0.92),
      CourseCategory.generalElective => preference.grade <= 2 ? 0.52 : 0.64,
    };
  }

  bool _isEligibleCourse(Course course, UserPreference preference) {
    if (!course.hasTimeSlots) {
      return false;
    }
    if (_violatesPreferredFreeDay(course, preference)) {
      return false;
    }
    if (course.category.isMajor) {
      return course.grade == 0 || course.grade == preference.grade;
    }
    return true;
  }

  bool _violatesPreferredFreeDay(Course course, UserPreference preference) =>
      preference.preferredFreeDays.isNotEmpty &&
      course.occursOnAny(preference.preferredFreeDays);

  List<Course>? _resolveSelectedCourses(
    List<Course> eligible,
    Set<String> selectedCourseIds,
    Map<String, double> utilityById,
  ) {
    final selected = eligible
        .where((course) => selectedCourseIds.contains(course.id))
        .toList();
    if (selected.length != selectedCourseIds.length) {
      return null;
    }
    final grouped = <String, List<Course>>{};

    for (final course in selected) {
      grouped.putIfAbsent(course.courseCode, () => []).add(course);
    }

    final resolved =
        grouped.values.map((courses) {
            courses.sort(
              (a, b) => utilityById[b.id]!.compareTo(utilityById[a.id]!),
            );
            return courses.first;
          }).toList()
          ..sort((a, b) => utilityById[b.id]!.compareTo(utilityById[a.id]!));

    return _coursesCompatible(resolved) ? resolved : null;
  }

  List<Course>? _resolveAutomaticRequiredCourses(
    List<Course> allCourses,
    List<Course> eligible,
    List<Course> lockedCourses,
    Map<String, double> utilityById,
    UserPreference preference,
  ) {
    final lockedCourseCodes = lockedCourses
        .map((course) => course.courseCode)
        .toSet();
    final requiredCourseCodes = allCourses
        .where(
          (course) =>
              course.hasTimeSlots &&
              course.category == CourseCategory.majorRequired &&
              course.grade == preference.grade &&
              !lockedCourseCodes.contains(course.courseCode),
        )
        .map((course) => course.courseCode)
        .toSet();
    final grouped = <String, List<Course>>{};

    for (final course in eligible) {
      if (course.category != CourseCategory.majorRequired ||
          course.grade != preference.grade ||
          lockedCourseCodes.contains(course.courseCode)) {
        continue;
      }
      grouped.putIfAbsent(course.courseCode, () => []).add(course);
    }

    if (grouped.isEmpty) {
      return requiredCourseCodes.isEmpty ? [] : null;
    }
    if (!grouped.keys.toSet().containsAll(requiredCourseCodes)) {
      return null;
    }

    final groups = grouped.values.toList()
      ..sort((left, right) {
        final countCompare = left.length.compareTo(right.length);
        if (countCompare != 0) {
          return countCompare;
        }
        final leftBest = left
            .map((course) => utilityById[course.id]!)
            .reduce(max);
        final rightBest = right
            .map((course) => utilityById[course.id]!)
            .reduce(max);
        return rightBest.compareTo(leftBest);
      });

    for (final group in groups) {
      group.sort((a, b) => utilityById[b.id]!.compareTo(utilityById[a.id]!));
    }

    List<Course>? bestSelection;
    double bestScore = -1;
    final current = <Course>[];

    void search(int index, double score) {
      if (index == groups.length) {
        if (score > bestScore) {
          bestScore = score;
          bestSelection = List<Course>.of(current);
        }
        return;
      }

      for (final course in groups[index]) {
        if (_conflictsWithCourseList([...lockedCourses, ...current], course)) {
          continue;
        }

        current.add(course);
        search(index + 1, score + utilityById[course.id]!);
        current.removeLast();
      }
    }

    search(0, 0);
    return bestSelection;
  }

  List<Course> _rebuildWithFixedCourses(
    List<Course> courses,
    List<Course> fixedCourses,
    UserPreference preference,
  ) {
    final fixedIds = fixedCourses.map((course) => course.id).toSet();
    final rebuilt = <Course>[...fixedCourses];
    var currentCredits = _totalCredits(rebuilt);
    final others =
        courses.where((course) => !fixedIds.contains(course.id)).toList()..sort(
          (a, b) => _courseUtility(
            b,
            preference,
          ).compareTo(_courseUtility(a, preference)),
        );

    for (final course in others) {
      if (_canAddCourse(
        rebuilt,
        course,
        preference,
        currentCredits: currentCredits,
      )) {
        rebuilt.add(course);
        currentCredits += course.credit;
      }
    }

    return rebuilt;
  }

  bool _coursesCompatible(List<Course> courses) {
    for (int i = 0; i < courses.length; i++) {
      for (int j = i + 1; j < courses.length; j++) {
        if (_coursesConflict(courses[i], courses[j])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _conflictsWithCourseList(List<Course> courses, Course candidate) {
    for (final course in courses) {
      if (_coursesConflict(course, candidate)) {
        return true;
      }
    }
    return false;
  }

  bool _canAddCourse(
    List<Course> courses,
    Course candidate,
    UserPreference preference, {
    int? currentCredits,
  }) {
    if (_violatesPreferredFreeDay(candidate, preference)) {
      return false;
    }
    if (courses.any((course) => course.id == candidate.id)) {
      return false;
    }
    if (_hasSameCourse(courses, candidate)) {
      return false;
    }
    if (_exceedsLiberalArtsStrategy(courses, candidate, preference)) {
      return false;
    }
    if ((currentCredits ?? _totalCredits(courses)) + candidate.credit >
        preference.maxCredits) {
      return false;
    }
    return !_conflictsWithAny(courses, candidate);
  }

  bool _exceedsLiberalArtsStrategy(
    List<Course> courses,
    Course candidate,
    UserPreference preference,
  ) {
    if (candidate.category.isMajor || preference.grade <= 2) {
      return false;
    }

    final liberalArtsCount = courses
        .where((course) => !course.category.isMajor)
        .length;
    if (liberalArtsCount >= 2) {
      return true;
    }

    if (candidate.category == CourseCategory.coreLiberalArts) {
      final coreCount = courses
          .where((course) => course.category == CourseCategory.coreLiberalArts)
          .length;
      final maxCoreCount = preference.grade == 3 ? 1 : 0;
      if (coreCount >= maxCoreCount) {
        return true;
      }
    }

    return false;
  }

  List<Course> _candidateOrder(
    List<Course> electives, {
    required bool exploratory,
  }) {
    final ordered = List<Course>.of(electives);
    if (ordered.length < 2) {
      return ordered;
    }

    final baseWindow = exploratory ? 18 : 7;
    final maxWindow = exploratory ? 42 : 16;

    for (int index = 0; index < ordered.length; index++) {
      final dynamicWindow = min(
        maxWindow,
        baseWindow + (index ~/ (exploratory ? 3 : 5)),
      );
      final windowSize = min(ordered.length - index, dynamicWindow);
      if (windowSize <= 1) {
        continue;
      }

      final swapIndex = index + _random.nextInt(windowSize);
      final current = ordered[index];
      ordered[index] = ordered[swapIndex];
      ordered[swapIndex] = current;
    }

    return ordered;
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
