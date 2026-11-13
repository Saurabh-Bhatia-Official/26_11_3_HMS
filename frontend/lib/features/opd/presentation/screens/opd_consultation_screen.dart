import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hospital_management/core/router/app_routes.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/data/models/hms_models.dart';

class OpdConsultationScreen extends ConsumerStatefulWidget {
  const OpdConsultationScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<OpdConsultationScreen> createState() =>
      _OpdConsultationScreenState();
}

class _OpdConsultationScreenState extends ConsumerState<OpdConsultationScreen> {
  bool _initialized = false;
  String _patientName = '';
  String _uhid = '';
  String _doctorName = '';
  String _department = '';
  String _ageGender = '';
  String _tokenNo = '';

  final _complaintController = TextEditingController();
  final _historyController = TextEditingController();
  final _examController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _adviceController = TextEditingController();

  // Vitals controllers
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Prescriptions list
  final List<Map<String, String>> _medications = [];

  void _initFromVisit(OpdVisitModel? v) {
    if (v != null) {
      _patientName = v.patientName;
      _uhid = v.uhid;
      _doctorName = v.doctorName;
      _department = v.department;
      _ageGender = v.ageGender;
      _tokenNo = v.tokenNo;

      if (v.complaint.isNotEmpty) _complaintController.text = v.complaint;
      if (v.history.isNotEmpty) _historyController.text = v.history;
      if (v.examination.isNotEmpty) _examController.text = v.examination;
      if (v.diagnosis.isNotEmpty) _diagnosisController.text = v.diagnosis;
      if (v.advice.isNotEmpty) _adviceController.text = v.advice;

      if (v.bpSys.isNotEmpty) _bpSysController.text = v.bpSys;
      if (v.bpDia.isNotEmpty) _bpDiaController.text = v.bpDia;
      if (v.pulse.isNotEmpty) _pulseController.text = v.pulse;
      if (v.temp.isNotEmpty) _tempController.text = v.temp;
      if (v.spo2.isNotEmpty) _spo2Controller.text = v.spo2;
      if (v.weight.isNotEmpty) _weightController.text = v.weight;
      if (v.height.isNotEmpty) _heightController.text = v.height;

      _medications.clear();
      if (v.medications.isNotEmpty) {
        _medications.addAll(v.medications);
      }
    }
    _initialized = true;
  }

  void _autofillNormalVitals() {
    setState(() {
      _bpSysController.text = '120';
      _bpDiaController.text = '80';
      _pulseController.text = '72';
      _tempController.text = '98.6';
      _spo2Controller.text = '99';
      _weightController.text = '70';
      _heightController.text = '170';
    });
  }

  void _applyDiagnosisTemplate(String templateName) {
    setState(() {
      switch (templateName) {
        case 'Viral Fever':
          _complaintController.text = 'Fever with chills and body ache for 2 days.';
          _historyController.text = 'No prior chronic conditions. Non-diabetic.';
          _examController.text = 'Throat congested, chest clear, temperature 100.4°F.';
          _diagnosisController.text = 'B34.9 - Viral infection, unspecified';
          _adviceController.text = 'Adequate oral hydration, rest, light diet. Return if high fever persists > 3 days.';
          _addMedicineIfNotPresent('Tab. Paracetamol 650mg', '1 Tablet', 'Thrice daily (TDS)', '3 days', 'Take after food');
          _addMedicineIfNotPresent('Tab. Pantoprazole 40mg', '1 Tablet', 'Once daily (OD)', '5 days', 'Take before breakfast');
          break;
        case 'Acute URI / Cold':
          _complaintController.text = 'Runny nose, nasal congestion, sneezing, mild sore throat.';
          _historyController.text = 'Seasonal cold episode.';
          _examController.text = 'Mild pharyngeal erythema. Bilateral air entry normal.';
          _diagnosisController.text = 'J06.9 - Acute upper respiratory infection';
          _adviceController.text = 'Steam inhalation, warm saline gargles, avoid cold beverages.';
          _addMedicineIfNotPresent('Tab. Cetirizine 10mg', '1 Tablet', 'Once daily at bedtime', '5 days', 'Take at night');
          _addMedicineIfNotPresent('Tab. Paracetamol 650mg', '1 Tablet', 'SOS (if bodyache/fever)', '3 days', 'Take after food');
          break;
        case 'Hypertension':
          _complaintController.text = 'Routine hypertensive follow-up, mild occipital heaviness.';
          _historyController.text = 'Known hypertensive on medical therapy.';
          _examController.text = 'S1 S2 normal. No pedal edema. Chest clear.';
          _diagnosisController.text = 'I10 - Essential (primary) hypertension';
          _adviceController.text = 'Low salt diet, 30 min daily walking, maintain BP diary.';
          _addMedicineIfNotPresent('Tab. Telmisartan 40mg', '1 Tablet', 'Once daily (OD)', '30 days', 'Take morning after breakfast');
          break;
        case 'Gastroenteritis':
          _complaintController.text = 'Watery stools 4-5 episodes since morning, nausea.';
          _historyController.text = 'History of outside food consumption yesterday.';
          _examController.text = 'Abdomen soft, mild peri-umbilical tenderness, bowel sounds hyperactive.';
          _diagnosisController.text = 'A09 - Infectious gastroenteritis and colitis';
          _adviceController.text = 'ORS frequent sips, curd, boiled potato. Avoid spicy/greasy food.';
          _addMedicineIfNotPresent('ORS Sachet', '1 Sachet in 1L water', 'Frequent sips', '2 days', 'Drink throughout day');
          _addMedicineIfNotPresent('Tab. Pantoprazole 40mg', '1 Tablet', 'Once daily (OD)', '5 days', 'Take before breakfast');
          break;
      }
    });
  }

  void _addMedicineIfNotPresent(String name, String dosage, String frequency, String duration, String instructions) {
    if (!_medications.any((m) => m['name'] == name)) {
      _medications.add({
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'instructions': instructions,
      });
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _historyController.dispose();
    _examController.dispose();
    _diagnosisController.dispose();
    _adviceController.dispose();
    _bpSysController.dispose();
    _bpDiaController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double get _bmi {
    final w = double.tryParse(_weightController.text) ?? 0;
    final h = (double.tryParse(_heightController.text) ?? 0) / 100;
    if (w <= 0 || h <= 0) return 0;
    return w / (h * h);
  }

  Future<void> _finishConsultation() async {
    final db = ref.read(appDatabaseProvider);
    final visitId = int.tryParse(widget.visitId) ?? 1;

    final updated = OpdVisitModel(
      id: visitId,
      tokenNo: _tokenNo,
      patientName: _patientName,
      uhid: _uhid,
      doctorName: _doctorName,
      department: _department,
      ageGender: _ageGender,
      status: 'Completed',
      complaint: _complaintController.text.trim(),
      history: _historyController.text.trim(),
      examination: _examController.text.trim(),
      diagnosis: _diagnosisController.text.trim(),
      advice: _adviceController.text.trim(),
      bpSys: _bpSysController.text.trim(),
      bpDia: _bpDiaController.text.trim(),
      pulse: _pulseController.text.trim(),
      temp: _tempController.text.trim(),
      spo2: _spo2Controller.text.trim(),
      weight: _weightController.text.trim(),
      height: _heightController.text.trim(),
      medications: _medications,
    );

    await db.hmsDao.updateOpdVisit(updated);
    ref.invalidate(opdQueueProvider);
    ref.invalidate(opdVisitDetailProvider(visitId));
    ref.invalidate(dashboardStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation completed for $_patientName (#$_tokenNo)! Saved to database.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      context.go(AppRoutes.opd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visitId = int.tryParse(widget.visitId) ?? 1;
    final visitAsync = ref.watch(opdVisitDetailProvider(visitId));

    return visitAsync.when(
      loading: () => Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(title: const Text('Doctor Consultation')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(title: const Text('Doctor Consultation')),
        body: Center(child: Text('Error loading consultation: $e')),
      ),
      data: (visit) {
        if (!_initialized) {
          _initFromVisit(visit);
        }

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text('OPD Consultation • Token #$_tokenNo'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go(AppRoutes.opd),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Prescription printed for $_patientName.')),
                  );
                },
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print Rx'),
              ),
              const Gap(12),
              FilledButton.icon(
                onPressed: _finishConsultation,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Complete & Save'),
              ),
              const Gap(16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Patient Header Card
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            _patientName.isNotEmpty ? _patientName[0] : 'P',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Gap(16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Gap(8),
                                Chip(
                                  label: Text(_uhid, style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: colorScheme.secondaryContainer,
                                ),
                              ],
                            ),
                            Text('$_ageGender • Doctor: $_doctorName', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red.shade700),
                              const Gap(6),
                              Text(
                                'Alert: Check Drug Allergies before Rx',
                                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),

                // Quick Diagnosis Templates Toolbar
                Card(
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, size: 18, color: Colors.amber),
                        const Gap(8),
                        const Text('Quick Diagnosis Templates: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Gap(8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ActionChip(
                                label: const Text('Viral Fever'),
                                onPressed: () => _applyDiagnosisTemplate('Viral Fever'),
                              ),
                              ActionChip(
                                label: const Text('Acute URI / Cold'),
                                onPressed: () => _applyDiagnosisTemplate('Acute URI / Cold'),
                              ),
                              ActionChip(
                                label: const Text('Hypertension Review'),
                                onPressed: () => _applyDiagnosisTemplate('Hypertension'),
                              ),
                              ActionChip(
                                label: const Text('Gastroenteritis'),
                                onPressed: () => _applyDiagnosisTemplate('Gastroenteritis'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(16),

                // Two-column layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Vitals & Clinical Notes
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Vitals Panel
                          Card(
                            elevation: 0.5,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Patient Vitals', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      TextButton.icon(
                                        onPressed: _autofillNormalVitals,
                                        icon: const Icon(Icons.speed, size: 14),
                                        label: const Text('Autofill Normal Vitals'),
                                      ),
                                    ],
                                  ),
                                  const Gap(8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _vitalsField('BP (Sys)', _bpSysController, 'mmHg'),
                                      _vitalsField('BP (Dia)', _bpDiaController, 'mmHg'),
                                      _vitalsField('Pulse', _pulseController, 'bpm'),
                                      _vitalsField('Temp', _tempController, '°F'),
                                      _vitalsField('SpO2', _spo2Controller, '%'),
                                      _vitalsField('Weight', _weightController, 'kg'),
                                      _vitalsField('Height', _heightController, 'cm'),
                                      Container(
                                        width: 100,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('BMI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            const Gap(2),
                                            Text(_bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(16),

                          // Clinical Documentation
                          Card(
                            elevation: 0.5,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Clinical Documentation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const Gap(16),
                                  TextFormField(
                                    controller: _complaintController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(labelText: 'Chief Complaint'),
                                  ),
                                  const Gap(12),
                                  TextFormField(
                                    controller: _historyController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(labelText: 'Medical & Family History'),
                                  ),
                                  const Gap(12),
                                  TextFormField(
                                    controller: _examController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(labelText: 'Physical Examination Findings'),
                                  ),
                                  const Gap(12),
                                  TextFormField(
                                    controller: _diagnosisController,
                                    decoration: const InputDecoration(
                                      labelText: 'Diagnosis & ICD-10 Code',
                                      prefixIcon: Icon(Icons.search_rounded),
                                    ),
                                  ),
                                  const Gap(12),
                                  TextFormField(
                                    controller: _adviceController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(labelText: 'Doctor Advice & Follow-up Instructions'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // Right Column: Prescriptions
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Card(
                            elevation: 0.5,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Prescription (Rx)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      TextButton.icon(
                                        onPressed: () {
                                          _addMedicineIfNotPresent(
                                            'Tab. Pantoprazole 40mg',
                                            '1 Tablet',
                                            'Once daily (OD)',
                                            '10 days',
                                            'Take before breakfast',
                                          );
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Add Custom'),
                                      ),
                                    ],
                                  ),
                                  const Gap(8),
                                  const Text('Quick Add Standard Medicines:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const Gap(8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      ActionChip(
                                        avatar: const Icon(Icons.add, size: 14),
                                        label: const Text('+ Paracetamol 650mg', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _addMedicineIfNotPresent('Tab. Paracetamol 650mg', '1 Tablet', 'TDS (after food)', '3 days', 'Take after food');
                                          setState(() {});
                                        },
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.add, size: 14),
                                        label: const Text('+ Pantoprazole 40mg', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _addMedicineIfNotPresent('Tab. Pantoprazole 40mg', '1 Tablet', 'OD (empty stomach)', '15 days', 'Take in morning before food');
                                          setState(() {});
                                        },
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.add, size: 14),
                                        label: const Text('+ Amoxicillin 500mg', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _addMedicineIfNotPresent('Cap. Amoxicillin 500mg', '1 Capsule', 'TDS (8 hourly)', '5 days', 'Complete full course');
                                          setState(() {});
                                        },
                                      ),
                                      ActionChip(
                                        avatar: const Icon(Icons.add, size: 14),
                                        label: const Text('+ Cetirizine 10mg', style: TextStyle(fontSize: 11)),
                                        onPressed: () {
                                          _addMedicineIfNotPresent('Tab. Cetirizine 10mg', '1 Tablet', 'OD (at bedtime)', '5 days', 'May cause mild drowsiness');
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                  const Gap(16),
                                  if (_medications.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(child: Text('No medicines added. Tap chips above to prescribe in 1 click.')),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _medications.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, idx) {
                                        final m = _medications[idx];
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('${m["dosage"]} • ${m["frequency"]} • ${m["duration"]}\n${m["instructions"]}'),
                                          isThreeLine: true,
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18),
                                            tooltip: 'Remove',
                                            onPressed: () => setState(() => _medications.removeAt(idx)),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _vitalsField(String label, TextEditingController controller, String unit) {
    return SizedBox(
      width: 100,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
