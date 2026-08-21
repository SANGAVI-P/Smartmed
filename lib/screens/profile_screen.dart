import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  void _handleUpdate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('HIPAA profile updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);

    
    final user = auth.user;
    final patient = db.patients.firstWhere(
      (p) => p.uid == user?.uid,
      orElse: () => Patient(uid: '', name: '', age: 0, gender: '', phone: '', address: '', emergencyContact: '', caregiverName: '', caregiverPhone: '', medicalConditions: [], allergies: [], deviceId: ''),
    );

    final caregiver = db.caregivers.firstWhere(
      (c) => c.uid == user?.uid,
      orElse: () => Caregiver(uid: '', name: '', phone: '', email: '', patientIds: [], relationship: ''),
    );

    if (!_initialized && user != null) {
      _phoneController.text = user.role == 'patient' ? patient.phone : (user.role == 'caregiver' ? caregiver.phone : '555-0199');
      _addressController.text = patient.address.isNotEmpty ? patient.address : '123 Care Street, Boston MA';
      _emergencyController.text = patient.emergencyContact.isNotEmpty ? patient.emergencyContact : 'John Doe (Son) - 555-0120';
      _initialized = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(title: 'HIPAA User Profile'),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar & Username Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xff3b82f6).withValues(alpha: 0.1),
                          child: Text(
                            user?.name[0].toUpperCase() ?? 'U',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xff3b82f6), fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'SmartMed User', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xff3b82f6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xff3b82f6).withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                '${user?.role.toUpperCase()} ACCOUNT',
                                style: const TextStyle(color: Color(0xff3b82f6), fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),

                    // Inputs form
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('EMAIL ADDRESS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              TextField(
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: user?.email ?? '',
                                  prefixIcon: const Icon(Icons.email_outlined, size: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildFormField('CONTACT PHONE', _phoneController, '555-0199', Icons.phone_android_rounded),
                        ),
                      ],
                    ),

                    if (user?.role == 'patient') ...[
                      const SizedBox(height: 14),
                      _buildFormField('HOME ADDRESS', _addressController, '123 Care Street, Boston MA', Icons.location_on_outlined),
                      const SizedBox(height: 14),
                      _buildFormField('EMERGENCY CONTACTS', _emergencyController, 'John Doe (Son) - 555-0120', Icons.contacts_rounded),
                      
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'IoT Telemetry Node Information:',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xff3b82f6)),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoText('Device Serial ID', patient.deviceId.isNotEmpty ? patient.deviceId : 'BOX-8800'),
                            _buildInfoText('Caregiver Link', '${patient.caregiverName} (${patient.caregiverPhone})'),
                            _buildInfoText('Medical Conditions', patient.medicalConditions.isNotEmpty ? patient.medicalConditions.join(', ') : 'Hypertension, Diabetes'),
                            _buildInfoText('Drug Allergies', patient.allergies.isNotEmpty ? patient.allergies.join(', ') : 'Sulfas'),
                          ],
                        ),
                      ),
                    ],

                    if (user?.role == 'caregiver') ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Caregiver Account Details:',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xff10b981)),
                            ),
                            const SizedBox(height: 10),
                            _buildInfoText('Relationship Status', caregiver.relationship.isNotEmpty ? caregiver.relationship : 'Registered Nurse'),
                            _buildInfoText('Monitored Patients Count', '${caregiver.patientIds.length} patient(s)'),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () => _handleUpdate(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3b82f6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildFormField(String label, TextEditingController controller, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoText(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: val, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
