import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/services.dart';
import '../widgets/auth_components.dart';

class CaregiverRegisterScreen extends StatefulWidget {
  const CaregiverRegisterScreen({super.key});

  @override
  State<CaregiverRegisterScreen> createState() => _CaregiverRegisterScreenState();
}

class _CaregiverRegisterScreenState extends State<CaregiverRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  String _relationship = 'Professional Caregiver / Nurse';

  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final address = _addressController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        address.isEmpty) {
      setState(() {
        _error = 'Please fill out all required fields.';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _error = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final additionalData = {
      'name': name,
      'phone': phone,
      'relationship': _relationship,
      'address': address,
    };

    try {
      await auth.register('caregiver', email, password, additionalData);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

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
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );
    } else {
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

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
                Color(0xfff0f7ff),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrow_left, color: Color(0xff64748b)),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Caregiver Registration',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0f172a),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    HoverCard(
                      borderColor: const Color(0xffcbd5e1).withValues(alpha: 0.4),
                      scaleOnHover: 1.0,
                      borderRadius: 24,
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.circle_alert, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Full Name & Email
                          _buildResponsiveRow(
                            left: StyledTextField(
                              label: 'Full Name',
                              hint: 'Sarah Jenkins',
                              controller: _nameController,
                              prefixIcon: LucideIcons.user,
                            ),
                            right: StyledTextField(
                              label: 'Email',
                              hint: 'sarah@example.com',
                              controller: _emailController,
                              prefixIcon: LucideIcons.mail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 16),

                          // Phone & Relationship
                          _buildResponsiveRow(
                            left: StyledTextField(
                              label: 'Phone Number',
                              hint: '555-0144',
                              controller: _phoneController,
                              prefixIcon: LucideIcons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            right: StyledDropdownField(
                              label: 'Relationship with Patient',
                              value: _relationship,
                              items: const [
                                'Professional Caregiver / Nurse',
                                'Son / Daughter',
                                'Spouse',
                                'Other Relative'
                              ],
                              prefixIcon: LucideIcons.heart_handshake,
                              onChanged: (val) {
                                if (val != null) setState(() => _relationship = val);
                              },
                            ),
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 16),

                          // Password & Confirm Password
                          _buildResponsiveRow(
                            left: StyledTextField(
                              label: 'Password',
                              hint: '••••••••',
                              controller: _passwordController,
                              prefixIcon: LucideIcons.lock,
                              isPassword: true,
                            ),
                            right: StyledTextField(
                              label: 'Confirm Password',
                              hint: '••••••••',
                              controller: _confirmPasswordController,
                              prefixIcon: LucideIcons.lock,
                              isPassword: true,
                            ),
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 16),

                          // Address
                          StyledTextField(
                            label: 'Home Address',
                            hint: '124 Care Street, Boston MA',
                            controller: _addressController,
                            prefixIcon: LucideIcons.map_pin,
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          GradientHoverButton(
                            text: 'Create Caregiver Account',
                            icon: LucideIcons.arrow_right,
                            gradientColors: const [Color(0xff10b981), Color(0xff059669)], // Green-accent gradient
                            loading: _loading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
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
