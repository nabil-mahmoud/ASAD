import 'student.dart';

class CumulativeStudentReport {
  final String academicId;
  final String fullName;
  final String? location;
  final String gradeYear;
  final String department;
  final int totalCourseSessions;
  final int attendedSessions;
  final int absentSessions;
  final int excusedSessions;
  final int totalScore;
  final double attendancePercentage;
  final Map<int, int> sessionScores; // sessionId -> score (1 or 0)
  final Map<int, String> sessionStatuses; // sessionId -> status ('present', 'absent', 'excused')

  const CumulativeStudentReport({
    required this.academicId,
    required this.fullName,
    this.location,
    required this.gradeYear,
    required this.department,
    required this.totalCourseSessions,
    required this.attendedSessions,
    required this.absentSessions,
    required this.excusedSessions,
    required this.totalScore,
    required this.attendancePercentage,
    this.sessionScores = const {},
    this.sessionStatuses = const {},
  });

  bool get isAtRisk => totalCourseSessions > 0 && attendancePercentage < 75.0;
  bool get isDeprived => totalCourseSessions >= 3 && attendancePercentage < 50.0;

  String get statusTag {
    if (totalCourseSessions == 0) return 'لا توجد جلسات';
    if (attendancePercentage >= 85.0) return 'ممتاز';
    if (attendancePercentage >= 75.0) return 'منتظم';
    if (attendancePercentage >= 50.0) return 'منذر بالحرمان';
    return 'محروم';
  }

  factory CumulativeStudentReport.fromAggregation({
    required Student student,
    required int totalCourseSessions,
    required List<Map<String, dynamic>> records,
  }) {
    int attended = 0;
    int absent = 0;
    int excused = 0;
    int scoreSum = 0;
    final Map<int, int> scores = {};
    final Map<int, String> statuses = {};

    for (final r in records) {
      final sessionId = r['session_id'] as int;
      final status = (r['status'] as String?) ?? 'absent';
      final score = (r['score'] as int?) ?? 0;

      scores[sessionId] = score;
      statuses[sessionId] = status;
      scoreSum += score;

      if (status == 'present') {
        attended++;
      } else if (status == 'excused') {
        excused++;
      } else {
        absent++;
      }
    }

    // Any remaining sessions the student had no record for are counted as absent
    final recordedSessionsCount = records.length;
    if (totalCourseSessions > recordedSessionsCount) {
      absent += (totalCourseSessions - recordedSessionsCount);
    }

    final pct = totalCourseSessions > 0
        ? ((attended + excused) / totalCourseSessions) * 100.0
        : 0.0;

    return CumulativeStudentReport(
      academicId: student.academicId,
      fullName: student.fullName,
      location: student.location,
      gradeYear: student.gradeYear,
      department: student.department,
      totalCourseSessions: totalCourseSessions,
      attendedSessions: attended,
      absentSessions: absent,
      excusedSessions: excused,
      totalScore: scoreSum,
      attendancePercentage: pct,
      sessionScores: scores,
      sessionStatuses: statuses,
    );
  }
}

