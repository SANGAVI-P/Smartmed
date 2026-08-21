import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthService extends ChangeNotifier {
  UserSession? _user;
  bool _loading = true;

  UserSession? get user => _user;
  bool get loading => _loading;

  AuthService() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString('smartmed_session');
    if (sessionStr != null) {
      _user = UserSession.fromJson(jsonDecode(sessionStr));
    }
    _loading = false;
    notifyListeners();
  }

  String _getRoleFromEmail(String email) {
    final cleanEmail = email.toLowerCase();
    if (cleanEmail.contains('admin')) return 'admin';
    if (cleanEmail.contains('caregiver')) return 'caregiver';
    return 'patient';
  }

  Future<UserSession> login(String email, String password, String selectedRole) async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersStr = prefs.getString('smartmed_users') ?? '[]';
      final List<dynamic> usersJson = jsonDecode(usersStr);
      
      var existingUser = usersJson.firstWhere(
        (u) => u['email'].toString().toLowerCase() == email.toLowerCase(),
        orElse: () => null,
      );

      if (existingUser != null) {
        if (existingUser['password'] != password) {
          throw Exception('Invalid credentials. Password mismatch.');
        }
        
        final dbRole = existingUser['role'].toString().toLowerCase();
        if (dbRole != selectedRole.toLowerCase()) {
          throw Exception('Access denied. This account is registered as $dbRole.');
        }
        
        final session = UserSession(
          uid: existingUser['uid'],
          email: existingUser['email'],
          name: existingUser['name'],
          role: existingUser['role'],
        );

        await prefs.setString('smartmed_session', jsonEncode(session.toJson()));
        _user = session;
        _loading = false;
        notifyListeners();
        return session;
      } else {
        // Auto-provision user for ease of evaluation using the selectedRole!
        final role = selectedRole.toLowerCase();
        final nameParts = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z]'), ' ');
        final cleanName = nameParts.trim().isEmpty ? 'SmartMed User' : nameParts.trim();
        final name = cleanName[0].toUpperCase() + cleanName.substring(1);
        
        final uid = 'mock-${DateTime.now().millisecondsSinceEpoch}';
        
        final newUser = {
          'uid': uid,
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        };

        usersJson.add(newUser);
        await prefs.setString('smartmed_users', jsonEncode(usersJson));

        // Create clean profile for the user
        if (role == 'patient') {
          final patientsStr = prefs.getString('smartmed_patients') ?? '[]';
          final List<dynamic> patientsJson = jsonDecode(patientsStr);
          patientsJson.add({
            'uid': uid,
            'name': name,
            'age': 0,
            'gender': 'Not specified',
            'phone': '',
            'address': '',
            'emergencyContact': '',
            'caregiverName': '',
            'caregiverPhone': '',
            'medicalConditions': [],
            'allergies': [],
            'deviceId': '',
          });
          await prefs.setString('smartmed_patients', jsonEncode(patientsJson));
        } else if (role == 'caregiver') {
          final caregiversStr = prefs.getString('smartmed_caregivers') ?? '[]';
          final List<dynamic> caregiversJson = jsonDecode(caregiversStr);
          caregiversJson.add({
            'uid': uid,
            'name': name,
            'phone': '',
            'email': email,
            'patientIds': [],
            'relationship': 'Caregiver',
          });
          await prefs.setString('smartmed_caregivers', jsonEncode(caregiversJson));
        }

        final session = UserSession(
          uid: uid,
          email: email,
          name: name,
          role: role,
        );

        await prefs.setString('smartmed_session', jsonEncode(session.toJson()));
        _user = session;
        _loading = false;
        notifyListeners();
        return session;
      }
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<UserSession> register(
    String role,
    String email,
    String password,
    Map<String, dynamic> additionalData,
  ) async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersStr = prefs.getString('smartmed_users') ?? '[]';
      final List<dynamic> usersJson = jsonDecode(usersStr);

      if (usersJson.any((u) => u['email'].toString().toLowerCase() == email.toLowerCase())) {
        throw Exception('A user with this email address already exists.');
      }

      final uid = 'mock-${DateTime.now().millisecondsSinceEpoch}';
      final displayName = additionalData['name'] ?? 'SmartMed User';
      final computedRole = _getRoleFromEmail(email);
      final finalRole = computedRole == 'admin' ? 'admin' : role;

      final newUser = {
        'uid': uid,
        'email': email,
        'password': password,
        'name': displayName,
        'role': finalRole,
      };

      usersJson.add(newUser);
      await prefs.setString('smartmed_users', jsonEncode(usersJson));

      if (finalRole == 'patient') {
        final patientsStr = prefs.getString('smartmed_patients') ?? '[]';
        final List<dynamic> patientsJson = jsonDecode(patientsStr);
        
        patientsJson.add({
          'uid': uid,
          'name': displayName,
          'age': int.tryParse(additionalData['age']?.toString() ?? '') ?? 70,
          'gender': additionalData['gender'] ?? 'Not specified',
          'phone': additionalData['phone'] ?? '',
          'address': additionalData['address'] ?? '',
          'emergencyContact': additionalData['emergencyContact'] ?? '',
          'caregiverName': additionalData['caregiverName'] ?? '',
          'caregiverPhone': additionalData['caregiverPhone'] ?? '',
          'medicalConditions': additionalData['medicalConditions'] != null
              ? additionalData['medicalConditions'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
              : [],
          'allergies': additionalData['allergies'] != null
              ? additionalData['allergies'].toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
              : [],
          'deviceId': additionalData['deviceId'] ?? '',
        });
        await prefs.setString('smartmed_patients', jsonEncode(patientsJson));

        // Mark device as Registered
        final deviceId = additionalData['deviceId'] ?? '';
        if (deviceId.isNotEmpty) {
          final devicesStr = prefs.getString('smartmed_devices') ?? '[]';
          final List<dynamic> devicesJson = jsonDecode(devicesStr);
          var devIdx = devicesJson.indexWhere((d) => d['deviceId'] == deviceId);
          if (devIdx != -1) {
            devicesJson[devIdx]['status'] = 'Registered';
            devicesJson[devIdx]['patientId'] = uid;
            devicesJson[devIdx]['lastSyncTime'] = DateTime.now().toIso8601String();
            devicesJson[devIdx]['updatedAt'] = DateTime.now().toIso8601String();
          } else {
            devicesJson.add({
              'id': deviceId,
              'deviceId': deviceId,
              'status': 'Registered',
              'patientId': uid,
              'batteryLevel': 100,
              'lastSyncTime': DateTime.now().toIso8601String(),
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
          await prefs.setString('smartmed_devices', jsonEncode(devicesJson));
        }
      } else if (finalRole == 'caregiver') {
        final caregiversStr = prefs.getString('smartmed_caregivers') ?? '[]';
        final List<dynamic> caregiversJson = jsonDecode(caregiversStr);
        caregiversJson.add({
          'uid': uid,
          'name': displayName,
          'phone': additionalData['phone'] ?? '',
          'email': email,
          'patientIds': [],
          'relationship': additionalData['relationship'] ?? 'Caregiver',
        });
        await prefs.setString('smartmed_caregivers', jsonEncode(caregiversJson));
      }

      final session = UserSession(
        uid: uid,
        email: email,
        name: displayName,
        role: finalRole,
      );

      await prefs.setString('smartmed_session', jsonEncode(session.toJson()));
      _user = session;
      _loading = false;
      notifyListeners();
      return session;
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('smartmed_session');
    _user = null;
    _loading = false;
    notifyListeners();
  }
}
