import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../widgets/auth_components.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Widget _buildResponsiveRow({
    required Widget left,
    required Widget right,
    required bool isDesktop,
  }) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 24),
          Expanded(child: right),
        ],
      );
    } else {
      return Column(
        children: [
          left,
          const SizedBox(height: 24),
          right,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 640;

    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xff2563eb),
          secondary: Color(0xff10b981),
        ),
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xfff0f7ff), // Very subtle blue radial gradient
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Branding Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xff2563eb),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'Smart',
                                style: TextStyle(color: Color(0xff0f172a)),
                              ),
                              TextSpan(
                                text: 'Med',
                                style: TextStyle(color: Color(0xff10b981)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Create Secure Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0f172a),
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Choose your profile role to configure correct medicine alerts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: Color(0xff64748b),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Role selection container (Large white card)
                    HoverCard(
                      borderColor: const Color(0xffcbd5e1).withValues(alpha: 0.4),
                      scaleOnHover: 1.0,
                      borderRadius: 24,
                      padding: const EdgeInsets.all(32.0),
                      child: _buildResponsiveRow(
                        isDesktop: isDesktop,
                        left: HoverCard(
                          borderColor: const Color(0xfff1f5f9),
                          hoverBorderColor: const Color(0xff2563eb), // Blue border on hover
                          borderRadius: 16,
                          scaleOnHover: 1.03, // Slight scale effect
                          padding: const EdgeInsets.all(28.0),
                          onTap: () {
                            Navigator.pushNamed(context, '/register-patient');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xff2563eb).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.heart, // Blue icon
                                  color: Color(0xff2563eb),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Patient Profile',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff0f172a),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'I want to manage my own medicines and verify my adherence schedule.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xff64748b),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        right: HoverCard(
                          borderColor: const Color(0xfff1f5f9),
                          hoverBorderColor: const Color(0xff10b981), // Green border on hover
                          borderRadius: 16,
                          scaleOnHover: 1.03, // Slight scale effect
                          padding: const EdgeInsets.all(28.0),
                          onTap: () {
                            Navigator.pushNamed(context, '/register-caregiver');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xff10b981).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.users, // Green icon
                                  color: Color(0xff10b981),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Caregiver Profile',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff0f172a),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'I want to monitor and assist a patient remotely and receive medicine alerts.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xff64748b),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Log In bottom link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already registered? ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: Color(0xff64748b),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Log In to Portal',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2563eb),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
