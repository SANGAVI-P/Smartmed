import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';


class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for registration form
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyNumberController = TextEditingController();
  
  String _gender = 'Male';
  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _relationshipController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final emergencyContactString = '${_emergencyNameController.text.trim()} - ${_emergencyNumberController.text.trim()}';
    final patientId = _idController.text.trim();

    final patientData = {
      'uid': patientId,
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'gender': _gender,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'emergencyContact': emergencyContactString,
      'email': _emailController.text.trim(),
      'dateOfBirth': _dobController.text.trim(),
      'relationship': _relationshipController.text.trim(),
    };

    try {
      await db.addPatient(patientData, auth.user?.uid ?? '');
      
      if (mounted) {
        Navigator.pop(context); // Close dialog first
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient Created Successfully'),
            backgroundColor: Color(0xff10b981),
          ),
        );

        // Automatically navigate to that newly created patient's Patient Dashboard!
        Navigator.pushNamed(context, '/patient/$patientId/dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Register New Patient',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DEMOGRAPHICS',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Patient Name',
                              hint: 'e.g. Sangavi',
                              validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _idController,
                              label: 'Patient ID',
                              hint: 'e.g. PAT-8174',
                              validator: (val) => val == null || val.trim().isEmpty ? 'Patient ID is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ageController,
                              label: 'Age',
                              hint: 'e.g. 18',
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Age is required';
                                final age = int.tryParse(val.trim());
                                if (age == null || age <= 0 || age > 130) return 'Invalid age';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Gender',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                DropdownButtonFormField<String>(
                                  initialValue: _gender,
                                  dropdownColor: isDark ? const Color(0xff0f172a) : Colors.white,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: ['Male', 'Female', 'Other', 'Not specified'].map((g) {
                                    return DropdownMenuItem<String>(
                                      value: g,
                                      child: Text(g, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _gender = val;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'e.g. 555-0199',
                              keyboardType: TextInputType.phone,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Phone is required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'e.g. patient@mail.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Email is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dobController,
                              label: 'Date of Birth',
                              hint: 'e.g. YYYY-MM-DD',
                              validator: (val) => val == null || val.trim().isEmpty ? 'DOB is required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _relationshipController,
                              label: 'Relationship',
                              hint: 'e.g. Child / Spouse',
                              validator: (val) => val == null || val.trim().isEmpty ? 'Relationship is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Home Address',
                        hint: 'e.g. 123 Dental Clinic Lane, Vellore',
                        maxLines: 2,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'EMERGENCY CONTACT',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _emergencyNameController,
                              label: 'Contact Name',
                              hint: 'e.g. Deepa (Mother)',
                              validator: (val) => val == null || val.trim().isEmpty ? 'Contact Name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildTextField(
                              controller: _emergencyNumberController,
                              label: 'Contact Phone',
                              hint: 'e.g. 555-0120',
                              keyboardType: TextInputType.phone,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Contact Phone is required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3b82f6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Patient', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
