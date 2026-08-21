import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'ocr_service.dart';

class DatabaseService extends ChangeNotifier {
  List<Device> _devices = [];
  List<Patient> _patients = [];
  List<Caregiver> _caregivers = [];
  List<Medicine> _medicines = [];
  List<Reminder> _reminders = [];
  List<Prescription> _prescriptions = [];
  List<AppNotification> _notifications = [];
  final List<String> _telemetryLogs = [];
  Timer? _telemetryTimer;
  int _gracePeriod = 30;
  List<MissedDoseRecord> _missedDoseHistory = [];
  Timer? _missedDoseTimer;

  List<Device> get devices => _devices;
  List<Patient> get patients => _patients;
  List<Caregiver> get caregivers => _caregivers;
  List<Medicine> get medicines => _medicines;
  List<Reminder> get reminders => _reminders;
  List<Prescription> get prescriptions => _prescriptions;
  List<AppNotification> get notifications => _notifications;
  List<String> get telemetryLogs => _telemetryLogs;
  int get gracePeriod => _gracePeriod;
  List<MissedDoseRecord> get missedDoseHistory => _missedDoseHistory;

  DatabaseService() {
    _initDatabase();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _missedDoseTimer?.cancel();
    super.dispose();
  }

  void addTelemetryLog(String log) {
    final timestamp = DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8);
    _telemetryLogs.insert(0, '[$timestamp] $log');
    if (_telemetryLogs.length > 50) {
      _telemetryLogs.removeLast();
    }
    notifyListeners();
  }

  Future<void> _initDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool('smartmed_db_initialized_v2') ?? false;

    if (!isInitialized) {
      await prefs.setString('smartmed_devices', '[]');
      await prefs.setString('smartmed_patients', '[]');
      await prefs.setString('smartmed_caregivers', '[]');
      await prefs.setString('smartmed_medicines', '[]');
      await prefs.setString('smartmed_reminders', '[]');
      await prefs.setString('smartmed_prescriptions', '[]');
      await prefs.setString('smartmed_notifications', '[]');
      await prefs.setInt('smartmed_grace_period', 30);
      await prefs.setString('smartmed_missed_dose_history', '[]');
      await prefs.setBool('smartmed_db_initialized_v2', true);
    }

    _loadData();
    _startTelemetryLoop();
    _startMissedDoseCheckLoop();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final devStr = prefs.getString('smartmed_devices') ?? '[]';
    _devices = (jsonDecode(devStr) as List).map((d) => Device.fromJson(d)).toList();

    final patStr = prefs.getString('smartmed_patients') ?? '[]';
    _patients = (jsonDecode(patStr) as List).map((p) => Patient.fromJson(p)).toList();

    final cgStr = prefs.getString('smartmed_caregivers') ?? '[]';
    _caregivers = (jsonDecode(cgStr) as List).map((c) => Caregiver.fromJson(c)).toList();

    final medStr = prefs.getString('smartmed_medicines') ?? '[]';
    _medicines = (jsonDecode(medStr) as List).map((m) => Medicine.fromJson(m)).toList();

    final remStr = prefs.getString('smartmed_reminders') ?? '[]';
    _reminders = (jsonDecode(remStr) as List).map((r) => Reminder.fromJson(r)).toList();

    final presStr = prefs.getString('smartmed_prescriptions') ?? '[]';
    _prescriptions = (jsonDecode(presStr) as List).map((p) => Prescription.fromJson(p)).toList();

    final notStr = prefs.getString('smartmed_notifications') ?? '[]';
    final parsedNotifs = (jsonDecode(notStr) as List).map((n) => AppNotification.fromJson(n)).toList();
    parsedNotifs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _notifications = parsedNotifs;

    _gracePeriod = prefs.getInt('smartmed_grace_period') ?? 30;

    final historyStr = prefs.getString('smartmed_missed_dose_history') ?? '[]';
    _missedDoseHistory = (jsonDecode(historyStr) as List).map((h) => MissedDoseRecord.fromJson(h)).toList();

    notifyListeners();
    checkMissedDoses();
  }

  void _startTelemetryLoop() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_devices.isEmpty) return;
      final registered = _devices.where((d) => d.status == 'Registered').toList();
      if (registered.isEmpty) return;

      final rand = Random();
      final device = registered[rand.nextInt(registered.length)];

      final events = [
        'Telemetry Ping - Battery: ${device.batteryLevel}%, Status: online',
        'Sensors check: Medicine Drawer Closed',
        'NFC RFID scan successful - unit authenticated',
        'Dispenser RTC synced with NTP server successfully'
      ];
      final event = events[rand.nextInt(events.length)];

      if (rand.nextDouble() > 0.8) {
        // Battery level simulation
        final change = rand.nextBool() ? 1 : -1;
        device.batteryLevel = max(10, min(100, device.batteryLevel + change));
        device.lastSyncTime = DateTime.now().toIso8601String();
        device.updatedAt = DateTime.now().toIso8601String();
        _saveDevices();
        addTelemetryLog('BOX ID ${device.deviceId}: Battery level updated to ${device.batteryLevel}%');
      } else {
        addTelemetryLog('BOX ID ${device.deviceId}: $event');
      }
    });
  }

  // Device Methods
  Future<void> registerDevice(String deviceId) async {
    final dev = Device(
      id: deviceId,
      deviceId: deviceId,
      status: 'Not Registered',
      patientId: '',
      batteryLevel: 100,
      lastSyncTime: DateTime.now().toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    _devices.add(dev);
    await _saveDevices();
    addTelemetryLog('Admin registered hardware unit: $deviceId');
    notifyListeners();
  }

  Future<void> rebootDevice(String deviceId) async {
    addTelemetryLog('Dispatching [REBOOT COMMAND] to hardware unit $deviceId...');
    Future.delayed(const Duration(milliseconds: 1500), () {
      addTelemetryLog('Unit $deviceId acknowledged command. Rebooting device firmware...');
      Future.delayed(const Duration(seconds: 3), () {
        addTelemetryLog('Unit $deviceId telemetry online. Status: Connected.');
      });
    });
  }

  Future<void> _saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_devices', jsonEncode(_devices.map((d) => d.toJson()).toList()));
  }

  // Medicine Methods
  Future<void> addMedicine(Map<String, dynamic> medData) async {
    final id = 'med-${DateTime.now().millisecondsSinceEpoch}';
    final med = Medicine(
      id: id,
      patientId: medData['patientId'],
      name: medData['name'],
      dosage: medData['dosage'],
      schedule: Map<String, bool>.from(medData['schedule']),
      timing: medData['timing'],
      startDate: medData['startDate'],
      endDate: medData['endDate'],
      quantity: medData['quantity'],
      initialQuantity: medData['initialQuantity'],
      times: Map<String, String>.from(medData['times']),
      pillsPerDose: medData['pillsPerDose'] ?? 1,
    );

    _medicines.add(med);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_medicines', jsonEncode(_medicines.map((m) => m.toJson()).toList()));
    
    addTelemetryLog('Added medication ${med.name} scheduler for patient.');
    notifyListeners();
  }

  Future<void> updateMedicine(String id, Map<String, dynamic> fields) async {
    final idx = _medicines.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final old = _medicines[idx];
      _medicines[idx] = Medicine(
        id: id,
        patientId: fields['patientId'] ?? old.patientId,
        name: fields['name'] ?? old.name,
        dosage: fields['dosage'] ?? old.dosage,
        schedule: fields['schedule'] != null ? Map<String, bool>.from(fields['schedule']) : old.schedule,
        timing: fields['timing'] ?? old.timing,
        startDate: fields['startDate'] ?? old.startDate,
        endDate: fields['endDate'] ?? old.endDate,
        quantity: fields['quantity'] ?? old.quantity,
        initialQuantity: fields['initialQuantity'] ?? old.initialQuantity,
        times: fields['times'] != null ? Map<String, String>.from(fields['times']) : old.times,
        pillsPerDose: fields['pillsPerDose'] ?? old.pillsPerDose,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartmed_medicines', jsonEncode(_medicines.map((m) => m.toJson()).toList()));
      notifyListeners();
    }
  }

  Future<void> deleteMedicine(String id) async {
    _medicines.removeWhere((m) => m.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_medicines', jsonEncode(_medicines.map((m) => m.toJson()).toList()));
    
    // Clean reminders
    _reminders.removeWhere((r) => r.medicineId == id);
    await prefs.setString('smartmed_reminders', jsonEncode(_reminders.map((r) => r.toJson()).toList()));

    addTelemetryLog('Deleted medication ID $id scheduler.');
    notifyListeners();
  }

  Future<void> refillMedicine(String id, int refillAmount) async {
    final idx = _medicines.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _medicines[idx].quantity = refillAmount;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartmed_medicines', jsonEncode(_medicines.map((m) => m.toJson()).toList()));
      addTelemetryLog('Refilled medicine ${_medicines[idx].name}. New Stock: $refillAmount tablets.');
      notifyListeners();
    }
  }

  // Reminder Methods
  Future<void> toggleReminderTaken(String reminderId) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx == -1) return;

    final reminder = _reminders[idx];
    final nextState = !reminder.taken;
    
    reminder.taken = nextState;
    reminder.time = nextState 
        ? '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'
        : null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_reminders', jsonEncode(_reminders.map((r) => r.toJson()).toList()));

    // Sync Medicine stock
    final medIdx = _medicines.indexWhere((m) => m.id == reminder.medicineId);
    if (medIdx != -1) {
      final medicine = _medicines[medIdx];
      if (nextState) {
        medicine.quantity = max(0, medicine.quantity - 1);
        addTelemetryLog('IoT Trigger: Pill weight sensor detected taking of ${medicine.name}');
      } else {
        medicine.quantity = medicine.quantity + 1;
        addTelemetryLog('IoT Trigger: Refitting pill returned state of ${medicine.name}');
      }

      await prefs.setString('smartmed_medicines', jsonEncode(_medicines.map((m) => m.toJson()).toList()));

      // Low stock warning alerts
      if (medicine.quantity < 7) {
        final patient = _patients.firstWhere((p) => p.uid == reminder.patientId, 
          orElse: () => Patient(uid: '', name: 'Patient', age: 0, gender: '', phone: '', address: '', emergencyContact: '', caregiverName: 'Caregiver', caregiverPhone: '', medicalConditions: [], allergies: [], deviceId: '')
        );

        final notifId1 = 'notif-low-${DateTime.now().millisecondsSinceEpoch}';
        final notif1 = AppNotification(
          id: notifId1,
          userId: reminder.patientId,
          title: 'Low Pill Warning: ${medicine.name}',
          message: 'Only ${medicine.quantity} tablets of ${medicine.name} remaining. Please request a refill soon.',
          type: 'low_stock',
          timestamp: DateTime.now().toIso8601String(),
          read: false,
        );
        _notifications.insert(0, notif1);

        // Find Caregiver
        final caregiver = _caregivers.firstWhere(
          (cg) => cg.patientIds.contains(reminder.patientId) || cg.name == patient.caregiverName,
          orElse: () => Caregiver(uid: 'unassigned', name: 'No Caregiver Assigned', phone: '', email: '', patientIds: [], relationship: '')
        );

        final notifId2 = 'notif-low-cg-${DateTime.now().millisecondsSinceEpoch}';
        final notif2 = AppNotification(
          id: notifId2,
          userId: caregiver.uid,
          title: 'Low Pill Alert: ${patient.name}',
          message: '${patient.name} has low stock of ${medicine.name} (${medicine.quantity} tablets remaining).',
          type: 'low_stock',
          timestamp: DateTime.now().toIso8601String(),
          read: false,
        );
        _notifications.insert(0, notif2);

        await prefs.setString('smartmed_notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
        addTelemetryLog('ALERT generated: Low stock for ${medicine.name} (${medicine.quantity} tablets remaining)');
      }
    }
    notifyListeners();
  }

  Future<void> takeScheduledPill(String reminderId) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx == -1) return;

    final reminder = _reminders[idx];
    if (reminder.takenPills >= reminder.scheduledPills) {
      throw Exception('Scheduled dose already completed. No additional pills are scheduled for this dose.');
    }

    reminder.takenPills += 1;
    reminder.remainingPills = max(0, reminder.scheduledPills - reminder.takenPills);
    
    reminder.status = 'Taken';
    reminder.taken = true;

    reminder.time = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    
    // Update missed dose history status to 'Taken' if present
    final historyIdx = _missedDoseHistory.indexWhere((h) => h.id == reminderId);
    if (historyIdx != -1) {
      final oldH = _missedDoseHistory[historyIdx];
      _missedDoseHistory[historyIdx] = MissedDoseRecord(
        id: oldH.id,
        patientId: oldH.patientId,
        patientName: oldH.patientName,
        caregiverId: oldH.caregiverId,
        medicineId: oldH.medicineId,
        medicineName: oldH.medicineName,
        scheduledTime: oldH.scheduledTime,
        status: 'Taken',
        takenTime: DateTime.now().toIso8601String(),
        missedTime: oldH.missedTime,
        notificationSent: oldH.notificationSent,
      );
      await prefs.setString('smartmed_missed_dose_history', jsonEncode(_missedDoseHistory.map((h) => h.toJson()).toList()));
    }

    await prefs.setString('smartmed_reminders', jsonEncode(_reminders.map((r) => r.toJson()).toList()));

    // Sync Medicine stock (inventory)
    final medIdx = _medicines.indexWhere((m) => m.id == reminder.medicineId);
    if (medIdx != -1) {
      final medicine = _medicines[medIdx];
      medicine.quantity = max(0, medicine.quantity - 1);
      await prefs.setString('smartmed_medicines', jsonEncode(_medicines.map((m) => m.toJson()).toList()));

      addTelemetryLog('IoT Trigger: Pill weight sensor detected taking of 1 pill of ${medicine.name}. Remaining inventory: ${medicine.quantity}');

      // Low stock warning alerts
      if (medicine.quantity < 7) {
        final patient = _patients.firstWhere((p) => p.uid == reminder.patientId, 
          orElse: () => Patient(uid: '', name: 'Patient', age: 0, gender: '', phone: '', address: '', emergencyContact: '', caregiverName: 'Caregiver', caregiverPhone: '', medicalConditions: [], allergies: [], deviceId: '')
        );

        final notifId1 = 'notif-low-${DateTime.now().millisecondsSinceEpoch}';
        final notif1 = AppNotification(
          id: notifId1,
          userId: reminder.patientId,
          title: 'Low Pill Warning: ${medicine.name}',
          message: 'Only ${medicine.quantity} tablets of ${medicine.name} remaining. Please request a refill soon.',
          type: 'low_stock',
          timestamp: DateTime.now().toIso8601String(),
          read: false,
        );
        _notifications.insert(0, notif1);

        // Find Caregiver
        final caregiver = _caregivers.firstWhere(
          (cg) => cg.patientIds.contains(reminder.patientId) || cg.name == patient.caregiverName,
          orElse: () => Caregiver(uid: 'unassigned', name: 'No Caregiver Assigned', phone: '', email: '', patientIds: [], relationship: '')
        );

        final notifId2 = 'notif-low-cg-${DateTime.now().millisecondsSinceEpoch}';
        final notif2 = AppNotification(
          id: notifId2,
          userId: caregiver.uid,
          title: 'Low Pill Alert: ${patient.name}',
          message: '${patient.name} has low stock of ${medicine.name} (${medicine.quantity} tablets remaining).',
          type: 'low_stock',
          timestamp: DateTime.now().toIso8601String(),
          read: false,
        );
        _notifications.insert(0, notif2);

        await prefs.setString('smartmed_notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
        addTelemetryLog('ALERT generated: Low stock for ${medicine.name} (${medicine.quantity} tablets remaining)');
      }
    }
    notifyListeners();
  }

  Future<void> generateRemindersForDay(String patientId, String date) async {
    final patientMeds = _medicines.where((m) => m.patientId == patientId).toList();
    
    // Check if reminders already exist for this date
    final alreadyExist = _reminders.any((r) => r.patientId == patientId && r.timestamp == date);
    if (alreadyExist) return;

    final List<Reminder> newReminders = [];
    for (var med in patientMeds) {
      if (med.schedule['morning'] == true) {
        newReminders.add(Reminder(
          id: 'rem-m-${med.id}-$date',
          medicineId: med.id,
          patientId: patientId,
          medicineName: med.name,
          dosage: med.dosage,
          timeOfDay: 'morning',
          taken: false,
          timestamp: date,
          scheduledTime: med.times['morning'] ?? '08:00',
          scheduledPills: med.pillsPerDose,
          takenPills: 0,
          remainingPills: med.pillsPerDose,
          status: 'Scheduled',
        ));
      }
      if (med.schedule['afternoon'] == true) {
        newReminders.add(Reminder(
          id: 'rem-a-${med.id}-$date',
          medicineId: med.id,
          patientId: patientId,
          medicineName: med.name,
          dosage: med.dosage,
          timeOfDay: 'afternoon',
          taken: false,
          timestamp: date,
          scheduledTime: med.times['afternoon'] ?? '13:00',
          scheduledPills: med.pillsPerDose,
          takenPills: 0,
          remainingPills: med.pillsPerDose,
          status: 'Scheduled',
        ));
      }
      if (med.schedule['night'] == true) {
        newReminders.add(Reminder(
          id: 'rem-n-${med.id}-$date',
          medicineId: med.id,
          patientId: patientId,
          medicineName: med.name,
          dosage: med.dosage,
          timeOfDay: 'night',
          taken: false,
          timestamp: date,
          scheduledTime: med.times['night'] ?? '20:00',
          scheduledPills: med.pillsPerDose,
          takenPills: 0,
          remainingPills: med.pillsPerDose,
          status: 'Scheduled',
        ));
      }
    }

    if (newReminders.isNotEmpty) {
      _reminders.addAll(newReminders);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartmed_reminders', jsonEncode(_reminders.map((r) => r.toJson()).toList()));
      addTelemetryLog('Generated ${newReminders.length} daily dosage schedule items for date: $date');
      notifyListeners();
    }
  }

  // Prescription Methods
  Future<void> addPrescription(Map<String, dynamic> data) async {
    final id = 'pres-${DateTime.now().millisecondsSinceEpoch}';
    
    var rawMeds = data['extractedMedicines'] as List?;
    List<MedicineExtraction>? meds = rawMeds?.map((m) => MedicineExtraction.fromJson(m)).toList();

    final pres = Prescription(
      id: id,
      patientId: data['patientId'],
      deviceId: data['deviceId'] ?? 'BOX-8800',
      uploadedBy: data['uploadedBy'],
      fileName: data['fileName'],
      fileType: data['fileType'],
      fileSize: data['fileSize'],
      downloadURL: data['downloadURL'],
      uploadDate: data['uploadDate'],
      createdAt: DateTime.now().toIso8601String(),
      extractedMedicines: meds,
    );

    _prescriptions.add(pres);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_prescriptions', jsonEncode(_prescriptions.map((p) => p.toJson()).toList()));
    
    addTelemetryLog('Uploaded new medical prescription metadata file: ${pres.fileName}');
    notifyListeners();
  }

  Future<void> deletePrescription(String id) async {
    _prescriptions.removeWhere((p) => p.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_prescriptions', jsonEncode(_prescriptions.map((p) => p.toJson()).toList()));
    
    addTelemetryLog('Removed prescription record ID $id from HIPAA files.');
    notifyListeners();
  }

  // Notifications Methods
  Future<void> markNotificationRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].read = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartmed_notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
      notifyListeners();
    }
  }

  Future<void> clearNotifications(String userId) async {
    _notifications.removeWhere((n) => n.userId == userId || n.userId == 'all');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
    notifyListeners();
  }

  // SOS Emergency Beacon
  Future<void> triggerSOS(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smartmed_sos_active_$patientId', true);

    addTelemetryLog('[EMERGENCY CRITICAL SOS DISPATCHED] by patient ID: $patientId');

    final patient = _patients.firstWhere((p) => p.uid == patientId,
      orElse: () => Patient(uid: patientId, name: 'Elderly Patient', age: 0, gender: '', phone: '', address: '', emergencyContact: '', caregiverName: 'Caregiver', caregiverPhone: '', medicalConditions: [], allergies: [], deviceId: '')
    );

    // Patient Notification
    final pNotif = AppNotification(
      id: 'sos-pat-${DateTime.now().millisecondsSinceEpoch}',
      userId: patientId,
      title: 'SOS Distress Active',
      message: 'Distress alert broadcasts sent to emergency response caregivers.',
      type: 'emergency',
      timestamp: DateTime.now().toIso8601String(),
      read: false,
    );
    _notifications.insert(0, pNotif);

    // Caregivers Notification
    final caregiver = _caregivers.firstWhere(
      (cg) => cg.patientIds.contains(patientId) || cg.name == patient.caregiverName,
          orElse: () => Caregiver(uid: 'unassigned', name: 'No Caregiver Assigned', phone: '', email: '', patientIds: [], relationship: '')
    );

    final cgNotif = AppNotification(
      id: 'sos-cg-${DateTime.now().millisecondsSinceEpoch}',
      userId: caregiver.uid,
      title: 'EMERGENCY SOS: ${patient.name}',
      message: 'Patient ${patient.name} has fired a critical distress beacon. Immediate contact required!',
      type: 'emergency',
      timestamp: DateTime.now().toIso8601String(),
      read: false,
    );
    _notifications.insert(0, cgNotif);

    await prefs.setString('smartmed_notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
    notifyListeners();
  }

  Future<void> dismissSOS(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('smartmed_sos_active_$patientId');
    addTelemetryLog('SOS Distress Alarm dismissed/cleared for Patient: $patientId');
    
    // Clear notification triggers by adding a resolved event or just resetting state
    notifyListeners();
  }

  Future<void> addPatient(Map<String, dynamic> data, String caregiverUid) async {
    final uid = data['uid'] as String;
    if (_patients.any((p) => p.uid.toLowerCase() == uid.toLowerCase())) {
      throw Exception('Patient ID must be unique.');
    }

    // Find Caregiver
    final cgIdx = _caregivers.indexWhere((c) => c.uid == caregiverUid);
    String cgName = '';
    String cgPhone = '';
    if (cgIdx != -1) {
      final caregiver = _caregivers[cgIdx];
      if (!caregiver.patientIds.contains(uid)) {
        caregiver.patientIds.add(uid);
      }
      cgName = caregiver.name;
      cgPhone = caregiver.phone;
    }

    final newPatient = Patient(
      uid: uid,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? 'Not specified',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      caregiverName: cgName,
      caregiverPhone: cgPhone,
      medicalConditions: [],
      allergies: [],
      deviceId: '',
    );

    _patients.add(newPatient);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_patients', jsonEncode(_patients.map((p) => p.toJson()).toList()));
    await prefs.setString('smartmed_caregivers', jsonEncode(_caregivers.map((c) => c.toJson()).toList()));

    addTelemetryLog('Caregiver added patient: ${newPatient.name} ($uid)');
    notifyListeners();
  }

  Future<void> updatePatient(String uid, Map<String, dynamic> data) async {
    final idx = _patients.indexWhere((p) => p.uid == uid);
    if (idx == -1) throw Exception('Patient not found.');

    final old = _patients[idx];
    _patients[idx] = Patient(
      uid: old.uid,
      name: data['name'] ?? old.name,
      age: data['age'] ?? old.age,
      gender: data['gender'] ?? old.gender,
      phone: data['phone'] ?? old.phone,
      address: data['address'] ?? old.address,
      emergencyContact: data['emergencyContact'] ?? old.emergencyContact,
      caregiverName: old.caregiverName,
      caregiverPhone: old.caregiverPhone,
      medicalConditions: old.medicalConditions,
      allergies: old.allergies,
      deviceId: old.deviceId,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_patients', jsonEncode(_patients.map((p) => p.toJson()).toList()));

    addTelemetryLog('Caregiver updated patient profile: ${old.name}');
    notifyListeners();
  }

  Future<void> deletePatient(String uid) async {
    _patients.removeWhere((p) => p.uid == uid);

    // Remove patient from caregiver's list
    for (var caregiver in _caregivers) {
      caregiver.patientIds.remove(uid);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smartmed_patients', jsonEncode(_patients.map((p) => p.toJson()).toList()));
    await prefs.setString('smartmed_caregivers', jsonEncode(_caregivers.map((c) => c.toJson()).toList()));

    addTelemetryLog('Caregiver deleted patient ID: $uid');
    notifyListeners();
  }

  Future<void> setGracePeriod(int period) async {
    _gracePeriod = period;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('smartmed_grace_period', period);
    notifyListeners();
  }

  void _startMissedDoseCheckLoop() {
    _missedDoseTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkMissedDoses();
    });
  }

  Future<void> checkMissedDoses() async {
    final now = DateTime.now();
    bool updated = false;

    for (var reminder in _reminders) {
      if (reminder.status != 'Scheduled') continue;

      final dateParts = reminder.timestamp.split('-');
      final timeParts = reminder.scheduledTime.split(':');
      
      if (dateParts.length != 3 || timeParts.length != 2) continue;

      final scheduledDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final missedThreshold = scheduledDateTime.add(Duration(minutes: _gracePeriod));

      if (now.isAfter(missedThreshold)) {
        reminder.status = 'Missed';
        updated = true;

        final patient = _patients.firstWhere(
          (p) => p.uid == reminder.patientId,
          orElse: () => Patient(uid: reminder.patientId, name: 'Patient', age: 0, gender: '', phone: '', address: '', emergencyContact: '', caregiverName: 'Caregiver', caregiverPhone: '', medicalConditions: [], allergies: [], deviceId: '')
        );

        final caregiver = _caregivers.firstWhere(
          (cg) => cg.patientIds.contains(reminder.patientId) || cg.name == patient.caregiverName,
          orElse: () => Caregiver(uid: 'unassigned', name: 'No Caregiver Assigned', phone: '', email: '', patientIds: [], relationship: '')
        );

        final historyIndex = _missedDoseHistory.indexWhere((h) => h.id == reminder.id);
        final alreadyNotified = historyIndex != -1 && _missedDoseHistory[historyIndex].notificationSent;

        final historyEntry = MissedDoseRecord(
          id: reminder.id,
          patientId: reminder.patientId,
          patientName: patient.name,
          caregiverId: caregiver.uid,
          medicineId: reminder.medicineId,
          medicineName: reminder.medicineName,
          scheduledTime: scheduledDateTime.toIso8601String(),
          status: 'Missed',
          takenTime: null,
          missedTime: missedThreshold.toIso8601String(),
          notificationSent: true,
        );

        if (historyIndex != -1) {
          _missedDoseHistory[historyIndex] = MissedDoseRecord(
            id: reminder.id,
            patientId: reminder.patientId,
            patientName: patient.name,
            caregiverId: caregiver.uid,
            medicineId: reminder.medicineId,
            medicineName: reminder.medicineName,
            scheduledTime: scheduledDateTime.toIso8601String(),
            status: 'Missed',
            takenTime: null,
            missedTime: missedThreshold.toIso8601String(),
            notificationSent: true,
          );
        } else {
          _missedDoseHistory.add(historyEntry);
        }

        if (!alreadyNotified) {
          final notifId = 'notif-missed-${reminder.id}';
          final notif = AppNotification(
            id: notifId,
            userId: caregiver.uid,
            title: 'Missed Dose Alert: ${patient.name}',
            message: 'Missed Medication Alert:\n${patient.name} missed the scheduled ${reminder.medicineName} ${reminder.dosage} dose at ${reminder.scheduledTime}.',
            type: 'missed',
            timestamp: DateTime.now().toIso8601String(),
            read: false,
          );
          _notifications.insert(0, notif);
          addTelemetryLog('ALERT generated: Missed dose of ${reminder.medicineName} for patient ${patient.name}');
        }
      }
    }

    if (updated) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smartmed_reminders', jsonEncode(_reminders.map((r) => r.toJson()).toList()));
      await prefs.setString('smartmed_notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
      await prefs.setString('smartmed_missed_dose_history', jsonEncode(_missedDoseHistory.map((h) => h.toJson()).toList()));
      notifyListeners();
    }
  }
}
