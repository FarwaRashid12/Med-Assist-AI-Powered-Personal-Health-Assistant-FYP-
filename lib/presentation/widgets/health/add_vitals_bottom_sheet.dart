import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/health_vitals_model.dart';

/// Standardized vital types the user can choose from.
/// Each entry maps to a label, hint, unit, and the Hive field it populates.
class _VitalType {
  final String label;
  final String hint;
  final String unit;
  final IconData icon;
  final bool isDecimal;
  const _VitalType({
    required this.label,
    required this.hint,
    required this.unit,
    required this.icon,
    this.isDecimal = false,
  });
}

const _vitalTypes = [
  _VitalType(label: 'Blood Pressure', hint: '120/80', unit: 'mmHg', icon: Icons.favorite_rounded),
  _VitalType(label: 'Blood Sugar', hint: '100', unit: 'mg/dL', icon: Icons.water_drop_rounded, isDecimal: true),
  _VitalType(label: 'Heart Rate', hint: '75', unit: 'bpm', icon: Icons.monitor_heart_rounded),
  _VitalType(label: 'Other', hint: 'Enter reading', unit: '', icon: Icons.add_circle_outline_rounded),
];

class AddVitalsBottomSheet extends StatefulWidget {
  final String userId;
  const AddVitalsBottomSheet({super.key, required this.userId});

  @override
  State<AddVitalsBottomSheet> createState() => _AddVitalsBottomSheetState();
}

class _AddVitalsBottomSheetState extends State<AddVitalsBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  // Selected vital type index
  int _selectedIndex = 0;

  // Controllers
  final _valueController = TextEditingController();     // primary value (or systolic)
  final _value2Controller = TextEditingController();    // diastolic (BP only)
  final _otherLabelController = TextEditingController();// custom label (Other only)

  @override
  void dispose() {
    _valueController.dispose();
    _value2Controller.dispose();
    _otherLabelController.dispose();
    super.dispose();
  }

  _VitalType get _selected => _vitalTypes[_selectedIndex];
  bool get _isBP => _selected.label == 'Blood Pressure';
  bool get _isOther => _selected.label == 'Other';

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    int systolic = 0, diastolic = 0, heartRate = 0;
    double bloodSugar = 0;

    switch (_selected.label) {
      case 'Blood Pressure':
        // Support "120/80" or just two separate fields
        final parts = _valueController.text.split(RegExp(r'[/\-\s]+'));
        if (parts.length >= 2) {
          systolic = int.tryParse(parts[0].trim()) ?? 0;
          diastolic = int.tryParse(parts[1].trim()) ?? 0;
        } else {
          systolic = int.tryParse(_valueController.text.trim()) ?? 0;
          diastolic = int.tryParse(_value2Controller.text.trim()) ?? 0;
        }
        break;
      case 'Blood Sugar':
        bloodSugar = double.tryParse(_valueController.text.trim()) ?? 0;
        break;
      case 'Heart Rate':
        heartRate = int.tryParse(_valueController.text.trim()) ?? 0;
        break;
      case 'Other':
        // "Other" can't go into the typed model fields — skip for now
        // Future: store in a separate map field
        break;
    }

    final vitals = HealthVitalsModel(
      id: const Uuid().v4(),
      userId: widget.userId,
      systolic: systolic,
      diastolic: diastolic,
      bloodSugar: bloodSugar,
      heartRate: heartRate,
      timestamp: DateTime.now(),
    );
    Navigator.pop(context, vitals);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Log a Vital Reading',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              Text(
                'Select a vital type and enter your reading.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Vital Type Selector — horizontal chips
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _vitalTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final vt = _vitalTypes[i];
                    final isSelected = _selectedIndex == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = i;
                          _valueController.clear();
                          _value2Controller.clear();
                          _otherLabelController.clear();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(vt.icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              vt.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Dynamic input fields
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildInputSection(key: ValueKey(_selectedIndex)),
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Reading',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection({required Key key}) {
    if (_isBP) {
      return Column(
        key: key,
        children: [
          _buildLabel('Blood Pressure', Icons.favorite_rounded, const Color(0xFFE53935)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _valueController,
                  hint: '120',
                  label: 'Systolic',
                  unit: 'mmHg',
                  isDecimal: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('/', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w300, color: AppColors.textHint)),
              ),
              Expanded(
                child: _buildField(
                  controller: _value2Controller,
                  hint: '80',
                  label: 'Diastolic',
                  unit: 'mmHg',
                  isDecimal: false,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (_isOther) {
      return Column(
        key: key,
        children: [
          _buildLabel('Custom Vital', Icons.add_circle_outline_rounded, AppColors.accent),
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherLabelController,
            decoration: InputDecoration(
              labelText: 'Vital Name (e.g. Temperature)',
              labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _valueController,
            hint: 'Enter reading',
            label: 'Reading',
            unit: '',
            isDecimal: true,
          ),
        ],
      );
    }

    // Blood Sugar or Heart Rate
    return Column(
      key: key,
      children: [
        _buildLabel(_selected.label, _selected.icon, AppColors.primary),
        const SizedBox(height: 12),
        _buildField(
          controller: _valueController,
          hint: _selected.hint,
          label: _selected.label,
          unit: _selected.unit,
          isDecimal: _selected.isDecimal,
        ),
      ],
    );
  }

  Widget _buildLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required String unit,
    required bool isDecimal,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: GoogleFonts.outfit(fontSize: 20, color: AppColors.textHint),
        suffixText: unit,
        suffixStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
