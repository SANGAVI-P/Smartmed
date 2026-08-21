import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/add_patient_dialog.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _view = 'list'; // 'list' | 'add' | 'edit'
  Patient? _editingPatient;
  String _successMessage = '';
  String _errorMessage = '';

  // Form Key & Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyNumberController = TextEditingController();
  String _gender = 'Male';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _idController.clear();
    _ageController.clear();
    _phoneController.clear();
    _addressController.clear();
    _emergencyNameController.clear();
    _emergencyNumberController.clear();
    _gender = 'Male';
    _errorMessage = '';
    _editingPatient = null;
  }

  void _openAddForm() {
    showDialog(
      context: context,
      builder: (context) => const AddPatientDialog(),
    );
  }

  void _openEditForm(Patient patient) {
    setState(() {
      _clearForm();
      _editingPatient = patient;
      _nameController.text = patient.name;
      _idController.text = patient.uid;
      _ageController.text = patient.age.toString();
      _phoneController.text = patient.phone;
      _addressController.text = patient.address;
      
      // Parse emergency contact (John Doe (Son) - 555-0120)
      if (patient.emergencyContact.contains(' - ')) {
        final parts = patient.emergencyContact.split(' - ');
        _emergencyNameController.text = parts[0];
        if (parts.length > 1) {
          _emergencyNumberController.text = parts[1];
        }
      } else {
        _emergencyNameController.text = patient.emergencyContact;
      }
      
      _gender = ['Male', 'Female', 'Other', 'Not specified'].contains(patient.gender) 
          ? patient.gender 
          : 'Male';
      _view = 'edit';
      _successMessage = '';
    });
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final db = Provider.of<DatabaseService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);

    final emergencyContactString = '${_emergencyNameController.text.trim()} - ${_emergencyNumberController.text.trim()}';
    
    final patientData = {
      'uid': _idController.text.trim(),
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _gender,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'emergencyContact': emergencyContactString,
    };

    try {
      if (_view == 'add') {
        await db.addPatient(patientData, auth.user?.uid ?? '');
        setState(() {
          _successMessage = 'Patient Added Successfully';
          _view = 'list';
        });
      } else {
        await db.updatePatient(_editingPatient!.uid, patientData);
        setState(() {
          _successMessage = 'Patient Updated Successfully';
          _view = 'list';
        });
      }
      _clearForm();
      
      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _handleDelete(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff0f172a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Patient Profile?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          content: const Text(
            'Are you sure you want to delete this patient profile and unbind them? This action cannot be undone.',
            style: TextStyle(color: Colors.grey, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      try {
        await db.deletePatient(uid);
        setState(() {
          _successMessage = 'Patient Deleted Successfully';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = '';
            });
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete patient: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final auth = Provider.of<AuthService>(context);
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    // Filter patients monitored under this caregiver
    final caregiverUid = auth.user?.uid ?? '';
    final caregiver = db.caregivers.firstWhere(
      (c) => c.uid == caregiverUid,
      orElse: () => Caregiver(uid: '', name: '', phone: '', email: '', patientIds: [], relationship: ''),
    );
    final myPatients = db.patients.where((p) => caregiver.patientIds.contains(p.uid)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DashboardHeader(
                  title: _view == 'list' 
                      ? 'Patient Directory' 
                      : (_view == 'add' ? 'Register New Patient' : 'Edit Patient Profile'),
                ),
              ),
              if (_view == 'list')
                ElevatedButton.icon(
                  onPressed: _openAddForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff10b981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_successMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff10b981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xff10b981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xff10b981), size: 20),
                  const SizedBox(width: 12),
                  Text(_successMessage, style: const TextStyle(color: Color(0xff10b981), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_errorMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _view == 'list' 
              ? _buildPatientList(myPatients, isDark)
              : _buildPatientForm(isDark),
        ],
      ),
    );
  }

  Widget _buildPatientList(List<Patient> patients, bool isDark) {
    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.supervised_user_circle_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'No Monitored Patients Registered',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click "Add Patient" above to register a patient in your portal.',
                style: TextStyle(color: Colors.grey, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500,
        mainAxisExtent: 180,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final p = patients[index];
        final isConnected = p.deviceId.isNotEmpty;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xff3b82f6).withValues(alpha: 0.1),
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                      style: const TextStyle(color: Color(0xff3b82f6), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${p.uid}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConnected 
                          ? const Color(0xff10b981).withValues(alpha: 0.08) 
                          : Colors.orangeAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isConnected ? 'Connected' : 'Unlinked',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isConnected ? const Color(0xff10b981) : Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Age: ${p.age} years', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('Phone: ${p.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _openEditForm(p),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xff3b82f6)),
                        tooltip: 'Edit Profile',
                      ),
                      IconButton(
                        onPressed: () => _handleDelete(p.uid),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        tooltip: 'Delete Profile',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientForm(bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PATIENT DETAILS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),

            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Patient Name',
              hint: 'e.g. John Doe',
              validator: (val) => val == null || val.trim().isEmpty ? 'Patient Name is required.' : null,
            ),
            const SizedBox(height: 16),

            // Patient ID Field
            _buildTextField(
              controller: _idController,
              label: 'Patient ID',
              hint: 'e.g. PAT-9080',
              disabled: _view == 'edit', // cannot edit ID once added
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Patient ID is required.';
                }
                if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(val)) {
                  return 'Use only alphanumeric, dashes (-), or underscores (_).';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Age & Gender in a row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    hint: 'e.g. 74',
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Age is required.';
                      }
                      final age = int.tryParse(val);
                      if (age == null || age <= 0 || age > 130) {
                        return 'Enter a valid age.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Gender',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        dropdownColor: isDark ? const Color(0xff0f172a) : Colors.white,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Male', 'Female', 'Other', 'Not specified'].map((g) {
                          return DropdownMenuItem<String>(value: g, child: Text(g, style: const TextStyle(fontSize: 13)));
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
            const SizedBox(height: 16),

            // Phone Field
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'e.g. 555-0199',
              keyboardType: TextInputType.phone,
              validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required.' : null,
            ),
            const SizedBox(height: 16),

            // Address Field
            _buildTextField(
              controller: _addressController,
              label: 'Home Address',
              hint: 'e.g. 123 Care Street, Boston MA',
              maxLines: 2,
              validator: (val) => val == null || val.trim().isEmpty ? 'Address is required.' : null,
            ),
            const SizedBox(height: 24),

            const Text(
              'EMERGENCY CONTACT DETAILS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),

            // Emergency Contact Name
            _buildTextField(
              controller: _emergencyNameController,
              label: 'Emergency Contact Name',
              hint: 'e.g. John Doe (Son)',
              validator: (val) => val == null || val.trim().isEmpty ? 'Contact Name is required.' : null,
            ),
            const SizedBox(height: 16),

            // Emergency Contact Number
            _buildTextField(
              controller: _emergencyNumberController,
              label: 'Emergency Contact Phone',
              hint: 'e.g. 555-0120',
              keyboardType: TextInputType.phone,
              validator: (val) => val == null || val.trim().isEmpty ? 'Contact Phone is required.' : null,
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _view = 'list';
                      _clearForm();
                    });
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3b82f6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save Patient', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool disabled = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !disabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
