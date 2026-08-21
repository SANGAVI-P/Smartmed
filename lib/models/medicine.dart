class Medicine {
  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final Map<String, bool> schedule; // e.g. {'morning': true, 'afternoon': false, 'night': true}
  final String timing; // 'before_food' | 'after_food'
  final String startDate;
  final String endDate;
  int quantity;
  final int initialQuantity;
  final Map<String, String> times; // e.g. {'morning': '08:00', 'night': '20:00'}
  final int pillsPerDose;

  Medicine({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.schedule,
    required this.timing,
    required this.startDate,
    required this.endDate,
    required this.quantity,
    required this.initialQuantity,
    required this.times,
    this.pillsPerDose = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'name': name,
    'dosage': dosage,
    'schedule': schedule,
    'timing': timing,
    'startDate': startDate,
    'endDate': endDate,
    'quantity': quantity,
    'initialQuantity': initialQuantity,
    'times': times,
    'pillsPerDose': pillsPerDose,
  };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    id: json['id'] ?? '',
    patientId: json['patientId'] ?? '',
    name: json['name'] ?? '',
    dosage: json['dosage'] ?? '',
    schedule: Map<String, bool>.from(json['schedule'] ?? {}),
    timing: json['timing'] ?? 'after_food',
    startDate: json['startDate'] ?? '',
    endDate: json['endDate'] ?? '',
    quantity: json['quantity'] ?? 0,
    initialQuantity: json['initialQuantity'] ?? 0,
    times: Map<String, String>.from(json['times'] ?? {}),
    pillsPerDose: json['pillsPerDose'] ?? 1,
  );
}
