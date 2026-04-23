class TimeSlot {
  final String day; // 월화수목금
  final int startHour;
  final int endHour;

  const TimeSlot({required this.day, required this.startHour, required this.endHour});

  bool conflictsWith(TimeSlot other) =>
      day == other.day && startHour < other.endHour && endHour > other.startHour;

  /// 교시 문자열 (예: 9:00~12:00)
  String get timeLabel => '${startHour.toString().padLeft(2, '0')}:00 ~ ${endHour.toString().padLeft(2, '0')}:00';

  Map<String, dynamic> toJson() => {'day': day, 'startHour': startHour, 'endHour': endHour};
  factory TimeSlot.fromJson(Map<String, dynamic> j) =>
      TimeSlot(day: j['day'], startHour: j['startHour'], endHour: j['endHour']);
}

class Course {
  final String id;
  final String name;
  final String professor;
  final int credit;
  final double rating; // 0~5
  final int difficulty; // 1~5
  final bool hasTeamProject;
  final bool isMajorRequired;
  final int grade; // 대상 학년
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

  /// 과목 코드 (분반 제외)
  String get courseCode => id.split('-').first;

  /// 분반
  String get section => id.split('-').last;

  /// 시간표 요약 문자열 (예: 월9~12, 수13~16)
  String get timeSummary => timeSlots.map((s) => '${s.day} ${s.startHour}~${s.endHour}').join(', ');

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
        'timeSlots': timeSlots.map((t) => t.toJson()).toList(),
      };

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'],
        name: j['name'],
        professor: j['professor'],
        credit: j['credit'],
        rating: (j['rating'] as num).toDouble(),
        difficulty: j['difficulty'],
        hasTeamProject: j['hasTeamProject'],
        isMajorRequired: j['isMajorRequired'],
        grade: j['grade'] ?? 0,
        timeSlots: (j['timeSlots'] as List).map((t) => TimeSlot.fromJson(t)).toList(),
      );
}
