import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../widgets/glass_card.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final List<int> _expandedFaqIndices = [];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.sync_rounded,
      'title': 'Automatic Device Sync',
      'desc': 'The smart box logs access automatically, tracking pill counts and device battery levels over secure HIPAA channels whenever a device is opened or closed.',
      'color': Color(0xff3b82f6),
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Intelligent Alerts',
      'desc': 'Automated reminders keep patients on track. Missed doses or low medication stock automatically notify caregivers and patients via SMS/Push alerts.',
      'color': Color(0xff10b981),
    },
    {
      'icon': Icons.emergency_share_rounded,
      'title': 'Emergency SOS Button',
      'desc': 'An immediate physical or digital SOS trigger sends high-risk distress signals to caregivers instantly, routing coordinates, status, and detail logs.',
      'color': Color(0xfff43f5e),
    }
  ];

  final List<Map<String, String>> _steps = [
    {
      'num': '1',
      'title': 'Place Pills in Dispenser',
      'desc': 'Plug in the SmartMed dispenser box. Use patient details to link the active Device ID to your cloud profile.'
    },
    {
      'num': '2',
      'title': 'Set Schedule & Alarms',
      'desc': 'Configure prescription dosage amounts, food sync options (Before/After food), and target AM/PM alarm times in the portal.'
    },
    {
      'num': '3',
      'title': 'Hear Buzzer & Take Dose',
      'desc': 'Dispenser slots flash and beep at the configured time. Pushing to open automatically records adherence in the portal.'
    }
  ];

  final List<Map<String, dynamic>> _benefitsGrid = [
    {
      'icon': Icons.verified_user_rounded,
      'title': '99.4% Adherence',
      'desc': 'Proven average compliance rate among test patients.',
    },
    {
      'icon': Icons.bolt_rounded,
      'title': 'Real-Time Sync',
      'desc': 'Immediate cloud replication of dose logs to caregiver panels.',
    },
    {
      'icon': Icons.loop_rounded,
      'title': 'Refill Trackers',
      'desc': 'Predicts inventory depletion and alerts low stock margins.',
    },
    {
      'icon': Icons.lock_outline_rounded,
      'title': 'Secure Cloud',
      'desc': 'Complies with HIPAA regulations and identity standards.',
    }
  ];

  final List<Map<String, String>> _testimonials = [
    {
      'quote': 'Sarah can finally look after my health from another city. I just open the green slot when the buzzer sounds.',
      'author': 'Albert Jenkins, 72',
      'role': 'Hypertension Patient'
    },
    {
      'quote': "Being able to monitor my father's Metformin intake has given our family absolute peace of mind.",
      'author': 'Sarah Jenkins',
      'role': 'Daughter & Primary Caregiver'
    },
    {
      'quote': 'Medication adherence is the cornerstone of geriatric recovery. SmartMed resolves this problem with smart engineering.',
      'author': 'Dr. Arthur Pendelton',
      'role': 'Geriatric Specialist'
    }
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'HOW DOES THE SMARTMED DISPENSER CONNECT TO THE INTERNET?',
      'a': 'The dispenser box features a built-in 2.4GHz Wi-Fi chip that automatically syncs telemetry, battery logs, and dosage checks to our secure cloud database.'
    },
    {
      'q': 'DO CAREGIVERS NEED THEIR OWN DEDICATED ACCOUNT?',
      'a': 'Yes. Caregivers sign up for a caregiver profile, allowing them to link patient devices, customize alarms, and configure emergency contacts.'
    },
    {
      'q': 'IS PATIENT MEDICAL DATA SECURE?',
      'a': 'Absolutely. SmartMed is built on HIPAA-compliant cloud storage, featuring end-to-end encryption for all personal and medication metadata.'
    },
    {
      'q': 'WHAT HAPPENS IF A PATIENT MISSES A DOSE?',
      'a': 'If the dispenser isn\'t opened within 30 minutes of the scheduled alarm time, the system logs a missed dose, triggers a portal warning, and alerts caregivers.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);
    
    final isDark = themeService.isDarkMode;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    // Use exact Next.js mockup background colors
    final backgroundColor = isDark ? const Color(0xff070a13) : const Color(0xfff8fafc);
    final navColor = isDark ? const Color(0xff070a13).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[650];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 100), // Height for sticky header placeholder

                // 1. HERO SECTION
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? screenWidth * 0.1 : 20.0,
                    vertical: 60.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        // Small pill badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xff3b82f6).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xff3b82f6).withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, color: Color(0xff3b82f6), size: 13),
                              SizedBox(width: 6),
                              Text(
                                'Adherence Management System',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xff3b82f6),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Heading Title
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: textTheme.headlineLarge?.copyWith(
                              fontSize: isDesktop ? 54 : 32,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -1.5,
                              color: textColor,
                            ),
                            children: [
                              const TextSpan(text: 'SmartMed –\n'),
                              TextSpan(
                                text: 'Smart Medicine Management',
                                style: TextStyle(
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [Color(0xff3b82f6), Color(0xff06b6d4)],
                                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Subtitle
                        Text(
                          'Our IoT-connected system helps elderly patients take their medications safely and\non schedule, while allowing caregivers to monitor adherence remotely.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                            height: 1.5,
                            fontSize: isDesktop ? 15.5 : 13.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff3b82f6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                elevation: 0,
                              ),
                              child: const Row(
                                children: [
                                  Text('GET STARTED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                                  SizedBox(width: 6),
                                  Icon(Icons.add, size: 14),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            OutlinedButton(
                              onPressed: () {
                                // Smooth scroll / feedback
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                foregroundColor: textColor,
                              ),
                              child: const Text('LEARN MORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 2. FEATURES GRID SECTION
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? screenWidth * 0.1 : 20.0,
                    vertical: 60.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        Text(
                          'Smarter Healthcare, Remote Peace of Mind',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 26 : 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The SmartMed platform addresses medication non-adherence by providing smart hardware syncing directly\nto our HIPAA-ready cloud portal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subtitleColor, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 40),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 1,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            mainAxisExtent: 220,
                          ),
                          itemCount: _features.length,
                          itemBuilder: (context, idx) {
                            final feat = _features[idx];
                            return GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: (feat['color'] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(feat['icon'] as IconData, color: feat['color'] as Color, size: 20),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    feat['title'] as String,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      feat['desc'] as String,
                                      style: TextStyle(color: subtitleColor, fontSize: 11.5, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 3. THREE STEPS TIMELINE
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? screenWidth * 0.1 : 20.0,
                    vertical: 60.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        Text(
                          'Three Steps to Complete Adherence',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 26 : 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We connect simple, friendly hardware in the patient\'s home with powerful cloud applications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subtitleColor, fontSize: 12.5),
                        ),
                        const SizedBox(height: 44),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 1,
                            crossAxisSpacing: 30,
                            mainAxisSpacing: 30,
                            mainAxisExtent: 200,
                          ),
                          itemCount: _steps.length,
                          itemBuilder: (context, idx) {
                            final step = _steps[idx];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xff3b82f6).withValues(alpha: 0.1),
                                  child: Text(
                                    step['num']!,
                                    style: const TextStyle(
                                      color: Color(0xff3b82f6),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  step['title']!,
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  step['desc']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: subtitleColor, fontSize: 11.5, height: 1.4),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 4. ENGINEERED / SAFETY SECTION
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? screenWidth * 0.1 : 20.0,
                    vertical: 60.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left text & bullets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Engineered for Elderly Safety, Designed\nfor Caregivers',
                                style: TextStyle(
                                  fontSize: isDesktop ? 26 : 20,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Geriatric medical errors cost lives and cause immense caregiver anxiety. SmartMed bridges this distance with real-time hardware logging.',
                                style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 24),
                              _buildBulletPoint(
                                Icons.verified_user_outlined,
                                'For Elderly Patients',
                                'Stay independent at home. Clear buzzer signals, simplified schedules, and easy-to-pull pill boxes prevent double dosing.',
                                const Color(0xff3b82f6),
                                isDark,
                              ),
                              const SizedBox(height: 16),
                              _buildBulletPoint(
                                Icons.people_outline_rounded,
                                'For Caregivers & Families',
                                'Track adherence status from anywhere. Know if medication was taken before food, receive SMS stock alerts, and trigger emergency signals.',
                                const Color(0xff10b981),
                                isDark,
                              ),
                            ],
                          ),
                        ),
                        if (isDesktop) const SizedBox(width: 60),
                        // Right grid
                        if (isDesktop)
                          Expanded(
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 130,
                              ),
                              itemCount: _benefitsGrid.length,
                              itemBuilder: (context, idx) {
                                final benefit = _benefitsGrid[idx];
                                return GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(benefit['icon'] as IconData, color: const Color(0xff3b82f6), size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            benefit['title'] as String,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: Text(
                                          benefit['desc'] as String,
                                          style: TextStyle(color: subtitleColor, fontSize: 10.5, height: 1.3),
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
                // For mobile display the benefits grid below bullet list
                if (!isDesktop) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 110,
                      ),
                      itemCount: _benefitsGrid.length,
                      itemBuilder: (context, idx) {
                        final benefit = _benefitsGrid[idx];
                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(benefit['icon'] as IconData, color: const Color(0xff3b82f6), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    benefit['title'] as String,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  benefit['desc'] as String,
                                  style: TextStyle(color: subtitleColor, fontSize: 10.5, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 60),

                // 5. TESTIMONIALS SECTION
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? screenWidth * 0.1 : 20.0,
                    vertical: 60.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        Text(
                          'Trusted by Care Teams & Seniors',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 26 : 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Read how SmartMed is making a difference in homes and clinics.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subtitleColor, fontSize: 12.5),
                        ),
                        const SizedBox(height: 40),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 1,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            mainAxisExtent: 170,
                          ),
                          itemCount: _testimonials.length,
                          itemBuilder: (context, idx) {
                            final test = _testimonials[idx];
                            return GlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Text(
                                      '"${test['quote']}"',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    test['author']!,
                                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                                  ),
                                  Text(
                                    test['role']!,
                                    style: TextStyle(color: subtitleColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 6. FAQ ACCORDION SECTION
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? screenWidth * 0.1 : 20.0,
                    vertical: 60.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        Text(
                          'Frequently Asked Questions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 26 : 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quick answers to setup, hardware details, and caregiver features.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subtitleColor, fontSize: 12.5),
                        ),
                        const SizedBox(height: 40),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _faqs.length,
                          itemBuilder: (context, idx) {
                            final faq = _faqs[idx];
                            final isExpanded = _expandedFaqIndices.contains(idx);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        faq['q']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isExpanded ? const Color(0xff3b82f6) : textColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      trailing: Icon(
                                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                        color: const Color(0xff3b82f6),
                                        size: 18,
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedFaqIndices.remove(idx);
                                          } else {
                                            _expandedFaqIndices.add(idx);
                                          }
                                        });
                                      },
                                    ),
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            faq['a']!,
                                            style: TextStyle(color: subtitleColor, fontSize: 11.5, height: 1.4),
                                          ),
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
                ),
                const SizedBox(height: 80),

                // 7. FOOTER
                const Divider(color: Colors.white10),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? screenWidth * 0.1 : 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [Color(0xff3b82f6), Color(0xff06b6d4)],
                              ),
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 10),
                          ),
                          const SizedBox(width: 8),
                          const Text('SmartMed Systems', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      const Text(
                        '© 2026 SmartMed. All rights reserved. Designed for Care, Adherence, and Adherent Families.',
                        style: TextStyle(color: Colors.grey, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Sticky Navigation Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? screenWidth * 0.08 : 20.0),
              decoration: BoxDecoration(
                color: navColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xff3b82f6), Color(0xff06b6d4)],
                          ),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SmartMed',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  // Desktop Menu Links
                  if (isDesktop)
                    Row(
                      children: [
                        _buildNavLink('HOME', true),
                        _buildNavLink('FEATURES', false),
                        _buildNavLink('ABOUT', false),
                        _buildNavLink('CONTACT', false),
                      ],
                    ),

                  // Actions
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? Colors.amberAccent : Colors.indigo,
                          size: 20,
                        ),
                        onPressed: themeService.toggleTheme,
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (authService.user != null) {
                            Navigator.pushReplacementNamed(context, '/dashboard');
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff3b82f6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: Text(
                          authService.user != null ? 'Dashboard' : 'Sign In',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: active ? const Color(0xff3b82f6) : Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(IconData icon, String title, String body, Color accentColor, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: accentColor, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[650],
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
