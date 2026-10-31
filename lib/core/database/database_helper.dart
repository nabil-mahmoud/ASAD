import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models/doctor_profile.dart';
import '../../domain/models/course.dart';
import '../../domain/models/student.dart';
import '../../domain/models/session.dart';
import '../../domain/models/attendance_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Enable FFI on macOS, Linux, and Windows desktop
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (kIsWeb) {
      dbPath = 'asad_local.db';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = join(docsDir.path, 'asad_attendance.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Doctor Profile Table
    await db.execute('''
      CREATE TABLE Doctor_Profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        doctor_name TEXT NOT NULL
      );
    ''');

    // 2. Courses Table
    await db.execute('''
      CREATE TABLE Courses (
        course_id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_name TEXT NOT NULL,
        grade_year TEXT NOT NULL,
        department TEXT NOT NULL,
        teaching_type TEXT CHECK(teaching_type IN ('theory_only', 'theory_and_practical'))
      );
    ''');

    // 3. Students Table & Location Index
    await db.execute('''
      CREATE TABLE Students (
        academic_id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        grade_year TEXT NOT NULL,
        department TEXT NOT NULL,
        location TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE INDEX idx_student_location ON Students(location);
    ''');

    // 4. Sessions Table
    await db.execute('''
      CREATE TABLE Sessions (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        session_type TEXT CHECK(session_type IN ('lecture', 'lab_theory', 'lab_practical')),
        location TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (course_id) REFERENCES Courses (course_id) ON DELETE CASCADE
      );
    ''');

    // 5. Attendance Records Table & Unique Index
    await db.execute('''
      CREATE TABLE Attendance_Records (
        record_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        academic_id TEXT NOT NULL,
        status TEXT CHECK(status IN ('present', 'absent', 'excused')),
        scan_timestamp DATETIME,
        notes TEXT,
        score INTEGER DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES Sessions (session_id) ON DELETE CASCADE,
        FOREIGN KEY (academic_id) REFERENCES Students (academic_id)
      );
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_unique_attendance ON Attendance_Records(session_id, academic_id);
    ''');
  }

  // ---------------- Doctor Profile Operations ----------------
  Future<DoctorProfile?> getDoctorProfile() async {
    final db = await database;
    final res = await db.query('Doctor_Profile', limit: 1);
    if (res.isNotEmpty) {
      return DoctorProfile.fromMap(res.first);
    }
    return null;
  }

  Future<void> saveDoctorProfile(String name) async {
    final db = await database;
    final current = await getDoctorProfile();
    if (current == null) {
      await db.insert('Doctor_Profile', {'doctor_name': name});
    } else {
      await db.update(
        'Doctor_Profile',
        {'doctor_name': name},
        where: 'id = ?',
        whereArgs: [current.id],
      );
    }
  }

  // ---------------- Courses Operations ----------------
  Future<List<Course>> getCourses() async {
    final db = await database;
    final res = await db.query('Courses', orderBy: 'course_id DESC');
    return res.map((m) => Course.fromMap(m)).toList();
  }

  Future<int> insertCourse(Course course) async {
    final db = await database;
    return await db.insert('Courses', course.toMap());
  }

  Future<int> updateCourse(Course course) async {
    final db = await database;
    return await db.update(
      'Courses',
      course.toMap(),
      where: 'course_id = ?',
      whereArgs: [course.courseId],
    );
  }

  Future<int> deleteCourse(int courseId) async {
    final db = await database;
    return await db.delete(
      'Courses',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  // ---------------- Students Operations ----------------
  Future<List<Student>> getStudents({
    String? location,
    String? gradeYear,
    String? department,
    String? query,
  }) async {
    final db = await database;
    List<String> conditions = [];
    List<dynamic> whereArgs = [];

    if (location != null && location.trim().isNotEmpty) {
      conditions.add('location = ?');
      whereArgs.add(location.trim());
    }
    if (gradeYear != null && gradeYear.trim().isNotEmpty) {
      conditions.add('grade_year = ?');
      whereArgs.add(gradeYear.trim());
    }
    if (department != null && department.trim().isNotEmpty) {
      conditions.add('department = ?');
      whereArgs.add(department.trim());
    }
    if (query != null && query.trim().isNotEmpty) {
      conditions.add('(full_name LIKE ? OR academic_id LIKE ? OR location LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%', '%$query%']);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final res = await db.query(
      'Students',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'academic_id ASC',
    );
    return res.map((m) => Student.fromMap(m)).toList();
  }

  Future<Student?> getStudentById(String academicId) async {
    final db = await database;
    final res = await db.query(
      'Students',
      where: 'academic_id = ?',
      whereArgs: [academicId.trim()],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return Student.fromMap(res.first);
    }
    return null;
  }

  Future<List<String>> getAllUniqueGradeYears() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT DISTINCT grade_year FROM Students WHERE grade_year IS NOT NULL AND TRIM(grade_year) != "" ORDER BY grade_year ASC',
    );
    return res.map((r) => (r['grade_year'] as String).trim()).toList();
  }

  Future<List<String>> getAllUniqueDepartments({String? gradeYear}) async {
    final db = await database;
    String query = 'SELECT DISTINCT department FROM Students WHERE department IS NOT NULL AND TRIM(department) != ""';
    List<dynamic> args = [];
    if (gradeYear != null && gradeYear.trim().isNotEmpty) {
      query += ' AND grade_year = ?';
      args.add(gradeYear.trim());
    }
    query += ' ORDER BY department ASC';
    final res = await db.rawQuery(query, args);
    return res.map((r) => (r['department'] as String).trim()).toList();
  }

  Future<List<String>> getAllUniqueLocations({String? gradeYear, String? department}) async {
    final db = await database;
    String query = 'SELECT DISTINCT location FROM Students WHERE location IS NOT NULL AND TRIM(location) != ""';
    List<dynamic> args = [];
    if (gradeYear != null && gradeYear.trim().isNotEmpty) {
      query += ' AND grade_year = ?';
      args.add(gradeYear.trim());
    }
    if (department != null && department.trim().isNotEmpty) {
      query += ' AND department = ?';
      args.add(department.trim());
    }
    query += ' ORDER BY location ASC';
    final res = await db.rawQuery(query, args);
    return res.map((r) => (r['location'] as String).trim()).toList();
  }

  Future<int> batchInsertStudents(List<Student> students) async {
    final db = await database;
    int count = 0;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final s in students) {
        batch.insert(
          'Students',
          s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        count++;
      }
      await batch.commit(noResult: true);
    });
    return count;
  }

  Future<int> getTotalStudentsCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM Students');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> clearAllStudents() async {
    final db = await database;
    await db.delete('Students');
  }

  // ---------------- Sessions Operations ----------------
  Future<int> createSession(Session session) async {
    final db = await database;
    return await db.insert('Sessions', session.toMap());
  }

  Future<List<Session>> getSessions() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        s.session_id,
        s.course_id,
        s.session_type,
        s.location,
        s.created_at,
        c.course_name,
        (SELECT COUNT(*) FROM Attendance_Records ar WHERE ar.session_id = s.session_id) as total_students,
        (SELECT COUNT(*) FROM Attendance_Records ar WHERE ar.session_id = s.session_id AND (ar.status = 'present' OR ar.status = 'excused')) as present_count
      FROM Sessions s
      LEFT JOIN Courses c ON s.course_id = c.course_id
      ORDER BY s.session_id DESC
    ''');
    return res.map((m) => Session.fromMap(m)).toList();
  }

  Future<Session?> getSessionById(int sessionId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        s.session_id,
        s.course_id,
        s.session_type,
        s.location,
        s.created_at,
        c.course_name,
        (SELECT COUNT(*) FROM Attendance_Records ar WHERE ar.session_id = s.session_id) as total_students,
        (SELECT COUNT(*) FROM Attendance_Records ar WHERE ar.session_id = s.session_id AND (ar.status = 'present' OR ar.status = 'excused')) as present_count
      FROM Sessions s
      LEFT JOIN Courses c ON s.course_id = c.course_id
      WHERE s.session_id = ?
      LIMIT 1
    ''', [sessionId]);
    if (res.isNotEmpty) {
      return Session.fromMap(res.first);
    }
    return null;
  }

  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete('Sessions', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  // ---------------- Attendance Records Operations ----------------
  Future<void> initializeAttendanceRoster({
    required int sessionId,
    required List<Student> targetStudents,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final st in targetStudents) {
        batch.insert(
          'Attendance_Records',
          {
            'session_id': sessionId,
            'academic_id': st.academicId,
            'status': 'absent',
            'scan_timestamp': null,
            'notes': null,
            'score': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Finalize and archive session attendance:
  /// Ensures all enrolled students not marked present or excused are saved as 'absent' with score = 0.
  Future<void> finalizeSessionAttendance(int sessionId) async {
    final db = await database;
    await db.update(
      'Attendance_Records',
      {
        'status': 'absent',
        'score': 0,
      },
      where: 'session_id = ? AND (status IS NULL OR status = "" OR (status != "present" AND status != "excused"))',
      whereArgs: [sessionId],
    );
  }

  Future<void> recordAttendance({
    required int sessionId,
    required String academicId,
    required String status, // 'present' | 'excused' | 'absent'
    required int score,     // 1 or 0
    String? notes,
    String? timestamp,
  }) async {
    final db = await database;
    final now = timestamp ?? DateTime.now().toIso8601String();

    await db.insert(
      'Attendance_Records',
      {
        'session_id': sessionId,
        'academic_id': academicId,
        'status': status,
        'scan_timestamp': now,
        'notes': notes,
        'score': score,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttendanceRecord>> getSessionRecords(int sessionId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT 
        ar.record_id,
        ar.session_id,
        ar.academic_id,
        ar.status,
        ar.scan_timestamp,
        ar.notes,
        ar.score,
        st.full_name,
        st.location,
        st.grade_year,
        st.department
      FROM Attendance_Records ar
      LEFT JOIN Students st ON ar.academic_id = st.academicId
      WHERE ar.session_id = ?
      ORDER BY 
        CASE ar.status 
          WHEN 'present' THEN 1 
          WHEN 'excused' THEN 2 
          ELSE 3 
        END,
        ar.scan_timestamp DESC,
        ar.academic_id ASC
    ''', [sessionId]);
    return res.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  Future<Set<String>> getPresentAcademicIdsInSession(int sessionId) async {
    final db = await database;
    final res = await db.query(
      'Attendance_Records',
      columns: ['academic_id'],
      where: 'session_id = ? AND (status = "present" OR status = "excused")',
      whereArgs: [sessionId],
    );
    return res.map((r) => r['academic_id'] as String).toSet();
  }

  // ---------------- Dashboard Summary Counts ----------------
  Future<Map<String, int>> getDashboardStats() async {
    final db = await database;
    final coursesCountRes = await db.rawQuery('SELECT COUNT(*) as c FROM Courses');
    final studentsCountRes = await db.rawQuery('SELECT COUNT(*) as c FROM Students');
    final sessionsCountRes = await db.rawQuery('SELECT COUNT(*) as c FROM Sessions');

    return {
      'courses': Sqflite.firstIntValue(coursesCountRes) ?? 0,
      'students': Sqflite.firstIntValue(studentsCountRes) ?? 0,
      'sessions': Sqflite.firstIntValue(sessionsCountRes) ?? 0,
    };
  }
}
