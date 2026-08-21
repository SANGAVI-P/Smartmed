class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'reminder' | 'low_stock' | 'missed' | 'emergency'
  final String timestamp;
  bool read;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.read,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'timestamp': timestamp,
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    type: json['type'] ?? 'reminder',
    timestamp: json['timestamp'] ?? '',
    read: json['read'] ?? false,
  );
}
