import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/dashboard_header.dart';
import 'prescriptions_screen.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String _patientFilter = 'mock-patient';
  String _stockFilter = 'all'; // 'all' | 'low'
  String _slotFilter = 'all'; // 'all' | 'morning' | 'afternoon' | 'night'

  // Form Controllers
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(text: '1 pill');
  final _qtyController = TextEditingController(text: '30');
  final _pillsPerDoseController = TextEditingController(text: '1');
  
  bool _morning = true;
  bool _afternoon = false;
  bool _night = true;

  final _morningTimeController = TextEditingController(text: '08:00');
  final _afternoonTimeController = TextEditingController(text: '13:00');
  final _nightTimeController = TextEditingController(text: '20:00');

  final _startDateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
  final _endDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0]);
  
  String _timing = 'after_food'; // 'before_food' | 'after_food'
  bool _loading = false;
  Medicine? _editingMed;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _qtyController.dispose();
    _pillsPerDoseController.dispose();
    _morningTimeController.dispose();
    _afternoonTimeController.dispose();
    _nightTimeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _openFormBottomSheet(BuildContext context, {Medicine? med}) {
    if (med != null) {
      _editingMed = med;
      _nameController.text = med.name;
      _dosageController.text = med.dosage;
      _qtyController.text = med.quantity.toString();
      _pillsPerDoseController.text = med.pillsPerDose.toString();
      _morning = med.schedule['morning'] ?? false;
      _afternoon = med.schedule['afternoon'] ?? false;
      _night = med.schedule['night'] ?? false;
      _morningTimeController.text = med.times['morning'] ?? '08:00';
      _afternoonTimeController.text = med.times['afternoon'] ?? '13:00';
      _nightTimeController.text = med.times['night'] ?? '20:00';
      _startDateController.text = med.startDate;
      _endDateController.text = med.endDate;
      _timing = med.timing;
    } else {
      _editingMed = null;
      _nameController.clear();
      _dosageController.text = '1 pill';
      _qtyController.text = '30';
      _pillsPerDoseController.text = '1';
      _morning = true;
      _afternoon = false;
      _night = true;
      _morningTimeController.text = '08:00';
      _afternoonTimeController.text = '13:00';
      _nightTimeController.text = '20:00';
      _startDateController.text = DateTime.now().toIso8601String().split('T')[0];
      _endDateController.text = DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0];
      _timing = 'after_food';
    }

    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff0f172a) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medication_rounded, color: Color(0xff3b82f6), size: 22),
                          const SizedBox(width: 10),
                          Text(
                            _editingMed != null ? 'Edit Medication Schedule' : 'Schedule Medication Routine',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Scrollable form fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFormField('Medication Name', _nameController, 'Lisinopril'),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField('Dosage Size', _dosageController, '10mg (1 Tablet)'),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildFormField('Pills Per Dose', _pillsPerDoseController, '1', isNum: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildFormField('Initial Stock Count', _qtyController, '30', isNum: true),
                          const SizedBox(height: 20),

                          const Text('DOSAGE SLOTS & ALARM TIMERS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                          const SizedBox(height: 10),

                          // Morning Routine
                          _buildTimeSlotSelector(
                            'Morning Routine',
                            _morning,
                            _morningTimeController,
                            (val) => setModalState(() => _morning = val!),
                          ),
                          const SizedBox(height: 10),

                          // Afternoon Routine
                          _buildTimeSlotSelector(
                            'Afternoon Routine',
                            _afternoon,
                            _afternoonTimeController,
                            (val) => setModalState(() => _afternoon = val!),
                          ),
                          const SizedBox(height: 10),

                          // Night Routine
                          _buildTimeSlotSelector(
                            'Night Routine',
                            _night,
                            _nightTimeController,
                            (val) => setModalState(() => _night = val!),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField('Start Date', _startDateController, 'YYYY-MM-DD'),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildFormField('End Date', _endDateController, 'YYYY-MM-DD'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text('FOOD INTAKE SYNCHRONIZATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Before Food'),
                                  selected: _timing == 'before_food',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() => _timing = 'before_food');
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('After Food'),
                                  selected: _timing == 'after_food',
                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() => _timing = 'after_food');
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          ElevatedButton.icon(
                            onPressed: _loading ? null : () => _handleSubmit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff3b82f6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: _loading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save Medication Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
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

  void _handleSubmit(BuildContext context) async {
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final qty = int.tryParse(_qtyController.text) ?? 30;
    final pillsPerDose = int.tryParse(_pillsPerDoseController.text) ?? 1;

    if (name.isEmpty || dosage.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);

    final medData = {
      'patientId': _patientFilter,
      'name': name,
      'dosage': dosage,
      'schedule': {'morning': _morning, 'afternoon': _afternoon, 'night': _night},
      'timing': _timing,
      'startDate': _startDateController.text,
      'endDate': _endDateController.text,
      'quantity': qty,
      'initialQuantity': _editingMed != null ? _editingMed!.initialQuantity : qty,
      'pillsPerDose': pillsPerDose,
      'times': {
        if (_morning) 'morning': _morningTimeController.text,
        if (_afternoon) 'afternoon': _afternoonTimeController.text,
        if (_night) 'night': _nightTimeController.text,
      }
    };

    try {
      if (_editingMed != null) {
        await db.updateMedicine(_editingMed!.id, medData);
      } else {
        await db.addMedicine(medData);
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _handleDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff0f172a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Schedule?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: const Text('Are you sure you want to remove this medication from patient scheduler?', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
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

    if (confirmed == true && context.mounted) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      await db.deleteMedicine(id);
    }
  }

  int _getDailyRate(Medicine med) {
    int rate = 0;
    if (med.schedule['morning'] == true) rate++;
    if (med.schedule['afternoon'] == true) rate++;
    if (med.schedule['night'] == true) rate++;
    return rate > 0 ? rate : 1;
  }

  String _getExhaustionDate(Medicine med) {
    final rate = _getDailyRate(med);
    final remainingDays = med.quantity ~/ rate;
    final date = DateTime.now().add(Duration(days: remainingDays));
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final db = Provider.of<DatabaseService>(context);
    final isDark = Provider.of<ThemeService>(context).isDarkMode;


    final isWritable = auth.user?.role == 'caregiver' || auth.user?.role == 'admin';

    if (auth.user?.role == 'patient' && _patientFilter != auth.user?.uid) {
      _patientFilter = auth.user!.uid;
    } else if (auth.user?.role != 'patient') {
      if (db.patients.isNotEmpty && (_patientFilter == 'mock-patient' || !db.patients.any((p) => p.uid == _patientFilter))) {
        _patientFilter = db.patients.first.uid;
      }
    }

    final filteredMeds = db.medicines.where((med) {
      // 1. Patient check
      if (med.patientId != _patientFilter) return false;

      // 2. Stock check
      if (_stockFilter == 'low' && med.quantity >= 7) return false;

      // 3. Time slot check
      if (_slotFilter != 'all') {
        if (_slotFilter == 'morning' && med.schedule['morning'] != true) return false;
        if (_slotFilter == 'afternoon' && med.schedule['afternoon'] != true) return false;
        if (_slotFilter == 'night' && med.schedule['night'] != true) return false;
      }

      return true;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Custom Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: DashboardHeader(title: 'Medication Scheduler')),
              if (isWritable) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _openFormBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3b82f6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add New Medicine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Dashboard Overview Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isCardWide = constraints.maxWidth > 800;
              final crossAxisCount = isCardWide ? 4 : 2;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 110,
                ),
                children: [
                  _buildDashboardMetricCard(
                    context,
                    title: 'Medicines',
                    value: '${db.medicines.where((med) => med.patientId == _patientFilter).length}',
                    subtitle: 'Active Prescribed',
                    icon: Icons.medication_rounded,
                    color: const Color(0xff3b82f6),
                    isDark: isDark,
                  ),
                  _buildDashboardMetricCard(
                    context,
                    title: 'Medicine Schedule',
                    value: '${db.reminders.where((r) => r.patientId == _patientFilter && r.timestamp == DateTime.now().toIso8601String().split('T')[0]).length}',
                    subtitle: 'Today\'s Routines',
                    icon: Icons.alarm_rounded,
                    color: const Color(0xff10b981),
                    isDark: isDark,
                  ),
                  _buildDashboardMetricCard(
                    context,
                    title: 'Stock',
                    value: '${db.medicines.where((med) => med.patientId == _patientFilter && med.quantity < 7).length}',
                    subtitle: 'Low Stock Alerts',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    isDark: isDark,
                  ),
                  _buildDashboardMetricCard(
                    context,
                    title: 'Prescription',
                    value: 'AI',
                    subtitle: 'OCR Scanner',
                    icon: Icons.document_scanner_rounded,
                    color: Colors.teal,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrescriptionsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Filters Row
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Patient picker for caregivers/admins
                    if (auth.user?.role != 'patient') ...[
                      const Text('PATIENT: ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 6),
                      if (db.patients.isNotEmpty) ...[
                        DropdownButton<String>(
                          value: db.patients.any((p) => p.uid == _patientFilter) ? _patientFilter : db.patients.first.uid,
                          dropdownColor: isDark ? const Color(0xff0f172a) : Colors.white,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                          items: db.patients.map((p) {
                            return DropdownMenuItem<String>(value: p.uid, child: Text(p.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _patientFilter = val;
                              });
                            }
                          },
                        ),
                      ] else ...[
                        const Text('No Patients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                      const SizedBox(width: 16),
                    ],

                    // Time Slot Filter
                    const Text('SLOT: ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: _slotFilter,
                      dropdownColor: isDark ? const Color(0xff0f172a) : Colors.white,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      items: ['all', 'morning', 'afternoon', 'night'].map((val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _slotFilter = val;
                          });
                        }
                      },
                    ),
                  ],
                ),

                // Isolate Low Stock Alerts Toggler
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _stockFilter = _stockFilter == 'all' ? 'low' : 'all';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stockFilter == 'low' ? Colors.orangeAccent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                    foregroundColor: _stockFilter == 'low' ? Colors.orangeAccent : Colors.grey,
                    side: BorderSide(color: _stockFilter == 'low' ? Colors.orangeAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.report_problem_rounded, size: 14),
                  label: const Text('Isolate Low Stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cards list Grid
          filteredMeds.isEmpty
              ? const GlassCard(
                  padding: EdgeInsets.all(40),
                  child: Text('No active medication schedules found matching constraints.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent: 260,
                  ),
                  itemCount: filteredMeds.length,
                  itemBuilder: (context, idx) {
                    final med = filteredMeds[idx];
                    final isLow = med.quantity < 7;

                    final exhaust = _getExhaustionDate(med);

                    return GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title & Edit details options
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isLow ? Colors.orangeAccent.withValues(alpha: 0.1) : const Color(0xff3b82f6).withValues(alpha: 0.1),
                                    child: Icon(Icons.medication_rounded, color: isLow ? Colors.orangeAccent : const Color(0xff3b82f6), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(med.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                      Text('Dosage: ${med.dosage}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                              if (isWritable)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xff3b82f6)),
                                      onPressed: () => _openFormBottomSheet(context, med: med),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                      onPressed: () => _handleDelete(context, med.id),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Schedulers info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 4,
                                children: [
                                  if (med.schedule['morning'] == true) _buildScheduleBadge('Morning (${med.times['morning']})'),
                                  if (med.schedule['afternoon'] == true) _buildScheduleBadge('Afternoon (${med.times['afternoon']})'),
                                  if (med.schedule['night'] == true) _buildScheduleBadge('Night (${med.times['night']})'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Start: ${med.startDate}  •  End: ${med.endDate}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),

                          // Exhaustion forecast and progress bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('EST. EXHAUSTION', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  Text(exhaust, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isLow ? Colors.orangeAccent : Colors.grey[300])),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: min(1.0, med.quantity / med.initialQuantity),
                                        backgroundColor: Colors.white10,
                                        color: isLow ? Colors.orangeAccent : const Color(0xff10b981),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${med.quantity} tabs left', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLow ? Colors.orangeAccent : Colors.grey)),
                                ],
                              ),
                              if (isLow) ...[
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(Icons.report_problem_rounded, color: Colors.orangeAccent, size: 10),
                                    SizedBox(width: 4),
                                    Text('Low stock volume warning active', style: TextStyle(color: Colors.orangeAccent, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildScheduleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xff3b82f6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 8.5, color: Color(0xff3b82f6), fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, String hint, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelector(String label, bool isSelected, TextEditingController controller, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: isSelected,
          onChanged: onChanged,
          activeColor: const Color(0xff3b82f6),
        ),
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (isSelected)
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 12, fontFamily: 'Courier', fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final cardContent = Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: cardContent,
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}
