import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/add_patient_dialog.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({super.key});

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  String _selectedPatientId = 'mock-patient';
  final _refillController = TextEditingController(text: '30');
  String? _refillMedId;
  bool _loadingRefill = false;

  @override
  void dispose() {
    _refillController.dispose();
    super.dispose();
  }

  void _handleRefillSubmit(BuildContext context) async {
    if (_refillMedId == null) return;
    setState(() {
      _loadingRefill = true;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final qty = int.tryParse(_refillController.text) ?? 30;
    try {
      await db.refillMedicine(_refillMedId!, qty);
      setState(() {
        _refillMedId = null;
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _loadingRefill = false;
      });
    }
  }

  void _handleSOSDismiss(String patientId) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    try {
      await db.dismissSOS(patientId);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final isDark = Provider.of<ThemeService>(context).isDarkMode;


    if (db.patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Monitored Patients Registered',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please register a patient in the system to monitor their compliance and scheduling.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddPatientDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff10b981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Patient Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    // Load selected patient profile
    final patient = db.patients.firstWhere(
      (p) => p.uid == _selectedPatientId,
      orElse: () => db.patients[0],
    );
    final patientUid = patient.uid;

    if (_selectedPatientId == 'mock-patient' || !db.patients.any((p) => p.uid == _selectedPatientId)) {
      _selectedPatientId = patientUid;
    }

    final patientDevice = db.devices.firstWhere(
      (d) => d.deviceId == patient.deviceId || d.patientId == patientUid,
      orElse: () => Device(id: 'None', deviceId: 'None', status: 'Unlinked', patientId: patientUid, batteryLevel: 0, lastSyncTime: '', createdAt: '', updatedAt: ''),
    );

    final isSosActive = db.notifications.any((n) => n.userId == patientUid && n.type == 'emergency' && !n.read);

    final patientMeds = db.medicines.where((m) => m.patientId == patientUid).toList();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final patientReminders = db.reminders.where((r) => r.patientId == patientUid && r.timestamp == todayStr).toList();

    int totalScheduledPills = 0;
    int totalTakenPills = 0;
    for (var r in patientReminders) {
      totalScheduledPills += r.scheduledPills;
      totalTakenPills += r.takenPills;
    }
    final complianceRate = totalScheduledPills > 0 ? (totalTakenPills / totalScheduledPills) : 1.0;

    // Timeline calculation
    final List<Map<String, String>> timeline = [];
    for (var r in patientReminders) {
      if (r.takenPills > 0 && r.time != null) {
        timeline.add({
          'time': r.time!,
          'event': '${r.medicineName} (${r.takenPills}/${r.scheduledPills} pills taken) by patient',
          'type': 'taken',
        });
      }
    }

    final missedRems = patientReminders.where((r) => r.status == 'Missed').toList();
    for (var r in missedRems) {
      timeline.add({
        'time': r.scheduledTime,
        'event': '${r.medicineName} missed (Scheduled: ${r.scheduledTime}, ${r.scheduledPills} pills)',
        'type': 'missed',
      });
    }
    timeline.sort((a, b) => b['time']!.compareTo(a['time']!));



    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(title: 'Caregiver Dashboard'),

          // SOS Critical alarm banner
          if (isSosActive) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.emergency_share_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL: SOS Distress Alarm from ${patient.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.redAccent),
                        ),
                        Text(
                          'Distress beacon is active. Check home address: ${patient.address}.',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Simulating call connection to ${patient.phone}...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff3b82f6), foregroundColor: Colors.white),
                    icon: const Icon(Icons.phone_rounded, size: 14),
                    label: Text('Call Patient (${patient.phone})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _handleSOSDismiss(patientUid),
                    child: const Text('Dismiss Alarm', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Title & Patient dropdown selector row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Caregiver Adherence Console',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Text('PATIENT: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _selectedPatientId,
                    dropdownColor: isDark ? const Color(0xff0f172a) : Colors.white,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    items: db.patients.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.uid,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPatientId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddPatientDialog(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff10b981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Add Patient', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Compliance rate gauge & demographics grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isGridWide = constraints.maxWidth > 700;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular gauge painter card
                  Expanded(
                    child: GlassCard(
                      height: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('TODAY\'S ADHERENCE RATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(complianceRate * 100).round()}%',
                                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xff3b82f6)),
                                ),
                                const Text('Adhered', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('Scheduled', '$totalScheduledPills', Colors.grey),
                              _buildStatItem('Taken', '$totalTakenPills', const Color(0xff10b981)),
                              _buildStatItem('Remaining', '${totalScheduledPills - totalTakenPills}', Colors.orangeAccent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Patient metrics demographics card
                  Expanded(
                    flex: isGridWide ? 2 : 1,
                    child: GlassCard(
                      height: 250,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, color: Color(0xff3b82f6), size: 18),
                                  SizedBox(width: 8),
                                  Text('Patient Profile & Demographics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                ],
                              ),
                              Text('UID: ${patient.uid}', style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontFamily: 'Courier')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: isGridWide ? 2 : 1,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 8,
                              childAspectRatio: isGridWide ? 4.0 : 6.0,
                              children: [
                                _buildMetricRow('Patient', '${patient.name} (${patient.age} y/o, ${patient.gender})'),
                                _buildMetricRow('Address Location', patient.address),
                                _buildMetricRow('Emergency Contacts', patient.emergencyContact),
                                _buildConditionsRow('Conditions', patient.medicalConditions),
                                _buildAllergiesRow('Drug Allergies', patient.allergies),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.settings_remote_outlined, color: Color(0xff10b981), size: 14),
                                  const SizedBox(width: 6),
                                  Text('Device: ${patientDevice.deviceId}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text('Battery Level: ${patientDevice.batteryLevel}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Timeline and Refill Pipeline row
          LayoutBuilder(
            builder: (context, constraints) {

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline logs
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_toggle_off_rounded, color: Color(0xff3b82f6)),
                              SizedBox(width: 8),
                              Text('Live Adherence Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: timeline.isEmpty
                                ? const Center(child: Text('No adherence logs recorded for today.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: timeline.length,
                                    itemBuilder: (context, idx) {
                                      final item = timeline[idx];
                                      final isTaken = item['type'] == 'taken';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                              color: isTaken ? const Color(0xff10b981) : Colors.redAccent,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(item['time']!, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontFamily: 'Courier')),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                item['event']!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isTaken ? Colors.grey[400] : Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Refill list pipeline
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.medication_liquid_sharp, color: Color(0xff10b981)),
                              SizedBox(width: 8),
                              Text('Low Stock Refill Pipeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: patientMeds.isEmpty
                                ? const Center(child: Text('No medication scheduler logs configured.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: patientMeds.length,
                                    itemBuilder: (context, idx) {
                                      final med = patientMeds[idx];
                                      final isLow = med.quantity < 7;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isLow ? Colors.orangeAccent.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.01),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isLow ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.medication_rounded, color: isLow ? Colors.orangeAccent : Colors.grey, size: 18),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                                      Text(
                                                        'Stock: ${med.quantity} / ${med.initialQuantity}',
                                                        style: TextStyle(
                                                          fontSize: 9.5, 
                                                          color: isLow ? Colors.orangeAccent : Colors.grey,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _refillMedId = med.id;
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isLow ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.08),
                                                  foregroundColor: isLow ? Colors.white : Colors.grey[350],
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text('Refill', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Missed Doses History Log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                db.missedDoseHistory.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: Text(
                            'No missed doses recorded.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      )
                    : Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(2.0),
                          3: FlexColumnWidth(2.0),
                          4: FlexColumnWidth(1.0),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
                            ),
                            children: [
                              Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Patient', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Medication', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Scheduled Time', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Missed Time', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Status', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                            ],
                          ),
                          ...db.missedDoseHistory.map((record) {
                            final schedDateTime = DateTime.parse(record.scheduledTime).toLocal();
                            final schedStr = '${schedDateTime.year}-${schedDateTime.month.toString().padLeft(2, '0')}-${schedDateTime.day.toString().padLeft(2, '0')} ${schedDateTime.hour.toString().padLeft(2, '0')}:${schedDateTime.minute.toString().padLeft(2, '0')}';
                            
                            final missedDateTime = DateTime.parse(record.missedTime).toLocal();
                            final missedStr = '${missedDateTime.year}-${missedDateTime.month.toString().padLeft(2, '0')}-${missedDateTime.day.toString().padLeft(2, '0')} ${missedDateTime.hour.toString().padLeft(2, '0')}:${missedDateTime.minute.toString().padLeft(2, '0')}';

                            final isTaken = record.status == 'Taken';

                            return TableRow(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text(record.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text(record.medicineName, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text(schedStr, style: const TextStyle(fontSize: 10.5, fontFamily: 'Courier', color: Colors.grey)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text(missedStr, style: const TextStyle(fontSize: 10.5, fontFamily: 'Courier', color: Colors.grey)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isTaken
                                            ? const Color(0xff10b981).withValues(alpha: 0.1)
                                            : Colors.redAccent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isTaken ? 'Taken (Late)' : 'Missed',
                                        style: TextStyle(
                                          color: isTaken ? const Color(0xff10b981) : Colors.redAccent,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    ),
        if (_refillMedId != null)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: AlertDialog(
              backgroundColor: const Color(0xff0f172a),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Refill Medication Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure stock update quantity for ${db.medicines.firstWhere((m) => m.id == _refillMedId).name}.',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pill Refill Volume (Tablets)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _refillController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _refillMedId = null),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: _loadingRefill ? null : () => _handleRefillSubmit(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff10b981)),
                  child: _loadingRefill
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Refill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.w900, fontSize: 13.5)),
      ],
    );
  }

  Widget _buildMetricRow(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildConditionsRow(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Wrap(
          spacing: 4,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xff3b82f6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item, style: const TextStyle(color: Color(0xff3b82f6), fontSize: 8, fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAllergiesRow(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Wrap(
          spacing: 4,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(item, style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// Custom compliance painter for adherence circular gauge
// ----------------------------------------------------
class CompliancePainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;

  CompliancePainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 6;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    final angle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      angle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
