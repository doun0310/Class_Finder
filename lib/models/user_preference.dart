class UserPreference {
  final String major;
  final int grade;
  final int maxCredits; // 최대 학점 (기본 21)
  final bool preferMorning; // 오전 선호
  final double freeTimeWeight; // 공강 가중치 0~1
  final double ratingWeight;
  final double difficultyWeight;
  final double teamProjectWeight;
  final bool avoidTeamProject;
  final List<String> requiredCourseIds;

  const UserPreference({
    required this.major,
    required this.grade,
    this.maxCredits = 21,
    this.preferMorning = false,
    this.freeTimeWeight = 0.4,
    this.ratingWeight = 0.3,
    this.difficultyWeight = 0.2,
    this.teamProjectWeight = 0.1,
    this.avoidTeamProject = false,
    this.requiredCourseIds = const [],
  });

  UserPreference copyWith({
    String? major,
    int? grade,
    int? maxCredits,
    bool? preferMorning,
    double? freeTimeWeight,
    double? ratingWeight,
    double? difficultyWeight,
    double? teamProjectWeight,
    bool? avoidTeamProject,
    List<String>? requiredCourseIds,
  }) =>
      UserPreference(
        major: major ?? this.major,
        grade: grade ?? this.grade,
        maxCredits: maxCredits ?? this.maxCredits,
        preferMorning: preferMorning ?? this.preferMorning,
        freeTimeWeight: freeTimeWeight ?? this.freeTimeWeight,
        ratingWeight: ratingWeight ?? this.ratingWeight,
        difficultyWeight: difficultyWeight ?? this.difficultyWeight,
        teamProjectWeight: teamProjectWeight ?? this.teamProjectWeight,
        avoidTeamProject: avoidTeamProject ?? this.avoidTeamProject,
        requiredCourseIds: requiredCourseIds ?? this.requiredCourseIds,
      );
}
