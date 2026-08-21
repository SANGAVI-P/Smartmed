import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';

class PatientDashboard extends StatefulWidget {
  final String? patientId;
  const PatientDashboard({super.key, this.patientId});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  bool _loading = false;
  String _activeAction = '';

  @override
  void initState() {
    super.initState();
    // Auto-generate reminders on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final currentPatientId = widget.patientId ?? auth.user?.uid;
      if (currentPatientId != null) {
        db.generateRemindersForDay(currentPatientId, todayStr);
      }
    });
  }



  void _handleSOSConfirm(String patientId) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    setState(() {
      _loading = true;
    });
    try {
      await db.triggerSOS(patientId);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _handleSOSDismiss(String patientId) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    setState(() {
      _activeAction = 'dismiss-sos';
    });
    try {
      await db.dismissSOS(patientId);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _activeAction = '';
      });
    }
  }

  void _showSOSDialog(BuildContext context, String patientId, String caregiverName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff0f172a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Confirm Distress SOS?', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'This will trigger a flashing notification banner and dispatch logs to nurse $caregiverName immediately.',
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: _loading ? null : () => _handleSOSConfirm(patientId),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: _loading 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Yes, Send SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    final user = auth.user;
    final currentPatientId = widget.patientId ?? user?.uid;
    final patient = db.patients.firstWhere(
      (p) => p.uid == currentPatientId,
      orElse: () => db.patients.isNotEmpty ? db.patients[0] : Patient(uid: '', name: 'No Patient Profile', age: 0, gender: 'Not specified', phone: '', address: '', emergencyContact: '', caregiverName: '', caregiverPhone: '', medicalConditions: [], allergies: [], deviceId: ''),
    );

    final patientUid = patient.uid;
    final isSosActive = db.notifications.any((n) => n.userId == patientUid && n.type == 'emergency' && !n.read);

    final patientDevice = db.devices.firstWhere(
      (d) => d.deviceId == patient.deviceId || d.patientId == patientUid,
      orElse: () => Device(id: 'None', deviceId: 'None', status: 'Unlinked', patientId: patientUid, batteryLevel: 0, lastSyncTime: '', createdAt: '', updatedAt: ''),
    );

    final patientMeds = db.medicines.where((m) => m.patientId == patientUid).toList();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final patientReminders = db.reminders.where((r) => r.patientId == patientUid && r.timestamp == todayStr).toList();

    final morningRems = patientReminders.where((r) => r.timeOfDay == 'morning').toList();
    final afternoonRems = patientReminders.where((r) => r.timeOfDay == 'afternoon').toList();
    final nightRems = patientReminders.where((r) => r.timeOfDay == 'night').toList();

    int totalScheduledPills = 0;
    int totalTakenPills = 0;
    for (var r in patientReminders) {
      totalScheduledPills += r.scheduledPills;
      totalTakenPills += r.takenPills;
    }
    final complianceRate = totalScheduledPills > 0 ? (totalTakenPills / totalScheduledPills) : 1.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(title: 'Patient Dashboard'),

          // SOS Beacon active warning header
          if (isSosActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emergency Distress Beacon Active',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                        ),
                        Text(
                          'Emergency alerts sent to caregiver ${patient.caregiverName} (${patient.caregiverPhone}).',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _activeAction == 'dismiss-sos' ? null : () => _handleSOSDismiss(patientUid),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
                    child: _activeAction == 'dismiss-sos'
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Dismiss Alarm', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Greeting Banner Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xff1e293b).withValues(alpha: 0.4), const Color(0xff0f172a).withValues(alpha: 0.4)]
                    : [Colors.blue.withValues(alpha: 0.06), Colors.teal.withValues(alpha: 0.04)],
              ),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Color(0xff3b82f6), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Telemetry Portal Connection Secure',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xff3b82f6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome back, ${patient.name}!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your IoT medication dispenser is connected. Below is your schedule. Remember to check your inventory counts.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Widgets row (Device status, compliance summary, SOS trigger)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: isWide ? 1.6 : 2.0,
                children: [
                  // Device status widget
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('IoT DEVICE STATUS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xff10b981).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xff10b981).withValues(alpha: 0.12)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.wifi, color: Color(0xff10b981), size: 12),
                                  SizedBox(width: 4),
                                  Text('Online', style: TextStyle(color: Color(0xff10b981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(patientDevice.deviceId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff3b82f6))),
                        Text(
                          'Last Sync: ${patientDevice.lastSyncTime.isNotEmpty ? patientDevice.lastSyncTime.split('T')[1].substring(0, 5) : 'Never'}',
                          style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        Row(
                          children: [
                            Icon(Icons.battery_std_rounded, color: patientDevice.batteryLevel > 20 ? Colors.green : Colors.red, size: 14),
                            const SizedBox(width: 4),
                            Text('Battery: ${patientDevice.batteryLevel}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Compliance overview widget
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TODAY\'S PROGRESS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('$totalTakenPills', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xff10b981))),
                            const Text(' / ', style: TextStyle(color: Colors.grey)),
                            Text('$totalScheduledPills', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(width: 8),
                            const Text('pills taken', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        LinearProgressIndicator(
                          value: complianceRate,
                          backgroundColor: Colors.white10,
                          color: const Color(0xff10b981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        Text('Compliance: ${totalScheduledPills > 0 ? (complianceRate * 100).round() : 100}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),

                  // Distress SOS trigger widget
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('EMERGENCY SOS BEACON', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const Text(
                          'Need help? Alert your emergency contacts.',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey),
                        ),
                        ElevatedButton.icon(
                          onPressed: isSosActive ? null : () => _showSOSDialog(context, patientUid, patient.caregiverName),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.warning_amber_rounded, size: 16),
                          label: Text(
                            isSosActive ? 'SOS Paged' : 'TRIGGER EMERGENCY SOS',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Routine slots & Inventories Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Morning, Afternoon, Night reminders slots
                  Expanded(
                    flex: isWide ? 2 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.alarm_on_rounded, color: Color(0xff3b82f6)),
                            SizedBox(width: 8),
                            Text('Today\'s Medication Routine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTimeSlotCard('Morning Routine', '08:00 AM', morningRems, patientMeds),
                        const SizedBox(height: 16),
                        _buildTimeSlotCard('Afternoon Routine', '01:00 PM', afternoonRems, patientMeds),
                        const SizedBox(height: 16),
                        _buildTimeSlotCard('Night Routine', '08:00 PM', nightRems, patientMeds),

                        if (patientReminders.isEmpty)
                          const GlassCard(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'No medication items configured for today.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  if (isWide) const SizedBox(width: 24),
                  
                  // Side stock inventories tracker
                  if (isWide)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Color(0xff10b981)),
                              SizedBox(width: 8),
                              Text('Inventory Count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInventoryCard(patientMeds),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          // For mobile layouts, append inventory tracker at bottom
          if (MediaQuery.of(context).size.width <= 800) ...[
            const SizedBox(height: 32),
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: Color(0xff10b981)),
                SizedBox(width: 8),
                Text('Inventory Count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildInventoryCard(patientMeds),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case 'Taken':
        bg = const Color(0xff10b981).withValues(alpha: 0.1);
        fg = const Color(0xff10b981);
        icon = Icons.check_circle_rounded;
        break;
      case 'Missed':
        bg = Colors.redAccent.withValues(alpha: 0.1);
        fg = Colors.redAccent;
        icon = Icons.cancel_rounded;
        break;
      case 'Scheduled':
      default:
        bg = Colors.grey.withValues(alpha: 0.1);
        fg = Colors.grey;
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 10.5),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _handleMarkTaken(String reminderId) async {
    setState(() {
      _activeAction = reminderId;
    });
    final db = Provider.of<DatabaseService>(context, listen: false);
    try {
      await db.takeScheduledPill(reminderId);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _activeAction = '';
      });
    }
  }

  Widget _buildTimeSlotCard(String title, String timeStr, List<Reminder> rems, List<Medicine> meds) {
    if (rems.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
              Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff3b82f6))),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rems.length,
            separatorBuilder: (context, idx) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final rem = rems[idx];
              final med = meds.firstWhere((m) => m.id == rem.medicineId, orElse: () => Medicine(id: '', patientId: '', name: '', dosage: '', schedule: {}, timing: '', startDate: '', endDate: '', quantity: 0, initialQuantity: 0, times: {}));
              final isBeforeFood = med.timing == 'before_food';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: rem.takenPills == rem.scheduledPills
                      ? const Color(0xff10b981).withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: rem.takenPills == rem.scheduledPills
                        ? const Color(0xff10b981).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: rem.takenPills == rem.scheduledPills
                                  ? const Color(0xff10b981).withValues(alpha: 0.1)
                                  : const Color(0xff3b82f6).withValues(alpha: 0.1),
                              child: Icon(Icons.medication_rounded,
                                  color: rem.takenPills == rem.scheduledPills ? const Color(0xff10b981) : const Color(0xff3b82f6),
                                  size: 16),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rem.medicineName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text('Dosage: ${rem.dosage}', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isBeforeFood ? 'Before Food' : 'After Food',
                                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildStatusBadge(rem.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Scheduled: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('${rem.scheduledPills}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                const Text('Taken: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('${rem.takenPills}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rem.takenPills > 0 ? const Color(0xff10b981) : Colors.grey)),
                                const SizedBox(width: 12),
                                const Text('Remaining: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('${rem.remainingPills}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rem.remainingPills > 0 ? Colors.orangeAccent : Colors.grey)),
                              ],
                            ),
                            if (rem.takenPills == rem.scheduledPills && rem.time != null) ...[
                              const SizedBox(height: 4),
                              Text('Dose Taken @ ${rem.time}', style: const TextStyle(fontSize: 9.5, color: Color(0xff10b981), fontFamily: 'Courier')),
                            ],
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: (rem.takenPills >= rem.scheduledPills || _activeAction == rem.id)
                              ? null
                              : () => _handleMarkTaken(rem.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff3b82f6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _activeAction == rem.id
                              ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                              : const Icon(Icons.add_circle_outline_rounded, size: 12),
                          label: Text(
                            rem.takenPills >= rem.scheduledPills ? 'Taken' : 'Mark 1 Pill Taken',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(List<Medicine> meds) {
    return GlassCard(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: meds.length,
        separatorBuilder: (context, idx) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final med = meds[idx];
          final isLow = med.quantity < 7;
          final pct = med.initialQuantity > 0 ? (med.quantity / med.initialQuantity) : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    '${med.quantity} / ${med.initialQuantity} tablets',
                    style: TextStyle(color: isLow ? Colors.orangeAccent : Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: min(1.0, pct),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: isLow ? Colors.orangeAccent : const Color(0xff3b82f6),
                ),
              ),
              if (isLow) ...[
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: Colors.orangeAccent, size: 12),
                    SizedBox(width: 4),
                    Text('Low stock warning! Refill required.', style: TextStyle(color: Colors.orangeAccent, fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
