class Course {
  final int? courseId;
  final String courseName;
  final String gradeYear;
  final String department;
  final String teachingType; // 'theory_only' | 'theory_and_practical'

  const Course({
    this.courseId,
    required this.courseName,
    required this.gradeYear,
    required this.department,
    required this.teachingType,
  });

  bool get isTheoryOnly => teachingType == 'theory_only';
  bool get hasPractical => teachingType == 'theory_and_practical';

  String get teachingTypeArabic =>
      isTheoryOnly ? 'نظري فقط' : 'نظري + عملي';

  Map<String, dynamic> toMap() {
    return {
      if (courseId != null) 'course_id': courseId,
      'course_name': courseName,
      'grade_year': gradeYear,
      'department': department,
      'teaching_type': teachingType,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      courseId: map['course_id'] as int?,
      courseName: map['course_name'] as String,
      gradeYear: map['grade_year'] as String,
      department: map['department'] as String,
      teachingType: map['teaching_type'] as String,
    );
  }

  Course copyWith({
    int? courseId,
    String? courseName,
    String? gradeYear,
    String? department,
    String? teachingType,
  }) {
    return Course(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      gradeYear: gradeYear ?? this.gradeYear,
      department: department ?? this.department,
      teachingType: teachingType ?? this.teachingType,
    );
  }
}
