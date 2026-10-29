class Student {
  final String academicId; // PRIMARY KEY
  final String fullName;
  final String gradeYear;
  final String department;
  final String location; // المكان المخصص (مدرج 1, معمل برمجة أ, معمل شبكات ب)

  const Student({
    required this.academicId,
    required this.fullName,
    required this.gradeYear,
    required this.department,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'academic_id': academicId,
      'full_name': fullName,
      'grade_year': gradeYear,
      'department': department,
      'location': location,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      academicId: (map['academic_id'] ?? '').toString().trim(),
      fullName: (map['full_name'] ?? '').toString().trim(),
      gradeYear: (map['grade_year'] ?? '').toString().trim(),
      department: (map['department'] ?? '').toString().trim(),
      location: (map['location'] ?? '').toString().trim(),
    );
  }

  Student copyWith({
    String? academicId,
    String? fullName,
    String? gradeYear,
    String? department,
    String? location,
  }) {
    return Student(
      academicId: academicId ?? this.academicId,
      fullName: fullName ?? this.fullName,
      gradeYear: gradeYear ?? this.gradeYear,
      department: department ?? this.department,
      location: location ?? this.location,
    );
  }
}
