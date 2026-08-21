import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';

import '../screens/patient_dashboard.dart';
import '../screens/caregiver_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/medicines_screen.dart';
import '../screens/prescriptions_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/patients_screen.dart';

class ResponsiveLayout extends StatefulWidget {
  const ResponsiveLayout({super.key});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _getDashboardScreen(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'caregiver':
        return const CaregiverDashboard();
      default:
        return const PatientDashboard();
    }
  }

  Widget _getScreen(int index, String role) {
    final isCgOrAdmin = role == 'caregiver' || role == 'admin';
    if (isCgOrAdmin) {
      switch (index) {
        case 0:
          return _getDashboardScreen(role);
        case 1:
          return const PatientsScreen();
        case 2:
          return const MedicinesScreen();
        case 3:
          return const PrescriptionsScreen();
        case 4:
          return const ProfileScreen();
        case 5:
          return const SettingsScreen();
        default:
          return _getDashboardScreen(role);
      }
    } else {
      switch (index) {
        case 0:
          return _getDashboardScreen(role);
        case 1:
          return const MedicinesScreen();
        case 2:
          return const PrescriptionsScreen();
        case 3:
          return const ProfileScreen();
        case 4:
          return const SettingsScreen();
        default:
          return _getDashboardScreen(role);
      }
    }
  }

  void _onMenuItemClick(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    
    if (authService.user == null) {
      return const SizedBox.shrink(); // Handled by root navigator redirection
    }

    final user = authService.user!;
    final isDark = themeService.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    final role = user.role;
    final isCgOrAdmin = role == 'caregiver' || role == 'admin';

    final menuItems = [
      {'name': 'Dashboard', 'icon': Icons.dashboard_rounded},
      if (isCgOrAdmin)
        {'name': 'Patients', 'icon': Icons.people_rounded},
      {'name': 'Medicines', 'icon': Icons.medication_rounded},
      {'name': 'Prescriptions', 'icon': Icons.description_rounded},
      {'name': 'Profile', 'icon': Icons.person_rounded},
      {'name': 'Settings', 'icon': Icons.settings_rounded},
    ];

    Widget buildSidebar() {
      final textTheme = Theme.of(context).textTheme;
      return Container(
        width: 260,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff121b2d).withValues(alpha: 0.9) : Colors.white,
          border: Border(
            right: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding Logo
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xff3b82f6), Color(0xff10b981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff3b82f6).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartMed',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'SYSTEMS',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Navigation List
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, idx) {
                  final item = menuItems[idx];
                  final isSelected = _currentIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () => _onMenuItemClick(idx),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xff3b82f6).withValues(alpha: 0.15),
                                    const Color(0xff10b981).withValues(alpha: 0.05),
                                  ],
                                )
                              : null,
                          border: isSelected
                              ? Border(
                                  left: BorderSide(
                                    color: const Color(0xff3b82f6),
                                    width: 4,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xff3b82f6)
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item['name'] as String,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xff3b82f6)
                                    : (isDark ? Colors.grey[400] : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // User Info & Logout
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xff3b82f6).withValues(alpha: 0.1),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff3b82f6),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.role.toUpperCase(),
                        style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.grey, size: 18),
                  onPressed: () {
                    authService.logout();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    final List<BottomNavigationBarItem> bottomBarItems = [];
    for (int i = 0; i < 3; i++) {
      bottomBarItems.add(BottomNavigationBarItem(
        icon: Icon(menuItems[i]['icon'] as IconData),
        label: menuItems[i]['name'] as String,
      ));
    }
    bottomBarItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.menu_rounded),
      label: 'More',
    ));

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(child: buildSidebar()),
      bottomNavigationBar: isDesktop 
          ? null 
          : BottomNavigationBar(
              currentIndex: _currentIndex < 3 ? _currentIndex : 3,
              onTap: (index) {
                if (index < 3) {
                  _onMenuItemClick(index);
                } else {
                  // Open mobile drawer for remaining tabs
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xff3b82f6),
              unselectedItemColor: Colors.grey,
              items: bottomBarItems,
            ),
      body: Row(
        children: [
          if (isDesktop) buildSidebar(),
          Expanded(
            child: _getScreen(_currentIndex, user.role),
          ),
        ],
      ),
    );
  }
}
