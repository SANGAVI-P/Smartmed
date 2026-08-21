class Device {
  final String id;
  final String deviceId;
  String status; // 'Registered' | 'Not Registered' | 'online' | 'offline'
  String patientId;
  int batteryLevel;
  String lastSyncTime;
  final String createdAt;
  String updatedAt;

  Device({
    required this.id,
    required this.deviceId,
    required this.status,
    required this.patientId,
    required this.batteryLevel,
    required this.lastSyncTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'status': status,
    'patientId': patientId,
    'batteryLevel': batteryLevel,
    'lastSyncTime': lastSyncTime,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] ?? '',
    deviceId: json['deviceId'] ?? '',
    status: json['status'] ?? 'Not Registered',
    patientId: json['patientId'] ?? '',
    batteryLevel: json['batteryLevel'] ?? 100,
    lastSyncTime: json['lastSyncTime'] ?? '',
    createdAt: json['createdAt'] ?? '',
    updatedAt: json['updatedAt'] ?? '',
  );
}
