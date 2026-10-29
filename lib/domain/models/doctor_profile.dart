class DoctorProfile {
  final int? id;
  final String doctorName;

  const DoctorProfile({
    this.id,
    required this.doctorName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'doctor_name': doctorName,
    };
  }

  factory DoctorProfile.fromMap(Map<String, dynamic> map) {
    return DoctorProfile(
      id: map['id'] as int?,
      doctorName: map['doctor_name'] as String,
    );
  }

  DoctorProfile copyWith({
    int? id,
    String? doctorName,
  }) {
    return DoctorProfile(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
    );
  }
}
