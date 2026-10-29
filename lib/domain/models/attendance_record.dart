class AttendanceRecord {
  final int? recordId;
  final int sessionId;
  final String academicId;
  final String status; // 'present' | 'absent' | 'excused'
  final String? scanTimestamp;
  final String? notes;
  final int score; // 1 or 0

  // Joined student data for views and export
  final String? studentName;
  final String? studentLocation;
  final String? gradeYear;
  final String? department;

  const AttendanceRecord({
    this.recordId,
    required this.sessionId,
    required this.academicId,
    required this.status,
    this.scanTimestamp,
    this.notes,
    this.score = 0,
    this.studentName,
    this.studentLocation,
    this.gradeYear,
    this.department,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isExcused => status == 'excused';

  String get statusArabic {
    switch (status) {
      case 'present':
        return 'حاضر';
      case 'excused':
        return 'حاضر (عذر)';
      case 'absent':
      default:
        return 'غائب';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (recordId != null) 'record_id': recordId,
      'session_id': sessionId,
      'academic_id': academicId,
      'status': status,
      'scan_timestamp': scanTimestamp,
      'notes': notes,
      'score': score,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      recordId: map['record_id'] as int?,
      sessionId: map['session_id'] as int,
      academicId: (map['academic_id'] ?? '').toString(),
      status: map['status'] as String? ?? 'absent',
      scanTimestamp: map['scan_timestamp'] as String?,
      notes: map['notes'] as String?,
      score: map['score'] as int? ?? 0,
      studentName: map['full_name'] as String?,
      studentLocation: map['location'] as String?,
      gradeYear: map['grade_year'] as String?,
      department: map['department'] as String?,
    );
  }

  AttendanceRecord copyWith({
    int? recordId,
    int? sessionId,
    String? academicId,
    String? status,
    String? scanTimestamp,
    String? notes,
    int? score,
    String? studentName,
    String? studentLocation,
    String? gradeYear,
    String? department,
  }) {
    return AttendanceRecord(
      recordId: recordId ?? this.recordId,
      sessionId: sessionId ?? this.sessionId,
      academicId: academicId ?? this.academicId,
      status: status ?? this.status,
      scanTimestamp: scanTimestamp ?? this.scanTimestamp,
      notes: notes ?? this.notes,
      score: score ?? this.score,
      studentName: studentName ?? this.studentName,
      studentLocation: studentLocation ?? this.studentLocation,
      gradeYear: gradeYear ?? this.gradeYear,
      department: department ?? this.department,
    );
  }
}
