class UserPreference {
  final String major;
  final int grade;
  final int maxCredits;
  final bool preferMorning;
  final double freeTimeWeight;
  final double ratingWeight;
  final double difficultyWeight;
  final bool avoidTeamProject;
  final List<String> selectedMajorCourseIds;
  final List<String> selectedLiberalArtsCourseIds;
  final int minStartHour;
  final int maxEndHour;
  final List<String> preferredFreeDays;
  final bool requireLunchBreak;

  const UserPreference({
    required this.major,
    required this.grade,
    this.maxCredits = 18,
    this.preferMorning = false,
    this.freeTimeWeight = 0.4,
    this.ratingWeight = 0.3,
    this.difficultyWeight = 0.2,
    this.avoidTeamProject = false,
    this.selectedMajorCourseIds = const [],
    this.selectedLiberalArtsCourseIds = const [],
    this.minStartHour = 9,
    this.maxEndHour = 20,
    this.preferredFreeDays = const [],
    this.requireLunchBreak = false,
  });

  List<String> get selectedCourseIds => [
    ...selectedMajorCourseIds,
    ...selectedLiberalArtsCourseIds,
  ];

  UserPreference copyWith({
    String? major,
    int? grade,
    int? maxCredits,
    bool? preferMorning,
    double? freeTimeWeight,
    double? ratingWeight,
    double? difficultyWeight,
    bool? avoidTeamProject,
    List<String>? selectedMajorCourseIds,
    List<String>? selectedLiberalArtsCourseIds,
    int? minStartHour,
    int? maxEndHour,
    List<String>? preferredFreeDays,
    bool? requireLunchBreak,
  }) => UserPreference(
    major: major ?? this.major,
    grade: grade ?? this.grade,
    maxCredits: maxCredits ?? this.maxCredits,
    preferMorning: preferMorning ?? this.preferMorning,
    freeTimeWeight: freeTimeWeight ?? this.freeTimeWeight,
    ratingWeight: ratingWeight ?? this.ratingWeight,
    difficultyWeight: difficultyWeight ?? this.difficultyWeight,
    avoidTeamProject: avoidTeamProject ?? this.avoidTeamProject,
    selectedMajorCourseIds:
        selectedMajorCourseIds ?? this.selectedMajorCourseIds,
    selectedLiberalArtsCourseIds:
        selectedLiberalArtsCourseIds ?? this.selectedLiberalArtsCourseIds,
    minStartHour: minStartHour ?? this.minStartHour,
    maxEndHour: maxEndHour ?? this.maxEndHour,
    preferredFreeDays: preferredFreeDays ?? this.preferredFreeDays,
    requireLunchBreak: requireLunchBreak ?? this.requireLunchBreak,
  );
}
