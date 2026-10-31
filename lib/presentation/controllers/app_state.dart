import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/haptics/haptic_service.dart';
import '../../core/sound/sound_service.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/course.dart';
import '../../domain/models/doctor_profile.dart';
import '../../domain/models/session.dart';
import '../../domain/models/student.dart';

enum ScanFeedbackType {
  success,        // 1. مسح ناجح ومقيد (أخضر + 880Hz + نبضة خفيفة + درجة 1)
  duplicate,      // 2. تكرار المسح (أصفر + 550Hz + نبضتان + مسجل مسبقاً)
  wrongLocation,  // 3. طالب غير مسجل بالمكان (أحمر + 220Hz + اهتزاز تحذيري قوي + درجة 0)
  manualSuccess,  // 4. تحضير يدوي / عذر (أزرق + نقرة تأكيد + نبضة لطيفة + درجة 1)
}

class ScanResult {
  final ScanFeedbackType type;
  final String academicId;
  final Student? student;
  final String message;
  final String? actualLocation;

  const ScanResult({
    required this.type,
    required this.academicId,
    this.student,
    required this.message,
    this.actualLocation,
  });
}

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final SoundService _sound = SoundService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  DoctorProfile? _doctorProfile;
  DoctorProfile? get doctorProfile => _doctorProfile;

  List<Course> _courses = [];
  List<Course> get courses => _courses;

  List<Session> _sessions = [];
  List<Session> get sessions => _sessions;

  int _totalStudents = 0;
  int get totalStudents => _totalStudents;

  List<String> _uniqueGradeYears = [];
  List<String> get uniqueGradeYears => _uniqueGradeYears;

  List<String> _uniqueDepartments = [];
  List<String> get uniqueDepartments => _uniqueDepartments;

  List<String> _uniqueLocations = [];
  List<String> get uniqueLocations => _uniqueLocations;

  bool get hasImportedStudents => _totalStudents > 0 && _uniqueGradeYears.isNotEmpty;

  // Active Session state
  Session? _activeSession;
  Session? get activeSession => _activeSession;

  Course? _activeCourse;
  Course? get activeCourse => _activeCourse;

  List<AttendanceRecord> _activeSessionRecords = [];
  List<AttendanceRecord> get activeSessionRecords => _activeSessionRecords;

  final Set<String> _presentInSession = <String>{};
  Set<String> get presentInSession => _presentInSession;

  // Fast in-memory cache of student profiles for zero-latency retrieval
  final Map<String, Student> _sessionStudentsCache = <String, Student>{};

  int get activePresentCount => _presentInSession.length;
  int get activeTotalTargetCount => _activeSessionRecords.length;

  // Last feedback result for scanner UI animation
  ScanResult? _lastScanResult;
  ScanResult? get lastScanResult => _lastScanResult;

  DateTime? _lastScanTime;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _sound.init();
    await refreshAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    _doctorProfile = await _db.getDoctorProfile();
    _courses = await _db.getCourses();
    _sessions = await _db.getSessions();
    _totalStudents = await _db.getTotalStudentsCount();
    _uniqueGradeYears = await _db.getAllUniqueGradeYears();
    _uniqueDepartments = await _db.getAllUniqueDepartments();
    _uniqueLocations = await _db.getAllUniqueLocations();
    notifyListeners();
  }

  Future<List<String>> getDepartmentsForGrade(String gradeYear) async {
    return await _db.getAllUniqueDepartments(gradeYear: gradeYear);
  }

  Future<List<String>> getLocationsForCourse({
    required String gradeYear,
    required String department,
  }) async {
    final list = await _db.getAllUniqueLocations(
      gradeYear: gradeYear,
      department: department,
    );
    if (list.isNotEmpty) return list;
    // Fallback to all locations if specific combination has none
    return _uniqueLocations;
  }

  // Doctor Profile
  Future<void> saveDoctorName(String name) async {
    await _db.saveDoctorProfile(name.trim());
    _doctorProfile = await _db.getDoctorProfile();
    notifyListeners();
  }

  // Course Management
  Future<void> addCourse(Course course) async {
    await _db.insertCourse(course);
    _courses = await _db.getCourses();
    notifyListeners();
  }

  Future<void> updateCourse(Course course) async {
    await _db.updateCourse(course);
    _courses = await _db.getCourses();
    notifyListeners();
  }

  Future<void> deleteCourse(int courseId) async {
    await _db.deleteCourse(courseId);
    _courses = await _db.getCourses();
    notifyListeners();
  }

  // Student Import
  Future<int> importStudents(List<Student> students) async {
    final count = await _db.batchInsertStudents(students);
    await refreshAll();
    return count;
  }

  // ---------------- Session Flow ----------------
  Future<Session> launchNewSession({
    required Course course,
    required String sessionType,
    String? location,
  }) async {
    final now = DateTime.now().toIso8601String();
    final newSession = Session(
      courseId: course.courseId!,
      sessionType: sessionType,
      location: location,
      createdAt: now,
      courseName: course.courseName,
    );

    final sessionId = await _db.createSession(newSession);
    final launchedSession = newSession.copyWith(sessionId: sessionId);

    // Filter target students roster based on session type and course/location
    List<Student> targetStudents;
    if (sessionType == 'lecture') {
      // General lecture: students of this grade and department
      targetStudents = await _db.getStudents(
        gradeYear: course.gradeYear,
        department: course.department,
      );
      if (targetStudents.isEmpty) {
        targetStudents = await _db.getStudents(gradeYear: course.gradeYear);
      }
      if (targetStudents.isEmpty) {
        targetStudents = await _db.getStudents();
      }
    } else {
      // Practical / lab: restricted to the selected location
      targetStudents = await _db.getStudents(
        location: location,
        gradeYear: course.gradeYear,
        department: course.department,
      );
      if (targetStudents.isEmpty) {
        targetStudents = await _db.getStudents(location: location);
      }
    }

    // Initialize attendance roster as 'absent'
    await _db.initializeAttendanceRoster(
      sessionId: sessionId,
      targetStudents: targetStudents,
    );

    _activeSession = launchedSession;
    _activeCourse = course;
    _presentInSession.clear();
    _sessionStudentsCache.clear();
    for (final s in targetStudents) {
      _sessionStudentsCache[s.academicId.trim()] = s;
    }
    _lastScanResult = null;
    _lastScanTime = null;

    await loadActiveSessionRecords();
    return launchedSession;
  }

  Future<void> resumeOrLoadSession(Session session) async {
    _activeSession = session;
    _activeCourse = _courses.firstWhere(
      (c) => c.courseId == session.courseId,
      orElse: () => Course(
        courseId: session.courseId,
        courseName: session.courseName ?? 'المقرر',
        gradeYear: '',
        department: '',
        teachingType: 'theory_only',
      ),
    );

    final presents = await _db.getPresentAcademicIdsInSession(session.sessionId!);
    _presentInSession.clear();
    _presentInSession.addAll(presents.map((e) => e.trim()));
    _sessionStudentsCache.clear();
    _lastScanTime = null;
    _lastScanResult = null;

    await loadActiveSessionRecords();
  }

  Future<void> loadActiveSessionRecords() async {
    if (_activeSession == null) return;
    _activeSessionRecords = await _db.getSessionRecords(_activeSession!.sessionId!);
    // Synchronize in-memory set with present students (score > 0)
    for (final rec in _activeSessionRecords) {
      if (rec.score > 0) {
        _presentInSession.add(rec.academicId.trim());
      }
    }
    notifyListeners();
  }

  // ---------------- Real-Time Optical & Manual Scanner Logic ----------------
  Future<ScanResult> processScan(String rawAcademicId) async {
    final academicId = rawAcademicId.trim();
    if (academicId.isEmpty || _activeSession == null) {
      return ScanResult(
        type: ScanFeedbackType.wrongLocation,
        academicId: academicId,
        message: 'كود غير صالح',
      );
    }

    // Debounce duplicate scans within 1.8s for the same barcode to prevent sensor flicker
    final now = DateTime.now();
    if (_lastScanTime != null &&
        _lastScanResult?.academicId == academicId &&
        now.difference(_lastScanTime!).inMilliseconds < 1800) {
      return _lastScanResult!;
    }
    _lastScanTime = now;

    // 1. Instant O(1) Memory Check: Is student already present in this active session?
    if (_presentInSession.contains(academicId)) {
      Student? student = _sessionStudentsCache[academicId];
      student ??= await _db.getStudentById(academicId);
      if (student != null) {
        _sessionStudentsCache[academicId] = student;
      }

      final result = ScanResult(
        type: ScanFeedbackType.duplicate,
        academicId: academicId,
        student: student,
        message: 'الطالب مسجل بالفعل في هذه الجلسة',
      );
      _lastScanResult = result;
      notifyListeners();

      // Audio & Haptic Feedback 2: 550Hz alert tone + double medium haptic
      await _sound.playDuplicateAlert();
      await HapticService.doubleMediumFeedback();
      return result;
    }

    // 2. Query student from in-memory cache or immediate local SQLite Students table
    Student? student = _sessionStudentsCache[academicId];
    student ??= await _db.getStudentById(academicId);
    if (student != null) {
      _sessionStudentsCache[academicId] = student;
    }

    // If student not found in roster
    if (student == null) {
      final result = ScanResult(
        type: ScanFeedbackType.wrongLocation,
        academicId: academicId,
        message: 'طالب غير مقيد في هذا المكان / المقرر',
      );
      _lastScanResult = result;
      notifyListeners();

      await _sound.playWrongLocationBuzz();
      await HapticService.strongWarningFeedback();
      return result;
    }

    // 3. Location Check (التحقق من مطابقة الطالب للمكان المخصص)
    final sessionLoc = _activeSession!.location?.trim();
    final bool isPractical = _activeSession!.isLabPractical || _activeSession!.isLabTheory;

    if (isPractical && sessionLoc != null && sessionLoc.isNotEmpty) {
      if (student.location.trim().toLowerCase() != sessionLoc.toLowerCase()) {
        final result = ScanResult(
          type: ScanFeedbackType.wrongLocation,
          academicId: academicId,
          student: student,
          actualLocation: student.location,
          message: 'طالب غير مقيد في هذا المكان / المقرر (مكانه: ${student.location})',
        );
        _lastScanResult = result;
        notifyListeners();

        // Audio & Haptic Feedback 3: 220Hz buzz + strong warning haptic
        await _sound.playWrongLocationBuzz();
        await HapticService.strongWarningFeedback();
        return result;
      }
    }

    // 4. Valid Scan (مسح ناجح ومقيد)
    _presentInSession.add(academicId);
    await _db.recordAttendance(
      sessionId: _activeSession!.sessionId!,
      academicId: academicId,
      status: 'present',
      score: 1,
    );

    await loadActiveSessionRecords();

    final result = ScanResult(
      type: ScanFeedbackType.success,
      academicId: academicId,
      student: student,
      message: student.fullName,
    );
    _lastScanResult = result;
    notifyListeners();

    // Audio & Haptic Feedback 1: Beep 880Hz + Light haptic
    await _sound.playSuccessBeep();
    await HapticService.lightFeedback();

    return result;
  }

  // 4. Manual Attendance / Excuse (تحضير يدوي / عذر)
  Future<ScanResult> markManualAttendance({
    required String academicId,
    required bool isExcused,
    String? note,
  }) async {
    final student = await _db.getStudentById(academicId);
    final status = isExcused ? 'excused' : 'present';

    _presentInSession.add(academicId);
    await _db.recordAttendance(
      sessionId: _activeSession!.sessionId!,
      academicId: academicId,
      status: status,
      score: 1,
      notes: note ?? (isExcused ? 'عذر مقبول' : 'تحضير يدوي'),
    );

    await loadActiveSessionRecords();

    final result = ScanResult(
      type: ScanFeedbackType.manualSuccess,
      academicId: academicId,
      student: student,
      message: isExcused ? 'تم رصد الحضور (بعذر مقبول)' : 'تم التحضير اليدوي',
    );
    _lastScanResult = result;
    notifyListeners();

    // Audio & Haptic Feedback 4: Soft Click + Gentle pulse
    await _sound.playManualConfirmClick();
    await HapticService.gentlePulseFeedback();

    return result;
  }

  Future<void> removeAttendance(String academicId) async {
    _presentInSession.remove(academicId);
    await _db.recordAttendance(
      sessionId: _activeSession!.sessionId!,
      academicId: academicId,
      status: 'absent',
      score: 0,
      notes: 'تم إلغاء الرصد',
    );
    await loadActiveSessionRecords();
    notifyListeners();
  }

  Future<void> endActiveSession() async {
    _activeSession = null;
    _activeCourse = null;
    _presentInSession.clear();
    _sessionStudentsCache.clear();
    _activeSessionRecords.clear();
    _lastScanResult = null;
    _lastScanTime = null;
    await refreshAll();
  }

  Future<void> deleteSession(int sessionId) async {
    await _db.deleteSession(sessionId);
    await refreshAll();
  }
}
