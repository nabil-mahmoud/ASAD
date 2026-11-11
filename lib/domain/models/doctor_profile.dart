class DoctorProfile {
  final int? id;
  final String doctorName;
  final String? facultyName;

  const DoctorProfile({
    this.id,
    required this.doctorName,
    this.facultyName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'doctor_name': doctorName,
      'faculty_name': facultyName,
    };
  }

  factory DoctorProfile.fromMap(Map<String, dynamic> map) {
    return DoctorProfile(
      id: map['id'] as int?,
      doctorName: map['doctor_name'] as String,
      facultyName: map['faculty_name'] as String?,
    );
  }

  DoctorProfile copyWith({
    int? id,
    String? doctorName,
    String? facultyName,
  }) {
    return DoctorProfile(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      facultyName: facultyName ?? this.facultyName,
    );
  }
}
