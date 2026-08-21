class Patient {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String address;
  final String emergencyContact;
  final String caregiverName;
  final String caregiverPhone;
  final List<String> medicalConditions;
  final List<String> allergies;
  final String deviceId;
  final String email;
  final String dateOfBirth;
  final String relationship;

  Patient({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.emergencyContact,
    required this.caregiverName,
    required this.caregiverPhone,
    required this.medicalConditions,
    required this.allergies,
    required this.deviceId,
    this.email = '',
    this.dateOfBirth = '',
    this.relationship = '',
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'age': age,
    'gender': gender,
    'phone': phone,
    'address': address,
    'emergencyContact': emergencyContact,
    'caregiverName': caregiverName,
    'caregiverPhone': caregiverPhone,
    'medicalConditions': medicalConditions,
    'allergies': allergies,
    'deviceId': deviceId,
    'email': email,
    'dateOfBirth': dateOfBirth,
    'relationship': relationship,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    uid: json['uid'] ?? '',
    name: json['name'] ?? '',
    age: json['age'] ?? 0,
    gender: json['gender'] ?? 'Not specified',
    phone: json['phone'] ?? '',
    address: json['address'] ?? '',
    emergencyContact: json['emergencyContact'] ?? '',
    caregiverName: json['caregiverName'] ?? '',
    caregiverPhone: json['caregiverPhone'] ?? '',
    medicalConditions: List<String>.from(json['medicalConditions'] ?? []),
    allergies: List<String>.from(json['allergies'] ?? []),
    deviceId: json['deviceId'] ?? '',
    email: json['email'] ?? '',
    dateOfBirth: json['dateOfBirth'] ?? '',
    relationship: json['relationship'] ?? '',
  );
}
