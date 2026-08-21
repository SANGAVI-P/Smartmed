import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/services.dart';
import '../widgets/auth_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _loading = false;
  String _selectedRole = 'Patient';
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter your email address.';
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _error = 'Please enter your password.';
      });
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.login(email, password, _selectedRole);
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

  Widget _buildDemoButton(String label, String email) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = label;
            _emailController.text = email;
            _passwordController.text = 'password';
          });
          _handleLogin();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xff475569), // Slate 600
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    final roles = ['Patient', 'Caregiver', 'Admin'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRole == role;
          final themeColor = role == 'Patient'
              ? const Color(0xff2563eb)
              : role == 'Caregiver'
                  ? const Color(0xff10b981)
                  : const Color(0xfff59e0b);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRole = role;
                  _error = '';
                  if (role == 'Patient') {
                    _emailController.text = 'patient@smartmed.com';
                  } else if (role == 'Caregiver') {
                    _emailController.text = 'caregiver@smartmed.com';
                  } else if (role == 'Admin') {
                    _emailController.text = 'admin@smartmed.com';
                  }
                  _passwordController.text = 'password';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  role,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? themeColor : const Color(0xff64748b),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xff2563eb),
          secondary: Color(0xff10b981),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Main background layout
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xfff0f7ff), // Subtle blue radial gradient
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // SmartMed Logo: Squircle with heart & SmartMed text
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
                        const SizedBox(height: 24),
                        Text(
                          '$_selectedRole Login',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0f172a),
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sign in to securely manage medicines and monitor patient adherence.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            color: Color(0xff64748b), // Slate 500
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Login form card
                        HoverCard(
                          borderColor: const Color(0xffcbd5e1).withValues(alpha: 0.4),
                          scaleOnHover: 1.01,
                          borderRadius: 24,
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRoleTabs(),
                              const SizedBox(height: 24),
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
                                const SizedBox(height: 16),
                              ],

                              // Email Address
                              StyledTextField(
                                label: 'Email Address',
                                hint: 'name@example.com',
                                controller: _emailController,
                                prefixIcon: LucideIcons.mail,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),

                              // Password
                              StyledTextField(
                                label: 'Password',
                                hint: '••••••••',
                                controller: _passwordController,
                                prefixIcon: LucideIcons.lock,
                                isPassword: true,
                                onForgotPassword: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password reset link has been dispatched to your email.'),
                                      backgroundColor: Color(0xff2563eb),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Remember Me Checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xff2563eb),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: const BorderSide(color: Color(0xffcbd5e1), width: 1.5),
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: const Text(
                                      'Remember Me',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xff475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Sign In Button
                              GradientHoverButton(
                                text: 'Sign In',
                                icon: LucideIcons.arrow_right,
                                gradientColors: const [Color(0xff2563eb), Color(0xff1d4ed8)],
                                loading: _loading,
                                onPressed: _handleLogin,
                              ),

                              const SizedBox(height: 20),
                              const Divider(color: Color(0xfff1f5f9), thickness: 1.5),
                              const SizedBox(height: 16),

                              // DEMO ACCOUNTS BYPASS
                              const Center(
                                child: Text(
                                  'DEMO ACCOUNTS BYPASS',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff94a3b8),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildDemoButton('Patient', 'patient@smartmed.com'),
                                  const SizedBox(width: 12),
                                  _buildDemoButton('Caregiver', 'caregiver@smartmed.com'),
                                  const SizedBox(width: 12),
                                  _buildDemoButton('Admin', 'admin@smartmed.com'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Create Account Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.5,
                                color: Color(0xff64748b),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.5,
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

            // Return Home back button at top-left
            Positioned(
              top: 40,
              left: 20,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(LucideIcons.arrow_left, size: 18, color: Color(0xff64748b)),
                        SizedBox(width: 8),
                        Text(
                          'Return Home',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff64748b),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
