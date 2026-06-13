class User {
  final String id;
  final String email;
  final String name;
  final String studentId; // 학번
  final String department; // 학과
  final int grade;
  final bool profileComplete;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.studentId,
    required this.department,
    required this.grade,
    this.profileComplete = true,
    required this.createdAt,
  });

  User copyWith({
    String? name,
    String? studentId,
    String? department,
    int? grade,
    bool? profileComplete,
  }) => User(
    id: id,
    email: email,
    name: name ?? this.name,
    studentId: studentId ?? this.studentId,
    department: department ?? this.department,
    grade: grade ?? this.grade,
    profileComplete: profileComplete ?? this.profileComplete,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'studentId': studentId,
    'department': department,
    'grade': grade,
    'profileComplete': profileComplete,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as String,
    email: j['email'] as String,
    name: j['name'] as String,
    studentId: j['studentId'] as String? ?? '',
    department: j['department'] as String? ?? '',
    grade: (j['grade'] as num?)?.toInt() ?? 1,
    profileComplete: j['profileComplete'] as bool? ?? true,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  /// 아바타나 배지에 표시할 이름 첫 글자입니다.
  bool get hasRequiredProfile =>
      name.trim().isNotEmpty &&
      studentId.trim().isNotEmpty &&
      department.trim().isNotEmpty &&
      grade >= 1 &&
      grade <= 4;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1);
}
