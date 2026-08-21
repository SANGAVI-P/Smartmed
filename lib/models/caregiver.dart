class Caregiver {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final List<String> patientIds;
  final String relationship;

  Caregiver({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.patientIds,
    required this.relationship,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'phone': phone,
    'email': email,
    'patientIds': patientIds,
    'relationship': relationship,
  };

  factory Caregiver.fromJson(Map<String, dynamic> json) => Caregiver(
    uid: json['uid'] ?? '',
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    email: json['email'] ?? '',
    patientIds: List<String>.from(json['patientIds'] ?? []),
    relationship: json['relationship'] ?? 'Caregiver',
  );
}
