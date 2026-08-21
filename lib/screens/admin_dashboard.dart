import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _deviceIdController = TextEditingController();
  String _error = '';
  String _success = '';
  String _activeAction = '';

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  void _handleRegisterDevice() async {
    setState(() {
      _error = '';
      _success = '';
    });

    final devId = _deviceIdController.text.trim();
    if (devId.isEmpty || !devId.startsWith('BOX-')) {
      setState(() {
        _error = 'Invalid ID. Device code must start with "BOX-" (e.g. BOX-7750).';
      });
      return;
    }

    final db = Provider.of<DatabaseService>(context, listen: false);
    if (db.devices.any((d) => d.deviceId == devId)) {
      setState(() {
        _error = 'Unit already exists in system inventory.';
      });
      return;
    }

    setState(() {
      _activeAction = 'register';
    });

    try {
      await db.registerDevice(devId);
      setState(() {
        _success = 'Device $devId provisioned successfully.';
        _deviceIdController.clear();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to provision device.';
      });
    } finally {
      setState(() {
        _activeAction = '';
      });
    }
  }

  void _handleRebootDevice(String deviceId) async {
    setState(() {
      _activeAction = deviceId;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    try {
      await db.rebootDevice(deviceId);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _activeAction = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final isDark = Provider.of<ThemeService>(context).isDarkMode;


    final totalUnits = db.devices.length;
    final registeredUnits = db.devices.where((d) => d.status == 'Registered').length;
    final patientsCount = db.patients.length;

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(title: 'Admin Operations Console'),

          // Counters Row / Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isWide ? 1.5 : 1.3,
            children: [
              _buildStatsCard('Monitored Patients', '$patientsCount', Icons.people_outline_rounded, const Color(0xff3b82f6), isDark),
              _buildStatsCard('Registered IoT Units', '$totalUnits', Icons.memory_rounded, const Color(0xff10b981), isDark, subtext: '$registeredUnits Active / ${totalUnits - registeredUnits} Unlinked'),
              _buildStatsCard('API Cluster Health', '99.9%', Icons.network_ping_rounded, const Color(0xff3b82f6), isDark, subtext: 'Latency: 42ms'),
              _buildStatsCard('HIPAA Status', 'SECURE', Icons.shield_rounded, const Color(0xff10b981), isDark, subtext: 'AES-256 standard'),
            ],
          ),
          const SizedBox(height: 32),

          // Action row: Register + Console logs
          LayoutBuilder(
            builder: (context, constraints) {
              final isPanelWide = constraints.maxWidth > 800;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Register card
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('PROVISION HARDWARE UNIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          const Text('Add raw device ID codes from SmartMed hardware packaging to authorize connections.', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3)),
                          const SizedBox(height: 16),

                          if (_error.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                              child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (_success.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xff10b981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                              child: Text(_success, style: const TextStyle(color: Color(0xff10b981), fontSize: 11)),
                            ),
                            const SizedBox(height: 12),
                          ],

                          TextField(
                            controller: _deviceIdController,
                            decoration: InputDecoration(
                              hintText: 'BOX-XXXX (e.g. BOX-7750)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            onPressed: _activeAction == 'register' ? null : _handleRegisterDevice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff3b82f6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: _activeAction == 'register'
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Register Hardware Box', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Telemetry terminal stream console
                  Expanded(
                    flex: isPanelWide ? 2 : 1,
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.terminal_rounded, color: Color(0xff3b82f6), size: 18),
                                  SizedBox(width: 8),
                                  Text('Active Device Telemetry Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                                child: const Text('PAGER=cat', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 170,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: db.telemetryLogs.isEmpty
                                ? const Center(child: Text('Initializing secure telemetry logs stream...\nAwaiting pings...', style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4), textAlign: TextAlign.center))
                                : ListView.builder(
                                    itemCount: db.telemetryLogs.length,
                                    itemBuilder: (context, idx) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6.0),
                                        child: Text(
                                          db.telemetryLogs[idx],
                                          style: const TextStyle(
                                            color: Color(0xff10b981),
                                            fontFamily: 'Courier',
                                            fontSize: 10.5,
                                            height: 1.3,
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

          // Telemetry List Table
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.developer_board_rounded, color: Color(0xff10b981), size: 18),
                    SizedBox(width: 8),
                    Text('Hardware Units & Dispatch Operations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ],
                ),
                const SizedBox(height: 16),

                // Table Layout
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: isWide ? 80 : 30,
                    columns: const [
                      DataColumn(label: Text('Hardware Device ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                      DataColumn(label: Text('Patient Assignee', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                      DataColumn(label: Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                      DataColumn(label: Text('Battery Level', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    ],
                    rows: db.devices.map((device) {
                      final patient = db.patients.firstWhere(
                        (p) => p.uid == device.patientId,
                        orElse: () => Patient(uid: '', name: 'Not Assigned', age: 0, gender: '', phone: '', address: '', emergencyContact: '', caregiverName: '', caregiverPhone: '', medicalConditions: [], allergies: [], deviceId: ''),
                      );

                      final isRegistered = device.status == 'Registered';

                      return DataRow(
                        cells: [
                          DataCell(Text(device.deviceId, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff3b82f6), fontSize: 12.5))),
                          DataCell(Text(patient.name, style: TextStyle(fontSize: 12.5, fontStyle: patient.uid.isEmpty ? FontStyle.italic : FontStyle.normal, color: patient.uid.isEmpty ? Colors.grey : null))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isRegistered ? const Color(0xff10b981).withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isRegistered ? const Color(0xff10b981).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Text(
                                isRegistered ? 'REGISTERED' : 'UNLINKED',
                                style: TextStyle(color: isRegistered ? const Color(0xff10b981) : Colors.grey, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataCell(Text('${device.batteryLevel}%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: device.batteryLevel < 30 ? Colors.redAccent : null))),
                          DataCell(
                            ElevatedButton.icon(
                              onPressed: _activeAction == device.deviceId ? null : () => _handleRebootDevice(device.deviceId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              icon: Icon(Icons.refresh, size: 12, color: isDark ? Colors.white70 : Colors.black87),
                              label: _activeAction == device.deviceId
                                  ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Reboot Unit', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String label, String val, IconData icon, Color iconColor, bool isDark, {String? subtext}) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                if (subtext != null) ...[
                  const SizedBox(height: 4),
                  Text(subtext, style: const TextStyle(fontSize: 9, color: Colors.grey, overflow: TextOverflow.ellipsis)),
                ],
              ],
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withValues(alpha: 0.1),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ],
      ),
    );
  }
}
