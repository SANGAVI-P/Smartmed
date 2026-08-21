class UserSession {
  final String uid;
  final String email;
  final String name;
  final String role; // 'patient' | 'caregiver' | 'admin'

  UserSession({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'role': role,
  };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    uid: json['uid'] ?? '',
    email: json['email'] ?? '',
    name: json['name'] ?? '',
    role: json['role'] ?? 'patient',
  );
}
