class Reminder {
  final String id;
  final String medicineId;
  final String patientId;
  final String medicineName;
  final String dosage;
  final String timeOfDay; // 'morning' | 'afternoon' | 'night'
  bool taken;
  final String timestamp; // YYYY-MM-DD
  String? time; // HH:MM log when taken
  final String scheduledTime; // HH:MM
  final int scheduledPills;
  int takenPills;
  int remainingPills;
  String status;

  Reminder({
    required this.id,
    required this.medicineId,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.timeOfDay,
    required this.taken,
    required this.timestamp,
    this.time,
    required this.scheduledTime,
    this.scheduledPills = 1,
    this.takenPills = 0,
    this.remainingPills = 1,
    this.status = 'Scheduled',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineId': medicineId,
    'patientId': patientId,
    'medicineName': medicineName,
    'dosage': dosage,
    'timeOfDay': timeOfDay,
    'taken': taken,
    'timestamp': timestamp,
    'time': time,
    'scheduledTime': scheduledTime,
    'scheduledPills': scheduledPills,
    'takenPills': takenPills,
    'remainingPills': remainingPills,
    'status': status,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] ?? '',
    medicineId: json['medicineId'] ?? '',
    patientId: json['patientId'] ?? '',
    medicineName: json['medicineName'] ?? '',
    dosage: json['dosage'] ?? '',
    timeOfDay: json['timeOfDay'] ?? 'morning',
    taken: json['taken'] ?? false,
    timestamp: json['timestamp'] ?? '',
    time: json['time'],
    scheduledTime: json['scheduledTime'] ?? '08:00',
    scheduledPills: json['scheduledPills'] ?? 1,
    takenPills: json['takenPills'] ?? 0,
    remainingPills: json['remainingPills'] ?? (json['scheduledPills'] ?? 1),
    status: json['status'] ?? 'Scheduled',
  );
}
