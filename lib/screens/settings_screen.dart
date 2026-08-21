import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _telemetrySim = true;

  void _handleClearAlerts(BuildContext context) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user != null) {
      await db.clearNotifications(auth.user!.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portal notification logs cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final db = Provider.of<DatabaseService>(context);
    final isDark = theme.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(title: 'Portal Configuration'),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Theme config
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Theme Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Toggle dark slate dashboard mode.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) => theme.toggleTheme(),
                        activeThumbColor: const Color(0xff3b82f6),
                      ),
                    ),
                    const Divider(color: Colors.white10),

                    // Simulator toggle
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hardware Telemetry Simulator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Trigger periodic ping tests on weight sensors.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: Switch(
                        value: _telemetrySim,
                        onChanged: (val) {
                          setState(() {
                            _telemetrySim = val;
                          });
                        },
                        activeThumbColor: const Color(0xff3b82f6),
                      ),
                    ),
                    const Divider(color: Colors.white10),

                    // Grace Period configuration
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Missed Dose Grace Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text('Current: ${db.gracePeriod} minutes ${db.gracePeriod == 1 ? "(Testing)" : "(Default)"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChoiceChip(
                            label: const Text('30m', style: TextStyle(fontSize: 11)),
                            selected: db.gracePeriod == 30,
                            onSelected: (val) {
                              if (val) db.setGracePeriod(30);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('1m', style: TextStyle(fontSize: 11)),
                            selected: db.gracePeriod == 1,
                            onSelected: (val) {
                              if (val) db.setGracePeriod(1);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),

                    // Clear alerts list
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Clear System Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Empty all notification logs from user feed.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _handleClearAlerts(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.clear_all_rounded, size: 14),
                        label: const Text('Clear Warnings', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Compliance Banner details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff3b82f6).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xff3b82f6).withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.gpp_good_rounded, color: Color(0xff10b981), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'HIPAA Encryption Compliance',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xff3b82f6)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This client runs on SmartMed v1.0.0-HIPAA-IoT protocol. Session databases fall back dynamically to sandboxed local storage channels when Firebase cluster tokens are offline or unconfigured.',
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey[400] : Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
