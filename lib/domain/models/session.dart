class Session {
  final int? sessionId;
  final int courseId;
  final String sessionType; // 'lecture' | 'lab_theory' | 'lab_practical'
  final String? location;
  final String createdAt;

  // Joined/calculated fields for UI
  final String? courseName;
  final int? totalStudentsCount;
  final int? presentCount;

  const Session({
    this.sessionId,
    required this.courseId,
    required this.sessionType,
    this.location,
    required this.createdAt,
    this.courseName,
    this.totalStudentsCount,
    this.presentCount,
  });

  bool get isLecture => sessionType == 'lecture';
  bool get isLabPractical => sessionType == 'lab_practical';
  bool get isLabTheory => sessionType == 'lab_theory';

  String get sessionTypeArabic {
    switch (sessionType) {
      case 'lecture':
        return 'محاضرة نظري عامة';
      case 'theory':
        return 'محاضرة نظري';
      case 'lab_practical':
        return 'درس عملي - تطبيقي';
      case 'practical':
        return 'درس عملي';
      case 'lab_theory':
        return 'سكشن نظري';
      default:
        return 'جلسة حضور';
    }
  }

  double get attendancePercentage {
    if (totalStudentsCount == null || totalStudentsCount == 0) return 0.0;
    return ((presentCount ?? 0) / totalStudentsCount!) * 100.0;
  }

  Map<String, dynamic> toMap() {
    return {
      if (sessionId != null) 'session_id': sessionId,
      'course_id': courseId,
      'session_type': sessionType,
      'location': location,
      'created_at': createdAt,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      sessionId: map['session_id'] as int?,
      courseId: map['course_id'] as int,
      sessionType: map['session_type'] as String,
      location: map['location'] as String?,
      createdAt: map['created_at'] as String,
      courseName: map['course_name'] as String?,
      totalStudentsCount: map['total_students'] as int?,
      presentCount: map['present_count'] as int?,
    );
  }

  Session copyWith({
    int? sessionId,
    int? courseId,
    String? sessionType,
    String? location,
    String? createdAt,
    String? courseName,
    int? totalStudentsCount,
    int? presentCount,
  }) {
    return Session(
      sessionId: sessionId ?? this.sessionId,
      courseId: courseId ?? this.courseId,
      sessionType: sessionType ?? this.sessionType,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      courseName: courseName ?? this.courseName,
      totalStudentsCount: totalStudentsCount ?? this.totalStudentsCount,
      presentCount: presentCount ?? this.presentCount,
    );
  }
}
