const weekdays = ['월', '화', '수', '목', '금'];

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
    this.grade = 0,
    required this.timeSlots,
  });

  String get courseCode => id.split('-').first;

  String get section => id.split('-').last;

  int get totalHours =>
      timeSlots.fold(0, (sum, slot) => sum + slot.durationHours);

  Set<String> get activeDays => timeSlots.map((slot) => slot.day).toSet();

  int get earliestStartHour => timeSlots
      .map((slot) => slot.startHour)
      .reduce((value, element) => value < element ? value : element);

  int get latestEndHour => timeSlots
      .map((slot) => slot.endHour)
      .reduce((value, element) => value > element ? value : element);

  bool occursOn(String day) => timeSlots.any((slot) => slot.day == day);

  String get timeSummary => timeSlots
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
    'grade': grade,
    'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
  };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as String,
    name: json['name'] as String,
    professor: json['professor'] as String,
    credit: json['credit'] as int,
    rating: (json['rating'] as num).toDouble(),
    difficulty: json['difficulty'] as int,
    hasTeamProject: json['hasTeamProject'] as bool,
    isMajorRequired: json['isMajorRequired'] as bool,
    grade: json['grade'] as int? ?? 0,
    timeSlots: (json['timeSlots'] as List)
        .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
        .toList(),
  );
}
