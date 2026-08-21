// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';

class MedicineEditControllers {
  final TextEditingController name;
  final TextEditingController strength;
  final TextEditingController dosage;
  final TextEditingController duration;

  MedicineEditControllers({
    required this.name,
    required this.strength,
    required this.dosage,
    required this.duration,
  });

  void dispose() {
    name.dispose();
    strength.dispose();
    dosage.dispose();
    duration.dispose();
  }
}

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  String _patientFilter = 'mock-patient';
  String? _errorMessage;

  // File Upload / Picker state
  Uint8List? _uploadedImageBytes;
  String? _uploadedImageName;
  int _uploadedImageSize = 0;

  String? _uploadedPDFName;
  Uint8List? _uploadedPDFBytes;
  int _uploadedPDFSize = 0;

  String? _fileType; // 'image' | 'camera' | 'pdf'

  // AI OCR state
  bool _isProcessing = false;
  bool _showExtractedInfo = false;
  bool _isEditingExtracted = false;
  bool _isOcrMocked = false;

  // Extracted values
  List<MedicineExtraction> _extractedMedicines = [];
  List<MedicineEditControllers> _editControllers = [];
  String _rawOcrText = '';
  bool _showOcrText = false;
  double _extractedConfidence = 100.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (final ctrl in _editControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _uploadedImageBytes = result.files.single.bytes;
          _uploadedImageName = result.files.single.name;
          _uploadedImageSize = result.files.single.size;
          _uploadedPDFName = null;
          _uploadedPDFBytes = null;
          _uploadedPDFSize = 0;
          _fileType = 'image';
          _errorMessage = null;
          _showExtractedInfo = false;
          _isEditingExtracted = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select photo: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      if (kIsWeb) {
        final result = await captureWebPhoto(context);
        if (result != null) {
          setState(() {
            _uploadedImageBytes = result['bytes'] as Uint8List;
            _uploadedImageName = result['name'] as String;
            _uploadedImageSize = result['size'] as int;
            _uploadedPDFName = null;
            _uploadedPDFBytes = null;
            _uploadedPDFSize = 0;
            _fileType = 'camera';
            _errorMessage = null;
            _showExtractedInfo = false;
            _isEditingExtracted = false;
          });
        }
        return;
      }

      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _uploadedImageBytes = bytes;
          _uploadedImageName = image.name;
          _uploadedImageSize = bytes.length;
          _uploadedPDFName = null;
          _uploadedPDFBytes = null;
          _uploadedPDFSize = 0;
          _fileType = 'camera';
          _errorMessage = null;
          _showExtractedInfo = false;
          _isEditingExtracted = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture photo: $e';
      });
    }
  }

  Future<void> _choosePDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _uploadedPDFName = result.files.single.name;
          _uploadedPDFBytes = result.files.single.bytes;
          _uploadedPDFSize = result.files.single.size;
          _uploadedImageBytes = null;
          _uploadedImageName = null;
          _uploadedImageSize = 0;
          _fileType = 'pdf';
          _errorMessage = null;
          _showExtractedInfo = false;
          _isEditingExtracted = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select PDF: $e';
      });
    }
  }

  void _selectPreset(String fileName) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      final bytes = await generatePresetRxImage(fileName);
      setState(() {
        _uploadedImageBytes = bytes;
        _uploadedImageName = fileName;
        _uploadedImageSize = bytes.length;
        _uploadedPDFName = null;
        _uploadedPDFBytes = null;
        _uploadedPDFSize = 0;
        _fileType = 'image';
        _errorMessage = null;
        _showExtractedInfo = false;
        _isEditingExtracted = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate preset document: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

   void _removeFile() {
    setState(() {
      _uploadedImageBytes = null;
      _uploadedImageName = null;
      _uploadedImageSize = 0;
      _uploadedPDFName = null;
      _uploadedPDFBytes = null;
      _uploadedPDFSize = 0;
      _fileType = null;
      _showExtractedInfo = false;
      _isEditingExtracted = false;
      _errorMessage = null;
      _rawOcrText = '';
      _showOcrText = false;
      _extractedMedicines = [];
      _isOcrMocked = false;
      for (final ctrl in _editControllers) {
        ctrl.dispose();
      }
      _editControllers.clear();
    });
  }

  void _processPrescription() async {
    final fileName = _fileType == 'pdf' ? _uploadedPDFName : _uploadedImageName;
    if (fileName == null) return;

    final bytes = _fileType == 'pdf' ? _uploadedPDFBytes : _uploadedImageBytes;
    if (bytes == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final ocrResult = await OcrService.processPrescription(bytes, fileName);
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _rawOcrText = ocrResult.rawText;
        _extractedConfidence = ocrResult.confidence;
        _extractedMedicines = List.from(ocrResult.medicines);
        _showExtractedInfo = true;
        _isEditingExtracted = false;
        _isOcrMocked = ocrResult.isMock;
      });
    } catch (e) {
      if (!mounted) return;
      
      final err = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isProcessing = false;
        _rawOcrText = '';
        _extractedMedicines = [];
        _extractedConfidence = 0.0;
        
        if (err.contains('API_KEY_NOT_CONFIGURED')) {
          _errorMessage = 'Gemini API key is not configured. Please tap the settings gear icon in the header to enter your API key.';
        } else if (err.contains('UNREADABLE_PRESCRIPTION')) {
          _errorMessage = 'Unable to read this prescription clearly. Please upload a clearer image.';
        } else {
          _errorMessage = err;
        }
      });
    }
  }

  void _showApiKeyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController(text: prefs.getString('smartmed_gemini_api_key') ?? '');
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('OCR Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Gemini API Key',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'AIzaSy...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your Gemini API key from Google AI Studio. It is saved securely in local storage. If blank, it fallbacks to GEMINI_API_KEY environment variable.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final key = controller.text.trim();
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('smartmed_gemini_api_key', key);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('API Key saved successfully!'),
                    backgroundColor: Color(0xff10b981),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPrescriptionDetails(Prescription pres) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hasExtracted = pres.extractedMedicines != null && pres.extractedMedicines!.isNotEmpty;
        
        // Decode base64 document preview if possible
        Widget docPreview = const SizedBox.shrink();
        if (pres.downloadURL.startsWith('data:image/')) {
          try {
            final base64Str = pres.downloadURL.split(',').last;
            final bytes = base64Decode(base64Str);
            docPreview = Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            );
          } catch (e) {
            docPreview = const Text('Failed to load document preview', style: TextStyle(color: Colors.grey, fontSize: 11));
          }
        } else if (pres.downloadURL.startsWith('data:application/pdf')) {
          docPreview = Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 36),
                  SizedBox(height: 8),
                  Text('PDF Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(
                pres.fileType == 'application/pdf' ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                color: pres.fileType == 'application/pdf' ? Colors.redAccent : const Color(0xff3b82f6),
              ),
              const SizedBox(width: 10),
              const Text('Prescription Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Meta fields
                  _buildDetailRow('File Name', pres.fileName),
                  _buildDetailRow('Upload Date', pres.uploadDate),
                  _buildDetailRow('File Size', _formatFileSize(pres.fileSize)),
                  _buildDetailRow('Uploaded By', pres.uploadedBy),
                  
                  const SizedBox(height: 16),
                  if (pres.downloadURL != '#') ...[
                    const Text('DOCUMENT VISUAL PREVIEW', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    docPreview,
                    const SizedBox(height: 16),
                  ],

                  // Glass clinical slip formulations
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SMARTMED MEDICAL CLINIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        const Text('Rx APPROVED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9)),
                        const Divider(height: 20),
                        const Text('DETECTED FORMULATIONS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 8),
                        if (hasExtracted) ...[
                          ...pres.extractedMedicines!.map((med) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${med.name} ${med.strength}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 2),
                                Text(
                                  'Take ${med.dosage} (${_getInlineFrequencyString(med)}) ${med.timing == 'after_food' ? 'after food' : 'before food'}. (${med.duration})',
                                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          )),
                        ] else ...[
                          const Text('No dynamic formulations extracted.', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _startEdit() {
    _editControllers = _extractedMedicines.map((med) {
      return MedicineEditControllers(
        name: TextEditingController(text: med.name),
        strength: TextEditingController(text: med.strength),
        dosage: TextEditingController(text: med.dosage),
        duration: TextEditingController(text: med.duration),
      );
    }).toList();
    setState(() {
      _isEditingExtracted = true;
    });
  }

  void _saveEdits() {
    for (int i = 0; i < _extractedMedicines.length; i++) {
      final ctrl = _editControllers[i];
      _extractedMedicines[i] = _extractedMedicines[i].copyWith(
        name: ctrl.name.text.trim(),
        strength: ctrl.strength.text.trim(),
        dosage: ctrl.dosage.text.trim(),
        duration: ctrl.duration.text.trim(),
      );
    }
    // Clean up controllers
    for (final ctrl in _editControllers) {
      ctrl.dispose();
    }
    _editControllers.clear();
    setState(() {
      _isEditingExtracted = false;
    });
  }

  void _confirmAndSyncMultiple() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    setState(() {
      _isProcessing = true;
    });

    try {
      final finalName = _fileType == 'pdf' 
          ? (_uploadedPDFName ?? 'Prescription.pdf') 
          : (_uploadedImageName ?? 'Prescription.jpg');
      final finalSize = _fileType == 'pdf' 
          ? _uploadedPDFSize 
          : _uploadedImageSize;

      // 1. Add prescription file details to secure HIPAA file system logs
      final downloadURL = _fileType == 'pdf' 
          ? 'data:application/pdf;base64,${base64Encode(_uploadedPDFBytes!)}' 
          : 'data:image/jpeg;base64,${base64Encode(_uploadedImageBytes!)}';

      await db.addPrescription({
        'patientId': _patientFilter,
        'deviceId': 'BOX-8800',
        'uploadedBy': auth.user?.uid ?? 'caregiver',
        'fileName': finalName,
        'fileType': _fileType == 'pdf' ? 'application/pdf' : 'image/jpeg',
        'fileSize': finalSize > 0 ? finalSize : 1024 * 350,
        'downloadURL': downloadURL,
        'uploadDate': DateTime.now().toIso8601String().split('T')[0],
        'extractedMedicines': _extractedMedicines.map((m) => m.toJson()).toList(),
      });

      // 2. Schedule each medicine routine in the list
      for (final med in _extractedMedicines) {
        if (med.name.trim().isEmpty) continue; // Skip empty fields

        int frequencyCount = 0;
        if (med.morning) frequencyCount++;
        if (med.afternoon) frequencyCount++;
        if (med.night) frequencyCount++;
        if (frequencyCount == 0) frequencyCount = 1;

        int durationDays = int.tryParse(med.duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 30;
        int quantity = durationDays * frequencyCount;

        await db.addMedicine({
          'patientId': _patientFilter,
          'name': med.name,
          'dosage': '${med.strength} (${med.dosage})',
          'schedule': {
            'morning': med.morning,
            'afternoon': med.afternoon,
            'night': med.night,
          },
          'timing': med.timing,
          'startDate': DateTime.now().toIso8601String().split('T')[0],
          'endDate': DateTime.now().add(Duration(days: durationDays)).toIso8601String().split('T')[0],
          'quantity': quantity,
          'initialQuantity': quantity,
          'pillsPerDose': 1,
          'times': {
            if (med.morning) 'morning': '08:00',
            if (med.afternoon) 'afternoon': '13:00',
            if (med.night) 'night': '20:00',
          }
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription processed successfully & medication routines scheduled!'),
          backgroundColor: Color(0xff10b981),
        ),
      );

      // Reset flow
      _removeFile();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to schedule medication: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }



  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    final i = (bytes / k).round() > k ? 2 : 1;
    return '${(bytes / (i == 2 ? k * k : k)).toStringAsFixed(1)} ${sizes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    // Resolve filter
    if (auth.user?.role == 'patient' && _patientFilter != auth.user?.uid) {
      _patientFilter = auth.user!.uid;
    } else if (auth.user?.role != 'patient') {
      if (db.patients.isNotEmpty && (_patientFilter == 'mock-patient' || !db.patients.any((p) => p.uid == _patientFilter))) {
        _patientFilter = db.patients.first.uid;
      }
    }

    final patientPres = db.prescriptions.where((p) => p.patientId == _patientFilter).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: DashboardHeader(title: 'Prescription')),
                Row(
                  children: [
                    if (auth.user?.role != 'patient') ...[
                      const Text('PATIENT: ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 6),
                      if (db.patients.isNotEmpty) ...[
                        DropdownButton<String>(
                          value: db.patients.any((p) => p.uid == _patientFilter) ? _patientFilter : db.patients.first.uid,
                          dropdownColor: isDark ? const Color(0xff0f172a) : Colors.white,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                          items: db.patients.map((p) {
                            return DropdownMenuItem<String>(value: p.uid, child: Text(p.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _patientFilter = val;
                              });
                            }
                          },
                        ),
                      ] else ...[
                        const Text('No Patients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ],
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.grey),
                      onPressed: _showApiKeyDialog,
                      tooltip: 'OCR Configuration',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload a prescription to extract medicine information.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Error display banner
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                      onPressed: () => setState(() => _errorMessage = null),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              if (_errorMessage!.contains('not configured')) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _rawOcrText = 'OCR returned no readable text.';
                      _extractedConfidence = 100.0;
                      _extractedMedicines = [
                        MedicineExtraction(
                          name: '',
                          strength: '',
                          dosage: '',
                          morning: true,
                          afternoon: false,
                          night: true,
                          timing: 'after_food',
                          duration: '5 days',
                          confidence: 100.0,
                        )
                      ];
                      _showExtractedInfo = true;
                      _isEditingExtracted = true;
                      _editControllers = [
                        MedicineEditControllers(
                          name: TextEditingController(text: ''),
                          strength: TextEditingController(text: ''),
                          dosage: TextEditingController(text: ''),
                          duration: TextEditingController(text: '5 days'),
                        )
                      ];
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3b82f6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Enter Prescription Details Manually', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ],

            // Main Flow Container
            if (_isProcessing)
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Color(0xff3b82f6)),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing prescription...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_showExtractedInfo)
              _buildExtractedInfoView(isDark)
            else if (_fileType == 'pdf')
              _buildPDFPreviewView(isDark)
            else if (_uploadedImageBytes != null)
              _buildImagePreviewView(isDark)
            else
              _buildUploadArea(context, isDark),

            const SizedBox(height: 32),

            // Historical prescription list grid
            Text(
              'Historical Medical Files (${patientPres.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            patientPres.isEmpty
                ? const GlassCard(
                    padding: EdgeInsets.all(40),
                    child: Text('No uploaded prescription documents found.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 1,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 130,
                    ),
                    itemCount: patientPres.length,
                    itemBuilder: (context, idx) {
                      final pres = patientPres[idx];
                      final isPdf = pres.fileType == 'application/pdf';
                      return InkWell(
                        onTap: () => _showPrescriptionDetails(pres),
                        borderRadius: BorderRadius.circular(16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isPdf ? Colors.redAccent : const Color(0xff3b82f6)).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                                  color: isPdf ? Colors.redAccent : const Color(0xff3b82f6),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      pres.fileName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pres.uploadDate} • ${_formatFileSize(pres.fileSize)}',
                                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    final optionCards = [
      _buildUploadOptionCard(
        label: 'Upload Photo',
        subtext: 'JPG, JPEG, PNG formats',
        icon: Icons.photo_library_rounded,
        color: const Color(0xff3b82f6),
        onTap: _chooseFromGallery,
        isDark: isDark,
      ),
      _buildUploadOptionCard(
        label: 'Take Photo',
        subtext: 'Capture via device camera',
        icon: Icons.camera_alt_rounded,
        color: const Color(0xff10b981),
        onTap: _takePhoto,
        isDark: isDark,
      ),
      _buildUploadOptionCard(
        label: 'Upload PDF',
        subtext: 'PDF documents only',
        icon: Icons.picture_as_pdf_rounded,
        color: Colors.redAccent,
        onTap: _choosePDF,
        isDark: isDark,
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Upload Prescription',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a prescription image, take a photo, or upload a PDF from your device.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          isCompact
              ? Column(
                  children: optionCards.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [Expanded(child: c)]),
                  )).toList(),
                )
              : Row(
                  children: [
                    Expanded(child: optionCards[0]),
                    const SizedBox(width: 14),
                    Expanded(child: optionCards[1]),
                    const SizedBox(width: 14),
                    Expanded(child: optionCards[2]),
                  ],
                ),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          const Text(
            'PRESETS FOR QUICK DEMO',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetChip('Lisinopril Rx', 'lisinopril_rx.jpg', const Color(0xff3b82f6)),
              _buildPresetChip('Metformin Rx', 'metformin_rx.jpg', const Color(0xff10b981)),
              _buildPresetChip('Atorvastatin Rx', 'atorvastatin_rx.jpg', const Color(0xfff59e0b)),
              _buildPresetChip('Eliquis Rx', 'eliquis_rx.jpg', const Color(0xff8b5cf6)),
              _buildPresetChip('Dental Toothpaste Rx', 'toothpaste_rx.jpg', const Color(0xffec4899)),
              _buildPresetChip('Blurry Rx', 'unclear_rx.jpg', const Color(0xffef4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String fileName, Color color) {
    return ActionChip(
      onPressed: () => _selectPreset(fileName),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUploadOptionCard({
    required String label,
    required String subtext,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtext,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewView(bool isDark) {
    final isCamera = _fileType == 'camera';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isCamera ? 'Captured Photo Preview' : 'Prescription Preview',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 250,
              color: Colors.black.withValues(alpha: 0.05),
              child: Image.memory(
                _uploadedImageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: isCamera ? _takePhoto : _chooseFromGallery,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(isCamera ? 'Retake Photo' : 'Change Image', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                onPressed: _removeFile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Remove Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _processPrescription,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Process Prescription',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFPreviewView(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Prescription PDF Preview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uploadedPDFName ?? 'document.pdf',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(_uploadedPDFSize),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _choosePDF,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Change PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              OutlinedButton.icon(
                onPressed: _removeFile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Remove PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _processPrescription,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Process Prescription',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedInfoView(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extracted Prescription Review (${_extractedConfidence.round()}% overall confidence)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              IconButton(
                onPressed: _removeFile,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                tooltip: 'Clear Document',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI Disclaimer Notice
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _isOcrMocked ? const Color(0xfff59e0b).withOpacity(0.06) : const Color(0xff3b82f6).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isOcrMocked ? const Color(0xfff59e0b).withOpacity(0.2) : const Color(0xff3b82f6).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_isOcrMocked ? Icons.info_outline_rounded : Icons.auto_awesome_rounded, color: _isOcrMocked ? const Color(0xfff59e0b) : const Color(0xff3b82f6), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOcrMocked ? 'Demo OCR Mode Active' : 'AI-assisted extraction',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _isOcrMocked ? const Color(0xfff59e0b) : const Color(0xff3b82f6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOcrMocked 
                            ? 'Gemini API key is not configured. The extracted values are mock results. Click the settings gear icon in the header to enter your Gemini API Key.'
                            : 'AI-assisted extraction. Please verify all extracted medicine information before confirmation.',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Render view OCR Text expandable section
          _buildOcrTextSection(isDark),

          const SizedBox(height: 16),

          // Render list of extracted medicines
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _extractedMedicines.length,
            itemBuilder: (context, idx) {
              final med = _extractedMedicines[idx];
              final isHighConf = med.confidence >= 85.0;
              final isMedConf = med.confidence >= 60.0 && med.confidence < 85.0;
              final isLowConf = med.confidence < 60.0;

              final Color badgeColor = isHighConf
                  ? const Color(0xff10b981)
                  : isMedConf
                      ? Colors.orangeAccent
                      : Colors.redAccent;

              final String badgeText = isHighConf
                  ? 'High Confidence'
                  : isMedConf
                      ? 'Medium Confidence — Please Verify'
                      : 'Low Confidence — Manual Verification Required';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Medicine ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff3b82f6)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10.5, 
                              fontWeight: FontWeight.bold, 
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (isLowConf) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Medicine could not be confidently identified. Please verify manually.',
                                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_isEditingExtracted && _editControllers.length > idx) ...[
                      // Editable input fields using controllers
                      _buildInlineEditField('Medicine Name', _editControllers[idx].name),
                      const SizedBox(height: 10),
                      _buildInlineEditField('Strength (e.g. 500 mg)', _editControllers[idx].strength),
                      const SizedBox(height: 10),
                      _buildInlineEditField('Dosage / Quantity (e.g. 1 Tablet)', _editControllers[idx].dosage),
                      const SizedBox(height: 10),

                      // Frequency Slots
                      const Text('FREQUENCY SLOT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInlineCheckbox('Morning', med.morning, (val) {
                            setState(() {
                              _extractedMedicines[idx] = med.copyWith(morning: val);
                            });
                          }),
                          _buildInlineCheckbox('Afternoon', med.afternoon, (val) {
                            setState(() {
                              _extractedMedicines[idx] = med.copyWith(afternoon: val);
                            });
                          }),
                          _buildInlineCheckbox('Night', med.night, (val) {
                            setState(() {
                              _extractedMedicines[idx] = med.copyWith(night: val);
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Timing Radio
                      const Text('TIMING', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'after_food',
                            groupValue: med.timing,
                            activeColor: const Color(0xff3b82f6),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _extractedMedicines[idx] = med.copyWith(timing: val);
                                });
                              }
                            },
                          ),
                          const Text('After Food', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'before_food',
                            groupValue: med.timing,
                            activeColor: const Color(0xff3b82f6),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _extractedMedicines[idx] = med.copyWith(timing: val);
                                });
                              }
                            },
                          ),
                          const Text('Before Food', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildInlineEditField('Duration (e.g. 5 days)', _editControllers[idx].duration),
                    ] else ...[
                      // Display Info row
                      _buildInfoRow('Medicine Name', med.name.isEmpty ? 'Unknown' : med.name),
                      _buildInfoRow('Strength', med.strength.isEmpty ? 'Unknown' : med.strength),
                      _buildInfoRow('Dosage', med.dosage.isEmpty ? 'Unknown' : med.dosage),
                      _buildInfoRow('Frequency', _getInlineFrequencyString(med)),
                      _buildInfoRow('Timing', med.timing == 'after_food' ? 'After Food' : 'Before Food'),
                      _buildInfoRow('Duration', med.duration.isEmpty ? 'Unknown' : med.duration),
                    ],

                    // Option to delete this specific medicine when editing
                    if (_isEditingExtracted && _extractedMedicines.length > 1) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _extractedMedicines.removeAt(idx);
                              _editControllers[idx].dispose();
                              _editControllers.removeAt(idx);
                            });
                          },
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 16),
                          label: const Text('Delete Medicine', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          if (_isEditingExtracted) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _extractedMedicines.add(
                    MedicineExtraction(
                      name: '',
                      strength: '',
                      dosage: '',
                      morning: true,
                      afternoon: false,
                      night: true,
                      timing: 'after_food',
                      duration: '5 days',
                      confidence: 100.0,
                    ),
                  );
                  _editControllers.add(
                    MedicineEditControllers(
                      name: TextEditingController(text: ''),
                      strength: TextEditingController(text: ''),
                      dosage: TextEditingController(text: ''),
                      duration: TextEditingController(text: '5 days'),
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Another Medicine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEdits,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3b82f6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Edits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startEdit,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmAndSyncMultiple,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3b82f6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('Confirm All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getInlineFrequencyString(MedicineExtraction med) {
    final slots = <String>[];
    if (med.morning) slots.add('Morning');
    if (med.afternoon) slots.add('Afternoon');
    if (med.night) slots.add('Night');
    return slots.isEmpty ? 'None' : slots.join(' - ');
  }

  Widget _buildInlineCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Expanded(
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xff3b82f6),
            onChanged: onChanged,
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildOcrTextSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showOcrText = !_showOcrText;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'View OCR Text',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xff3b82f6)),
                ),
                Icon(
                  _showOcrText ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xff3b82f6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_showOcrText) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OCR Extracted Text:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const Text(
                  '-------------------',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  _rawOcrText.isEmpty ? 'OCR returned no readable text.' : _rawOcrText,
                  style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                ),
                const Text(
                  '-------------------',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInlineEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


}

Future<Uint8List> generatePresetRxImage(String fileName) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, 400, 300));
  
  // Background
  final bgPaint = ui.Paint()..color = const ui.Color(0xffffffff);
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, 400, 300), bgPaint);
  
  // Header background
  final headerColor = fileName.contains('lisinopril') 
      ? const ui.Color(0xff3b82f6)
      : fileName.contains('metformin')
      ? const ui.Color(0xff10b981)
      : fileName.contains('atorvastatin')
      ? const ui.Color(0xfff59e0b)
      : fileName.contains('eliquis')
      ? const ui.Color(0xff8b5cf6)
      : const ui.Color(0xffef4444);
      
  final headerPaint = ui.Paint()..color = headerColor;
  canvas.drawRect(ui.Rect.fromLTWH(0, 0, 400, 70), headerPaint);
  
  // Draw text helper
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  
  void drawText(String text, double x, double y, double fontSize, ui.Color color, {bool bold = false}) {
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, ui.Offset(x, y));
  }
  
  drawText('SMARTMED HOSPITALS', 20, 25, 16, const ui.Color(0xffffffff), bold: true);
  drawText('Rx', 340, 15, 24, const ui.Color(0x55ffffff), bold: true);
  
  // Body text details
  String title = "Cardiovascular Care";
  String medName = "Lisinopril 10mg";
  String details = "Take 1 tablet daily in the morning for hypertension.";
  
  if (fileName.contains('metformin')) {
    title = "Endocrine Health Care";
    medName = "Metformin 500mg";
    details = "Take 1 tablet twice daily with meals.";
  } else if (fileName.contains('atorvastatin')) {
    title = "Lipid Clinic";
    medName = "Atorvastatin 20mg";
    details = "Take 1 tablet daily at bedtime.";
  } else if (fileName.contains('eliquis')) {
    title = "Cardiology Division";
    medName = "Eliquis 5mg";
    details = "Take 1 tablet twice daily.";
  } else if (fileName.contains('toothpaste')) {
    title = "Dental Toothpaste";
    medName = "Toothpaste (Oralhealth)";
    details = "Apply to teeth morning & night after food.";
  } else if (fileName.contains('unclear') || fileName.contains('blurry')) {
    title = "General Clinic";
    medName = "P...etamol 500mg";
    details = "T... 1 tab... pain [ILLEGIBLE]";
  }
  
  drawText('DEPARTMENT: ${title.toUpperCase()}', 20, 95, 10, const ui.Color(0xff64748b), bold: true);
  drawText('DATE: 2026-08-21', 20, 115, 9, const ui.Color(0xff94a3b8));
  
  // Line separator
  final linePaint = ui.Paint()..color = const ui.Color(0xffcbd5e1)..strokeWidth = 1;
  canvas.drawLine(ui.Offset(20, 135), ui.Offset(380, 135), linePaint);
  
  // Rx sign
  drawText('℞', 20, 160, 28, headerColor, bold: true);
  drawText(medName, 60, 165, 14, const ui.Color(0xff1e293b), bold: true);
  drawText('Disp: #30 • Refills: 3', 60, 185, 10, const ui.Color(0xff64748b));
  
  drawText('Sig / Directions:', 60, 215, 11, const ui.Color(0xff334155), bold: true);
  drawText(details, 60, 235, 10, const ui.Color(0xff475569));
  
  // Footer
  final footerPaint = ui.Paint()..color = const ui.Color(0xfff8fafc);
  canvas.drawRect(ui.Rect.fromLTWH(0, 270, 400, 30), footerPaint);
  drawText('AUTHENTIC CLINICAL PORTAL DOCUMENT • VERIFIED BY SMARTMED OCR', 20, 280, 8, const ui.Color(0xff94a3b8));
  
  final picture = recorder.endRecording();
  final imgData = await picture.toImage(400, 300);
  final byteData = await imgData.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
