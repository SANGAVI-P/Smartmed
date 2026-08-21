import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'fuzzy_match_service.dart';

class MedicineExtraction {
  final String name;
  final String strength;
  final String dosage;
  final bool morning;
  final bool afternoon;
  final bool night;
  final String timing; // 'before_food', 'after_food'
  final String duration;
  final double confidence;

  MedicineExtraction({
    required this.name,
    required this.strength,
    required this.dosage,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.timing,
    required this.duration,
    required this.confidence,
  });

  MedicineExtraction copyWith({
    String? name,
    String? strength,
    String? dosage,
    bool? morning,
    bool? afternoon,
    bool? night,
    String? timing,
    String? duration,
    double? confidence,
  }) {
    return MedicineExtraction(
      name: name ?? this.name,
      strength: strength ?? this.strength,
      dosage: dosage ?? this.dosage,
      morning: morning ?? this.morning,
      afternoon: afternoon ?? this.afternoon,
      night: night ?? this.night,
      timing: timing ?? this.timing,
      duration: duration ?? this.duration,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'strength': strength,
    'dosage': dosage,
    'morning': morning,
    'afternoon': afternoon,
    'night': night,
    'timing': timing,
    'duration': duration,
    'confidence': confidence,
  };

  factory MedicineExtraction.fromJson(Map<String, dynamic> json) => MedicineExtraction(
    name: json['name'] ?? '',
    strength: json['strength'] ?? '',
    dosage: json['dosage'] ?? '',
    morning: json['morning'] == true,
    afternoon: json['afternoon'] == true,
    night: json['night'] == true,
    timing: json['timing'] ?? 'after_food',
    duration: json['duration'] ?? '',
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
  );
}

class OcrResult {
  final String rawText;
  final List<MedicineExtraction> medicines;
  final double confidence;
  final bool isMock;

  OcrResult({
    required this.rawText,
    required this.medicines,
    required this.confidence,
    this.isMock = false,
  });
}

class OcrService {
  /// Local image contrast, grayscale, and resize preprocessor.
  static Uint8List preprocessImageBytes(Uint8List originalBytes) {
    try {
      img.Image? decoded = img.decodeImage(originalBytes);
      if (decoded == null) return originalBytes;

      // 1. Resize to a maximum dimension of 1200px
      int width = decoded.width;
      int height = decoded.height;
      const maxDim = 1200;
      if (width > maxDim || height > maxDim) {
        if (width > height) {
          height = (height * maxDim) ~/ width;
          width = maxDim;
        } else {
          width = (width * maxDim) ~/ height;
          height = maxDim;
        }
        decoded = img.copyResize(decoded, width: width, height: height);
      }

      // 2. Grayscale, Contrast, and Brightness adjustment
      // contrast = 1.25, brightness = 15
      for (final pixel in decoded) {
        double r = pixel.r.toDouble();
        double g = pixel.g.toDouble();
        double b = pixel.b.toDouble();
        double gray = 0.299 * r + 0.587 * g + 0.114 * b;
        
        double newColor = 1.25 * (gray - 128) + 128 + 15;
        if (newColor < 0) newColor = 0;
        if (newColor > 255) newColor = 255;
        
        pixel.r = newColor;
        pixel.g = newColor;
        pixel.b = newColor;
      }

      return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
    } catch (e) {
      debugPrint("Image preprocessing error: $e");
      return originalBytes;
    }
  }

  /// Processes the uploaded prescription file through the Gemini 1.5 Flash REST API.
  static Future<OcrResult> processPrescription(Uint8List bytes, String fileName) async {
    // 1. Load API Key (shared_preferences config takes priority, fallback to String.fromEnvironment)
    final prefs = await SharedPreferences.getInstance();
    String apiKey = prefs.getString('smartmed_gemini_api_key') ?? '';
    
    if (apiKey.isEmpty) {
      apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    }

    if (apiKey.isEmpty) {
      final nameLower = fileName.toLowerCase();
      if (nameLower.contains('lisinopril')) {
        return OcrResult(
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: CARDIOVASCULAR CARE\nDATE: 2026-08-21\n℞ Lisinopril 10mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet daily in the morning for hypertension.",
          medicines: [
            MedicineExtraction(
              name: "Lisinopril",
              strength: "10 mg",
              dosage: "1 Tablet",
              morning: true,
              afternoon: false,
              night: false,
              timing: "before_food",
              duration: "30 days",
              confidence: 95.0,
            )
          ],
          confidence: 95.0,
          isMock: true,
        );
      } else if (nameLower.contains('metformin')) {
        return OcrResult(
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: ENDOCRINE HEALTH CARE\nDATE: 2026-08-21\n℞ Metformin 500mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet twice daily with meals.",
          medicines: [
            MedicineExtraction(
              name: "Metformin",
              strength: "500 mg",
              dosage: "1 Tablet",
              morning: true,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "15 days",
              confidence: 95.0,
            )
          ],
          confidence: 95.0,
          isMock: true,
        );
      } else if (nameLower.contains('atorvastatin')) {
        return OcrResult(
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: LIPID CLINIC\nDATE: 2026-08-21\n℞ Atorvastatin 20mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet daily at bedtime.",
          medicines: [
            MedicineExtraction(
              name: "Atorvastatin",
              strength: "20 mg",
              dosage: "1 Tablet",
              morning: false,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "30 days",
              confidence: 95.0,
            )
          ],
          confidence: 95.0,
          isMock: true,
        );
      } else if (nameLower.contains('eliquis')) {
        return OcrResult(
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: CARDIOLOGY DIVISION\nDATE: 2026-08-21\n℞ Eliquis 5mg\nDisp: #30 • Refills: 3\nSig / Directions:\nTake 1 tablet twice daily.",
          medicines: [
            MedicineExtraction(
              name: "Eliquis",
              strength: "5 mg",
              dosage: "1 Tablet",
              morning: true,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "15 days",
              confidence: 95.0,
            )
          ],
          confidence: 95.0,
          isMock: true,
        );
      } else if (nameLower.contains('toothpaste')) {
        return OcrResult(
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: DENTAL TOOTHPASTE\nDATE: 2026-08-21\n℞ Toothpaste (Oralhealth)\nDisp: #30 • Refills: 3\nSig / Directions:\nApply to teeth morning & night after food.",
          medicines: [
            MedicineExtraction(
              name: "Toothpaste",
              strength: "Not detected",
              dosage: "Apply to teeth",
              morning: true,
              afternoon: false,
              night: true,
              timing: "after_food",
              duration: "30 days",
              confidence: 95.0,
            )
          ],
          confidence: 95.0,
          isMock: true,
        );
      } else if (nameLower.contains('unclear') || nameLower.contains('blurry')) {
        return OcrResult(
          rawText: "SMARTMED HOSPITALS\nRx\nDEPARTMENT: GENERAL CLINIC\nDATE: 2026-08-21\n℞ P...etamol 500mg\nDisp: #30 • Refills: 3\nSig / Directions:\nT... 1 tab... pain [ILLEGIBLE]",
          medicines: [],
          confidence: 30.0,
          isMock: true,
        );
      } else {
        return OcrResult(
          rawText: "Paracetamol - 1\nDistrin - 1\nLoperamide - 1\nNight Before Food",
          medicines: [
            MedicineExtraction(
              name: "Paracetamol",
              strength: "500 mg",
              dosage: "1 Tablet",
              morning: false,
              afternoon: false,
              night: true,
              timing: "before_food",
              duration: "7 days",
              confidence: 98.0,
            ),
            MedicineExtraction(
              name: "Distrin",
              strength: "10 mg",
              dosage: "1 Tablet",
              morning: false,
              afternoon: false,
              night: true,
              timing: "before_food",
              duration: "7 days",
              confidence: 95.0,
            ),
            MedicineExtraction(
              name: "Loperamide",
              strength: "2 mg",
              dosage: "1 Capsule",
              morning: false,
              afternoon: false,
              night: true,
              timing: "before_food",
              duration: "5 days",
              confidence: 98.0,
            ),
          ],
          confidence: 95.0,
          isMock: true,
        );
      }
    }

    // 2. Perform image preprocessing on non-PDF files
    Uint8List processedBytes = bytes;
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    if (!isPdf) {
      processedBytes = preprocessImageBytes(bytes);
    }

    final base64Image = base64Encode(processedBytes);
    String mimeType = isPdf ? 'application/pdf' : 'image/jpeg';
    if (fileName.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    }

    final prompt = """
Extract all medicine information from this prescription image or PDF. 
You must output a valid JSON object matching the following structure:
{
  "rawText": "The complete raw text extracted from the document",
  "medicines": [
    {
      "name": "Corrected medicine name (leave empty if unrecognizable)",
      "strength": "e.g. 500 mg, 10 mg (leave empty if not found)",
      "dosage": "e.g. 1 Tablet, 2 Capsules, 1 Inhalation (leave empty if not found)",
      "morning": true/false,
      "afternoon": true/false,
      "night": true/false,
      "timing": "before_food" or "after_food" (default to "after_food" if not specified)",
      "duration": "e.g. 5 days, 30 days (leave empty if not found)",
      "confidence": 0-100 (your confidence in extracting this specific medicine)
    }
  ],
  "confidence": 0-100 (overall confidence of prescription scan/readability)
}

Do not guess any fields that are not present. If a field cannot be read, leave it blank or mark it as "Not detected". If the image is blurry, corrupted, or not a medical prescription, return an empty medicines list and confidence score below 50. Output ONLY the JSON block, no markdown formatting.
""";

    final geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(geminiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API call failed: ${response.body}');
    }

    final responseData = jsonDecode(response.body);
    final textResponse = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (textResponse == null || textResponse.toString().isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    final parsedResult = jsonDecode(textResponse.toString().trim());

    final double overallConfidence = (parsedResult['confidence'] as num?)?.toDouble() ?? 0.0;
    if (overallConfidence < 45) {
      throw Exception('UNREADABLE_PRESCRIPTION');
    }

    final medicinesList = <MedicineExtraction>[];
    final rawMedicines = parsedResult['medicines'] as List?;
    if (rawMedicines != null) {
      for (var rawMed in rawMedicines) {
        final String ocrName = rawMed['name'] ?? '';
        final MatchResult fuzzy = FuzzyMatchService.fuzzyMatchMedicine(ocrName);

        final double ocrConf = (rawMed['confidence'] as num?)?.toDouble() ?? 100.0;
        final double combinedConfidence = ocrConf * (fuzzy.similarity > 0 ? fuzzy.similarity : 1.0);

        final finalName = fuzzy.similarity >= 0.85 ? fuzzy.matchedName : (ocrName.isNotEmpty ? ocrName : 'Not detected');

        medicinesList.add(MedicineExtraction(
          name: finalName,
          strength: rawMed['strength'] ?? 'Not detected',
          dosage: rawMed['dosage'] ?? 'Not detected',
          morning: rawMed['morning'] == true,
          afternoon: rawMed['afternoon'] == true,
          night: rawMed['night'] == true,
          timing: rawMed['timing'] == 'before_food' ? 'before_food' : 'after_food',
          duration: rawMed['duration'] ?? 'Not detected',
          confidence: combinedConfidence,
        ));
      }
    }

    return OcrResult(
      rawText: parsedResult['rawText'] ?? '',
      medicines: medicinesList,
      confidence: overallConfidence,
    );
  }
}
