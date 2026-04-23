class UserPreference {
  final String major;
  final int grade;
  final int maxCredits;
  final bool preferMorning;
  final double freeTimeWeight;
  final double ratingWeight;
  final double difficultyWeight;
  final bool avoidTeamProject;
  final List<String> requiredCourseIds;
  // 시간 제약 (Where-Got-TimeTable 참조)
  final int minStartHour;         // 수업 최소 시작 시간 (9~11)
  final int maxEndHour;           // 수업 최대 종료 시간 (18~21)
  final List<String> preferredFreeDays; // 공강 희망 요일 (하드 제약)
  final bool requireLunchBreak;   // 점심시간(12~13) 확보

  const UserPreference({
    required this.major,
    required this.grade,
    this.maxCredits = 18,
    this.preferMorning = false,
    this.freeTimeWeight = 0.4,
    this.ratingWeight = 0.3,
    this.difficultyWeight = 0.2,
    this.avoidTeamProject = false,
    this.requiredCourseIds = const [],
    this.minStartHour = 9,
    this.maxEndHour = 20,
    this.preferredFreeDays = const [],
    this.requireLunchBreak = false,
  });

  UserPreference copyWith({
    String? major,
    int? grade,
    int? maxCredits,
    bool? preferMorning,
    double? freeTimeWeight,
    double? ratingWeight,
    double? difficultyWeight,
    bool? avoidTeamProject,
    List<String>? requiredCourseIds,
    int? minStartHour,
    int? maxEndHour,
    List<String>? preferredFreeDays,
    bool? requireLunchBreak,
  }) =>
      UserPreference(
        major: major ?? this.major,
        grade: grade ?? this.grade,
        maxCredits: maxCredits ?? this.maxCredits,
        preferMorning: preferMorning ?? this.preferMorning,
        freeTimeWeight: freeTimeWeight ?? this.freeTimeWeight,
        ratingWeight: ratingWeight ?? this.ratingWeight,
        difficultyWeight: difficultyWeight ?? this.difficultyWeight,
        avoidTeamProject: avoidTeamProject ?? this.avoidTeamProject,
        requiredCourseIds: requiredCourseIds ?? this.requiredCourseIds,
        minStartHour: minStartHour ?? this.minStartHour,
        maxEndHour: maxEndHour ?? this.maxEndHour,
        preferredFreeDays: preferredFreeDays ?? this.preferredFreeDays,
        requireLunchBreak: requireLunchBreak ?? this.requireLunchBreak,
      );
}
