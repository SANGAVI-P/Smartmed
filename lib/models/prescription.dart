import '../services/services.dart' show MedicineExtraction;

class Prescription {
  final String id;
  final String patientId;
  final String deviceId;
  final String uploadedBy;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String downloadURL;
  final String uploadDate;
  final String createdAt;
  final List<MedicineExtraction>? extractedMedicines;

  Prescription({
    required this.id,
    required this.patientId,
    required this.deviceId,
    required this.uploadedBy,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.downloadURL,
    required this.uploadDate,
    required this.createdAt,
    this.extractedMedicines,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'deviceId': deviceId,
    'uploadedBy': uploadedBy,
    'fileName': fileName,
    'fileType': fileType,
    'fileSize': fileSize,
    'downloadURL': downloadURL,
    'uploadDate': uploadDate,
    'createdAt': createdAt,
    'extractedMedicines': extractedMedicines?.map((m) => m.toJson()).toList(),
  };

  factory Prescription.fromJson(Map<String, dynamic> json) {
    var rawMeds = json['extractedMedicines'] as List?;
    List<MedicineExtraction>? meds = rawMeds?.map((m) => MedicineExtraction.fromJson(m)).toList();

    return Prescription(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      downloadURL: json['downloadURL'] ?? '',
      uploadDate: json['uploadDate'] ?? '',
      createdAt: json['createdAt'] ?? '',
      extractedMedicines: meds,
    );
  }
}

