class MissedDoseRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String caregiverId;
  final String medicineId;
  final String medicineName;
  final String scheduledTime; // YYYY-MM-DD HH:MM
  final String status;
  final String? takenTime;
  final String missedTime;
  final bool notificationSent;

  MissedDoseRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.caregiverId,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledTime,
    required this.status,
    this.takenTime,
    required this.missedTime,
    required this.notificationSent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'caregiverId': caregiverId,
    'medicineId': medicineId,
    'medicineName': medicineName,
    'scheduledTime': scheduledTime,
    'status': status,
    'takenTime': takenTime,
    'missedTime': missedTime,
    'notificationSent': notificationSent,
  };

  factory MissedDoseRecord.fromJson(Map<String, dynamic> json) => MissedDoseRecord(
    id: json['id'] ?? '',
    patientId: json['patientId'] ?? '',
    patientName: json['patientName'] ?? '',
    caregiverId: json['caregiverId'] ?? '',
    medicineId: json['medicineId'] ?? '',
    medicineName: json['medicineName'] ?? '',
    scheduledTime: json['scheduledTime'] ?? '',
    status: json['status'] ?? 'Missed',
    takenTime: json['takenTime'],
    missedTime: json['missedTime'] ?? '',
    notificationSent: json['notificationSent'] ?? false,
  );
}
