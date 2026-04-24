class User {
  final String id;
  final String email;
  final String name;
  final String studentId; // 학번
  final String department; // 학과
  final int grade;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.studentId,
    required this.department,
    required this.grade,
    required this.createdAt,
  });

  User copyWith({
    String? name,
    String? studentId,
    String? department,
    int? grade,
  }) => User(
    id: id,
    email: email,
    name: name ?? this.name,
    studentId: studentId ?? this.studentId,
    department: department ?? this.department,
    grade: grade ?? this.grade,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'studentId': studentId,
    'department': department,
    'grade': grade,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String,
    email: j['email'] as String,
    name: j['name'] as String,
    studentId: j['studentId'] as String,
    department: j['department'] as String,
    grade: j['grade'] as int,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  /// 이니셜 (아바타용): 이름 첫글자
  String get initial => name.isEmpty ? '?' : name.substring(0, 1);
}
