import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';


class DashboardHeader extends StatelessWidget {
  final String title;

  const DashboardHeader({super.key, required this.title});

  void _showNotifications(BuildContext context) {

    final authService = Provider.of<AuthService>(context, listen: false);
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final uid = authService.user?.uid ?? '';



    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Re-fetch notifications within bottom sheet
            final db = Provider.of<DatabaseService>(context);
            final notifs = db.notifications
                .where((n) => n.userId == uid || n.userId == 'all')
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff0f172a) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Bottom Sheet Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_active_rounded, color: Color(0xff3b82f6), size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Notifications',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      if (notifs.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            db.clearNotifications(uid);
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notifications list
                  Expanded(
                    child: notifs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none_rounded, color: Colors.grey[600], size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  'No active notifications',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: notifs.length,
                            itemBuilder: (context, idx) {
                              final notif = notifs[idx];
                              
                              IconData icon = Icons.info_rounded;
                              Color iconColor = Colors.grey;
                              Color itemBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02);

                              if (!notif.read) {
                                if (notif.type == 'emergency') {
                                  icon = Icons.warning_amber_rounded;
                                  iconColor = Colors.redAccent;
                                  itemBg = Colors.redAccent.withValues(alpha: 0.08);
                                } else if (notif.type == 'low_stock') {
                                  icon = Icons.report_problem_rounded;
                                  iconColor = Colors.orangeAccent;
                                  itemBg = Colors.orangeAccent.withValues(alpha: 0.08);
                                } else {
                                  icon = Icons.medication_rounded;
                                  iconColor = const Color(0xff3b82f6);
                                  itemBg = const Color(0xff3b82f6).withValues(alpha: 0.08);
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: itemBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(icon, color: iconColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: isDark ? Colors.white : Colors.black87,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!notif.read)
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xff10b981)),
                                                  onPressed: () {
                                                    db.markNotificationRead(notif.id);
                                                    setModalState(() {});
                                                  },
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: const TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.4),
                                          ),
                                        ],
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);
    
    final uid = authService.user?.uid ?? '';
    final unreadCount = dbService.notifications
        .where((n) => (n.userId == uid || n.userId == 'all') && !n.read)
        .length;

    final isDark = themeService.isDarkMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Screen Title or Hamburger toggle for mobile
          Row(
            children: [
              if (MediaQuery.of(context).size.width <= 900) ...[
                IconButton(
                  icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black87),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Action center
          Row(
            children: [
              // Theme Toggle
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? Colors.amberAccent : Colors.indigo,
                  size: 22,
                ),
                onPressed: themeService.toggleTheme,
              ),
              const SizedBox(width: 8),

              // Notification Bell
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_rounded,
                      color: isDark ? Colors.grey[300] : Colors.black54,
                      size: 22,
                    ),
                    onPressed: () => _showNotifications(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              
              if (authService.user != null) ...[
                const SizedBox(width: 12),
                // User Chip Profile Initials
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xff3b82f6).withValues(alpha: 0.1),
                  child: Text(
                    authService.user!.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff3b82f6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
