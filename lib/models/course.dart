const weekdays = ['월', '화', '수', '목', '금'];

enum CourseCategory {
  majorRequired,
  majorElective,
  coreLiberalArts,
  generalElective,
}

enum RatingSource { officialEstimate, userInput, reviewBacked }

extension CourseCategoryX on CourseCategory {
  String get label => switch (this) {
    CourseCategory.majorRequired => '전공필수',
    CourseCategory.majorElective => '전공선택',
    CourseCategory.coreLiberalArts => '핵심교양',
    CourseCategory.generalElective => '일반교양',
  };

  bool get isMajor => switch (this) {
    CourseCategory.majorRequired || CourseCategory.majorElective => true,
    CourseCategory.coreLiberalArts || CourseCategory.generalElective => false,
  };
}

extension RatingSourceX on RatingSource {
  String get label => switch (this) {
    RatingSource.officialEstimate => '공식 추정',
    RatingSource.userInput => '사용자 입력',
    RatingSource.reviewBacked => '실제 리뷰 반영',
  };

  String get description => switch (this) {
    RatingSource.officialEstimate => '공개 강의 자료와 과목 성격을 바탕으로 추정한 평점입니다.',
    RatingSource.userInput => '사용자가 직접 입력한 평점입니다.',
    RatingSource.reviewBacked => '실제 강의 리뷰를 반영한 평점입니다.',
  };
}

CourseCategory _courseCategoryFromJson(
  Object? value, {
  required bool isMajorRequired,
}) {
  final categoryName = value as String?;
  return switch (categoryName) {
    'majorRequired' => CourseCategory.majorRequired,
    'majorElective' => CourseCategory.majorElective,
    'coreLiberalArts' => CourseCategory.coreLiberalArts,
    'generalElective' => CourseCategory.generalElective,
    _ =>
      isMajorRequired
          ? CourseCategory.majorRequired
          : CourseCategory.majorElective,
  };
}

RatingSource _ratingSourceFromJson(Object? value) {
  final sourceName = value as String?;
  return switch (sourceName) {
    'officialEstimate' => RatingSource.officialEstimate,
    'userInput' => RatingSource.userInput,
    'reviewBacked' => RatingSource.reviewBacked,
    _ => RatingSource.officialEstimate,
  };
}

class TimeSlot {
  final String day;
  final int startHour;
  final int endHour;

  const TimeSlot({
    required this.day,
    required this.startHour,
    required this.endHour,
  });

  int get durationHours => endHour - startHour;

  bool conflictsWith(TimeSlot other) =>
      day == other.day &&
      startHour < other.endHour &&
      endHour > other.startHour;

  String get timeLabel =>
      '${startHour.toString().padLeft(2, '0')}:00 ~ ${endHour.toString().padLeft(2, '0')}:00';

  Map<String, dynamic> toJson() => {
    'day': day,
    'startHour': startHour,
    'endHour': endHour,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    day: json['day'] as String,
    startHour: json['startHour'] as int,
    endHour: json['endHour'] as int,
  );
}

class Course {
  final String id;
  final String name;
  final String professor;
  final int credit;
  final double rating;
  final int difficulty;
  final bool hasTeamProject;
  final bool isMajorRequired;
  final CourseCategory category;
  final RatingSource ratingSource;
  final int grade;
  final List<TimeSlot> timeSlots;

  const Course({
    required this.id,
    required this.name,
    required this.professor,
    required this.credit,
    required this.rating,
    required this.difficulty,
    required this.hasTeamProject,
    required this.isMajorRequired,
    CourseCategory? category,
    RatingSource? ratingSource,
    this.grade = 0,
    required this.timeSlots,
  }) : category =
           category ??
           (isMajorRequired
               ? CourseCategory.majorRequired
               : CourseCategory.majorElective),
       ratingSource = ratingSource ?? RatingSource.officialEstimate;

  String get courseCode => id.split('-').first;

  String get section => id.split('-').last;

  int get totalHours =>
      timeSlots.fold(0, (sum, slot) => sum + slot.durationHours);

  Set<String> get activeDays => timeSlots.map((slot) => slot.day).toSet();

  bool get hasTimeSlots => timeSlots.isNotEmpty;

  int get earliestStartHour => timeSlots.isEmpty
      ? 0
      : timeSlots
            .map((slot) => slot.startHour)
            .reduce((value, element) => value < element ? value : element);

  int get latestEndHour => timeSlots.isEmpty
      ? 0
      : timeSlots
            .map((slot) => slot.endHour)
            .reduce((value, element) => value > element ? value : element);

  bool get isCoreLiberalArts => category == CourseCategory.coreLiberalArts;

  bool occursOn(String day) => timeSlots.any((slot) => slot.day == day);

  String get categoryLabel => category.label;

  String get ratingSourceLabel => ratingSource.label;

  String get timeSummary => timeSlots.isEmpty
      ? '\uc2dc\uac04\ud45c \ubbf8\uc9c0\uc815'
      : timeSlots
            .map((slot) => '${slot.day} ${slot.startHour}~${slot.endHour}')
            .join(', ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'professor': professor,
    'credit': credit,
    'rating': rating,
    'difficulty': difficulty,
    'hasTeamProject': hasTeamProject,
    'isMajorRequired': isMajorRequired,
    'category': category.name,
    'ratingSource': ratingSource.name,
    'grade': grade,
    'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    final isMajorRequired = json['isMajorRequired'] as bool? ?? false;
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      professor: json['professor'] as String,
      credit: json['credit'] as int,
      rating: (json['rating'] as num).toDouble(),
      difficulty: json['difficulty'] as int,
      hasTeamProject: json['hasTeamProject'] as bool,
      isMajorRequired: isMajorRequired,
      category: _courseCategoryFromJson(
        json['category'],
        isMajorRequired: isMajorRequired,
      ),
      ratingSource: _ratingSourceFromJson(json['ratingSource']),
      grade: json['grade'] as int? ?? 0,
      timeSlots: (json['timeSlots'] as List)
          .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
          .toList(),
    );
  }
}
