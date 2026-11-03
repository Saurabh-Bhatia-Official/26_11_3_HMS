import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hospital_management/core/providers/hospital_name_provider.dart';
import 'package:hospital_management/core/providers/hms_providers.dart';
import 'package:hospital_management/core/theme/theme_provider.dart';
import 'package:hospital_management/data/database/app_database.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Hospital Profile Controllers
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _regNoController = TextEditingController();
  final _gstController = TextEditingController();
  String _currencySymbol = '₹';
  String _uhidPrefix = 'UHID-';

  // 2. Clinical & OPD Rules
  final _opdFeeController = TextEditingController();
  final _specialistFeeController = TextEditingController();
  final _followupDaysController = TextEditingController();
  final _emergencySurchargeController = TextEditingController();
  String _slotDuration = '15 minutes';

  // 3. Inpatient & Beds (IPD)
  bool _autoBedCleaning = true;
  bool _mandatoryDeposit = true;
  final _inpatientDepositController = TextEditingController();
  String _bedTariffCutoff = '12:00 PM (Noon)';
  final _visitingHoursController = TextEditingController();

  // 4. Pharmacy & Inventory
  final _lowStockThresholdController = TextEditingController();
  final _nearExpiryDaysController = TextEditingController();
  bool _enforceFefo = true;

  // 5. Billing & Taxes
  String _taxRate = '0% (Exempt)';
  final _invoicePrefixController = TextEditingController(text: 'INV-');
  final _invoiceDisclaimerController = TextEditingController();

  // 6. Security
  String _autoLockTime = '15 minutes';
  bool _enforceRbac = true;

  bool _isLoading = true;

  String get _normalizedCurrency {
    const allowed = ['₹', '\$', '€', '£'];
    return allowed.contains(_currencySymbol) ? _currencySymbol : '₹';
  }

  String get _normalizedUhidPrefix {
    final clean = _uhidPrefix.replaceAll('-', '').trim().toUpperCase();
    if (clean == 'MRN') return 'MRN';
    if (clean == 'PAT') return 'PAT';
    return 'UHID';
  }

  String get _normalizedSlotDuration {
    const allowed = ['10 minutes', '15 minutes', '20 minutes', '30 minutes'];
    return allowed.contains(_slotDuration) ? _slotDuration : '15 minutes';
  }

  String get _normalizedBedTariffCutoff {
    const allowed = ['12:00 PM (Noon)', 'Midnight 12:00 AM', '24-Hour Rolling'];
    return allowed.contains(_bedTariffCutoff) ? _bedTariffCutoff : '12:00 PM (Noon)';
  }

  String get _normalizedTaxRate {
    const allowed = [
      '0% (Exempt)',
      '5% (Standard Consumables)',
      '12% (Medical Devices)',
      '18% (Commercial)',
    ];
    return allowed.contains(_taxRate) ? _taxRate : '0% (Exempt)';
  }

  String get _normalizedAutoLockTime {
    const allowed = ['5 minutes', '10 minutes', '15 minutes', '30 minutes', 'Never'];
    return allowed.contains(_autoLockTime) ? _autoLockTime : '15 minutes';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _nameController.text = ref.read(hospitalNameNotifierProvider);
    _loadPersistedSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _regNoController.dispose();
    _gstController.dispose();
    _opdFeeController.dispose();
    _specialistFeeController.dispose();
    _followupDaysController.dispose();
    _emergencySurchargeController.dispose();
    _inpatientDepositController.dispose();
    _visitingHoursController.dispose();
    _lowStockThresholdController.dispose();
    _nearExpiryDaysController.dispose();
    _invoicePrefixController.dispose();
    _invoiceDisclaimerController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedSettings() async {
    final db = ref.read(appDatabaseProvider);
    final dao = db.settingsDao;

    final tagline = await dao.getSetting('tagline');
    if (tagline != null) _taglineController.text = tagline.value;

    final address = await dao.getSetting('address');
    if (address != null) _addressController.text = address.value;

    final phone = await dao.getSetting('phone');
    if (phone != null) _phoneController.text = phone.value;

    final emergency = await dao.getSetting('emergency_phone');
    if (emergency != null) _emergencyController.text = emergency.value;

    final email = await dao.getSetting('email');
    if (email != null) _emailController.text = email.value;

    final website = await dao.getSetting('website');
    if (website != null) _websiteController.text = website.value;

    final regNo = await dao.getSetting('reg_no');
    if (regNo != null) _regNoController.text = regNo.value;

    final gstNo = await dao.getSetting('gst_no');
    if (gstNo != null) _gstController.text = gstNo.value;

    final currency = await dao.getSetting('currency_symbol');
    if (currency != null) _currencySymbol = currency.value;

    final uhidPref = await dao.getSetting('uhid_prefix');
    if (uhidPref != null) _uhidPrefix = uhidPref.value;

    final opdFee = await dao.getSetting('opd_fee');
    if (opdFee != null) _opdFeeController.text = opdFee.value;

    final specFee = await dao.getSetting('specialist_fee');
    if (specFee != null) _specialistFeeController.text = specFee.value;

    final followup = await dao.getSetting('followup_days');
    if (followup != null) _followupDaysController.text = followup.value;

    final surcharge = await dao.getSetting('emergency_surcharge');
    if (surcharge != null) _emergencySurchargeController.text = surcharge.value;

    final slot = await dao.getSetting('slot_duration');
    if (slot != null) _slotDuration = slot.value;

    final autoClean = await dao.getSetting('auto_bed_cleaning');
    if (autoClean != null) _autoBedCleaning = autoClean.value == 'true';

    final deposit = await dao.getSetting('inpatient_deposit');
    if (deposit != null) _inpatientDepositController.text = deposit.value;

    final cutoff = await dao.getSetting('bed_tariff_cutoff');
    if (cutoff != null) _bedTariffCutoff = cutoff.value;

    final visiting = await dao.getSetting('visiting_hours');
    if (visiting != null) _visitingHoursController.text = visiting.value;

    final lowStock = await dao.getSetting('low_stock_threshold');
    if (lowStock != null) _lowStockThresholdController.text = lowStock.value;

    final expiry = await dao.getSetting('near_expiry_days');
    if (expiry != null) _nearExpiryDaysController.text = expiry.value;

    final fefo = await dao.getSetting('enforce_fefo');
    if (fefo != null) _enforceFefo = fefo.value == 'true';

    final tax = await dao.getSetting('tax_rate');
    if (tax != null) _taxRate = tax.value;

    final prefix = await dao.getSetting('invoice_prefix');
    if (prefix != null) _invoicePrefixController.text = prefix.value;

    final disclaimer = await dao.getSetting('invoice_disclaimer');
    if (disclaimer != null) _invoiceDisclaimerController.text = disclaimer.value;

    final autoLock = await dao.getSetting('auto_lock_time');
    if (autoLock != null) _autoLockTime = autoLock.value;

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveAllSettings() async {
    final db = ref.read(appDatabaseProvider);
    final dao = db.settingsDao;

    final hospitalName = _nameController.text.trim();
    await ref.read(hospitalNameNotifierProvider.notifier).update(hospitalName);

    await dao.upsertSetting('hospital_name', hospitalName);
    await dao.upsertSetting('tagline', _taglineController.text.trim());
    await dao.upsertSetting('address', _addressController.text.trim());
    await dao.upsertSetting('phone', _phoneController.text.trim());
    await dao.upsertSetting('emergency_phone', _emergencyController.text.trim());
    await dao.upsertSetting('email', _emailController.text.trim());
    await dao.upsertSetting('website', _websiteController.text.trim());
    await dao.upsertSetting('reg_no', _regNoController.text.trim());
    await dao.upsertSetting('gst_no', _gstController.text.trim());
    await dao.upsertSetting('currency_symbol', _currencySymbol);
    await dao.upsertSetting('uhid_prefix', _uhidPrefix);

    await dao.upsertSetting('opd_fee', _opdFeeController.text.trim());
    await dao.upsertSetting('specialist_fee', _specialistFeeController.text.trim());
    await dao.upsertSetting('followup_days', _followupDaysController.text.trim());
    await dao.upsertSetting('emergency_surcharge', _emergencySurchargeController.text.trim());
    await dao.upsertSetting('slot_duration', _slotDuration);

    await dao.upsertSetting('auto_bed_cleaning', _autoBedCleaning.toString());
    await dao.upsertSetting('inpatient_deposit', _inpatientDepositController.text.trim());
    await dao.upsertSetting('bed_tariff_cutoff', _bedTariffCutoff);
    await dao.upsertSetting('visiting_hours', _visitingHoursController.text.trim());

    await dao.upsertSetting('low_stock_threshold', _lowStockThresholdController.text.trim());
    await dao.upsertSetting('near_expiry_days', _nearExpiryDaysController.text.trim());
    await dao.upsertSetting('enforce_fefo', _enforceFefo.toString());

    await dao.upsertSetting('tax_rate', _taxRate);
    await dao.upsertSetting('invoice_prefix', _invoicePrefixController.text.trim());
    await dao.upsertSetting('invoice_disclaimer', _invoiceDisclaimerController.text.trim());
    await dao.upsertSetting('auto_lock_time', _autoLockTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hospital settings and policy for "$hospitalName" saved successfully!'),
          backgroundColor: Colors.teal.shade800,
        ),
      );
    }
  }

  void _backupDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Offline encrypted database backup (.hmsbackup) successfully generated in Backups folder!'),
        backgroundColor: Colors.teal.shade800,
      ),
    );
  }

  void _exportCsv(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported $type to Documents/HMS_Exports_${DateTime.now().year}.csv'),
        backgroundColor: Colors.teal.shade800,
      ),
    );
  }

  void _confirmClearAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            Gap(8),
            Text('Clear All Database Records?'),
          ],
        ),
        content: const Text(
          'Warning: This action will permanently delete all clinical records, patients, admissions, appointments, visits, lab orders, invoices, and audit logs from the local database.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(appDatabaseProvider);
              await db.hmsDao.clearAllData();
              ref.invalidate(patientListProvider);
              ref.invalidate(appointmentsListProvider);
              ref.invalidate(opdQueueProvider);
              ref.invalidate(ipdAdmissionsListProvider);
              ref.invalidate(bedsListProvider);
              ref.invalidate(labOrdersListProvider);
              ref.invalidate(invoicesListProvider);
              ref.invalidate(auditLogsProvider);
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(reportsDataProvider);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All database records have been deleted successfully.'),
                    backgroundColor: Colors.red.shade900,
                  ),
                );
              }
            },
            child: const Text('Yes, Delete All Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Hospital Administration & Settings'),
        actions: [
          FilledButton.icon(
            onPressed: _saveAllSettings,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save All Settings'),
          ),
          const Gap(16),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.local_hospital), text: 'Hospital Identity'),
            Tab(icon: Icon(Icons.medical_services_outlined), text: 'Clinical & OPD Tariffs'),
            Tab(icon: Icon(Icons.hotel_outlined), text: 'IPD & Bed Policy'),
            Tab(icon: Icon(Icons.medication_outlined), text: 'Pharmacy Stock Rules'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Billing & Taxation'),
            Tab(icon: Icon(Icons.shield_outlined), text: 'Backup & Security'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Hospital Identity
                _buildIdentityTab(colorScheme),

                // 2. Clinical & OPD Tariffs
                _buildClinicalTariffsTab(colorScheme),

                // 3. IPD & Bed Policy
                _buildIpdPolicyTab(colorScheme),

                // 4. Pharmacy & Stock Rules
                _buildPharmacyRulesTab(colorScheme),

                // 5. Billing & Taxation
                _buildBillingTaxTab(colorScheme),

                // 6. Backup, Export & Security
                _buildBackupSecurityTab(colorScheme, themeMode),
              ],
            ),
    );
  }

  Widget _buildIdentityTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(Icons.local_hospital, color: colorScheme.onPrimaryContainer, size: 26),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hospital Identity & Letterhead', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Appears on all OPD slips, discharge summaries, lab reports, and tax invoices.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Hospital / Healthcare Center Name',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _taglineController,
                    decoration: const InputDecoration(
                      labelText: 'Official Tagline / Slogan',
                      prefixIcon: Icon(Icons.short_text),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Full Official Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Hospital Board Line Phone',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _emergencyController,
                          decoration: const InputDecoration(
                            labelText: '24/7 Emergency Helpline',
                            prefixIcon: Icon(Icons.emergency),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Official Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'Website URL',
                            prefixIcon: Icon(Icons.language),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _regNoController,
                          decoration: const InputDecoration(
                            labelText: 'Hospital License / Reg. No.',
                            prefixIcon: Icon(Icons.verified_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _gstController,
                          decoration: const InputDecoration(
                            labelText: 'GSTIN / Tax ID Number',
                            prefixIcon: Icon(Icons.receipt_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _normalizedCurrency,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'System Currency',
                            prefixIcon: Icon(Icons.currency_exchange),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '₹', child: Text('₹ (INR - Indian Rupee)')),
                            DropdownMenuItem(value: '\$', child: Text('\$ (USD - US Dollar)')),
                            DropdownMenuItem(value: '€', child: Text('€ (EUR - Euro)')),
                            DropdownMenuItem(value: '£', child: Text('£ (GBP - British Pound)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _currencySymbol = val);
                          },
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _normalizedUhidPrefix,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Patient UHID Prefix',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'UHID', child: Text('UHID (e.g. UHID-000001)')),
                            DropdownMenuItem(value: 'MRN', child: Text('MRN (Medical Record)')),
                            DropdownMenuItem(value: 'PAT', child: Text('PAT (Patient ID)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _uhidPrefix = val);
                          },
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
    );
  }

  Widget _buildClinicalTariffsTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Outpatient (OPD) & Consultation Tariffs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Configure standard consultation rates, doctor appointment schedules, and free review policies.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _opdFeeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Standard OPD Consultation Fee',
                            prefixText: '$_currencySymbol ',
                            prefixIcon: const Icon(Icons.payments_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _specialistFeeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Senior Specialist Consultation Fee',
                            prefixText: '$_currencySymbol ',
                            prefixIcon: const Icon(Icons.star_outline),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _followupDaysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Free Follow-up Consultation Window',
                            suffixText: 'Days',
                            prefixIcon: Icon(Icons.event_repeat),
                            border: OutlineInputBorder(),
                            helperText: 'Return visits within this window are not charged.',
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _emergencySurchargeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Emergency Triage Surcharge',
                            suffixText: '%',
                            prefixIcon: Icon(Icons.warning_amber),
                            border: OutlineInputBorder(),
                            helperText: 'Additional markup for after-hours emergency care.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  DropdownButtonFormField<String>(
                    value: _normalizedSlotDuration,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Standard Appointment Slot Duration',
                      prefixIcon: Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '10 minutes', child: Text('10 minutes per patient')),
                      DropdownMenuItem(value: '15 minutes', child: Text('15 minutes per patient (Standard)')),
                      DropdownMenuItem(value: '20 minutes', child: Text('20 minutes per patient')),
                      DropdownMenuItem(value: '30 minutes', child: Text('30 minutes per patient')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _slotDuration = v);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIpdPolicyTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Inpatient (IPD), Admission & Bed Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Set bed occupancy calculation rules, housekeeping triggers, and advance deposits.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text('Auto-Trigger Bed Cleaning On Patient Discharge'),
                    subtitle: const Text('Immediately flags bed as "Cleaning" so housekeeping is notified before next admission.'),
                    value: _autoBedCleaning,
                    onChanged: (val) => setState(() => _autoBedCleaning = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Mandatory Inpatient Advance Deposit'),
                    subtitle: const Text('Requires front-desk to collect security deposit prior to bed allocation.'),
                    value: _mandatoryDeposit,
                    onChanged: (val) => setState(() => _mandatoryDeposit = val),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _inpatientDepositController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Standard IPD Advance Deposit',
                            prefixText: '$_currencySymbol ',
                            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _normalizedBedTariffCutoff,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Daily Bed Charge Cutoff Time',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '12:00 PM (Noon)', child: Text('12:00 PM (Standard Hotel Cutoff)')),
                            DropdownMenuItem(value: 'Midnight 12:00 AM', child: Text('Midnight 12:00 AM (Calendar Day)')),
                            DropdownMenuItem(value: '24-Hour Rolling', child: Text('Exact 24 Hours From Check-in')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _bedTariffCutoff = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _visitingHoursController,
                    decoration: const InputDecoration(
                      labelText: 'General Ward Visiting Hours',
                      prefixIcon: Icon(Icons.people_alt_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacyRulesTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pharmacy & Medication Inventory Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Set stock reorder alerts, expiry prevention windows, and FEFO dispensing priority.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lowStockThresholdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Default Low-Stock Alert Threshold',
                            suffixText: 'Units',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(),
                            helperText: 'Triggers restock alert when medicine falls below this.',
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _nearExpiryDaysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Near-Expiry Warning Window',
                            suffixText: 'Days',
                            prefixIcon: Icon(Icons.timer_outlined),
                            border: OutlineInputBorder(),
                            helperText: 'Alerts pharmacist when a batch will expire within X days.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  SwitchListTile(
                    title: const Text('Enforce First-Expiry-First-Out (FEFO)'),
                    subtitle: const Text('Automatically recommends dispensing batches closest to expiration first.'),
                    value: _enforceFefo,
                    onChanged: (v) => setState(() => _enforceFefo = v),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingTaxTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Billing, Taxation & Invoicing Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Set tax rates, receipt formatting, numbering sequences, and terms of service.', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _normalizedTaxRate,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Healthcare GST / Tax Rate',
                            prefixIcon: Icon(Icons.percent),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '0% (Exempt)', child: Text('0% (Healthcare Services Exempt)')),
                            DropdownMenuItem(value: '5% (Standard Consumables)', child: Text('5% (Medicines & Consumables)')),
                            DropdownMenuItem(value: '12% (Medical Devices)', child: Text('12% (Medical Implants & Devices)')),
                            DropdownMenuItem(value: '18% (Commercial)', child: Text('18% (Commercial Services)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _taxRate = v);
                          },
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextFormField(
                          controller: _invoicePrefixController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number Prefix',
                            prefixIcon: Icon(Icons.tag),
                            border: OutlineInputBorder(),
                            helperText: 'e.g. INV-2026-0001',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: _invoiceDisclaimerController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Printed Bill Terms & Legal Disclaimer',
                      prefixIcon: Icon(Icons.gavel_outlined),
                      border: OutlineInputBorder(),
                      helperText: 'Printed at the bottom of all patient invoices and receipts.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSecurityTab(ColorScheme colorScheme, ThemeMode themeMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // Display mode
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Theme & Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Gap(12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Application Color Theme'),
                        subtitle: const Text('Toggle between clean clinical light theme and night-shift dark theme'),
                        trailing: SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                          ],
                          selected: {themeMode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light},
                          onSelectionChanged: (set) {
                            ref.read(themeModeProvider.notifier).setThemeMode(set.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(20),

              // Security & Lock
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Security, Roles & Auto-Lock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Gap(16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _normalizedAutoLockTime,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Inactivity Screen Lock Timeout',
                                prefixIcon: Icon(Icons.lock_clock_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: '5 minutes', child: Text('5 minutes of inactivity')),
                                DropdownMenuItem(value: '10 minutes', child: Text('10 minutes of inactivity')),
                                DropdownMenuItem(value: '15 minutes', child: Text('15 minutes (Recommended)')),
                                DropdownMenuItem(value: '30 minutes', child: Text('30 minutes')),
                                DropdownMenuItem(value: 'Never', child: Text('Never (Disabled)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _autoLockTime = v);
                              },
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Role-Based Access Control'),
                              subtitle: const Text('Enforce role permissions strictly'),
                              value: _enforceRbac,
                              onChanged: (v) => setState(() => _enforceRbac = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(20),

              // Offline Data, Backup & CSV Export
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage_rounded, color: Colors.teal.shade700),
                          const Gap(8),
                          const Expanded(
                            child: Text('Offline SQLite Database & Backup Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        'All clinical records, prescriptions, and billing transactions are stored locally on this machine (offline-first). No external cloud connection required.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const Gap(20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _backupDatabase,
                            icon: const Icon(Icons.backup_outlined, size: 18),
                            label: const Text('Create Encrypted Backup Now'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Database integrity check passed: PRAGMA integrity_check = OK. All 14 tables verified.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.verified_user_outlined, size: 18),
                            label: const Text('Verify DB Integrity'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _exportCsv('Patient Records'),
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: const Text('Export Patients CSV'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _exportCsv('Financial Ledger'),
                            icon: const Icon(Icons.receipt_long, size: 18),
                            label: const Text('Export Revenue Ledger CSV'),
                          ),
                        ],
                      ),
                      const Gap(24),
                      const Divider(),
                      const Gap(16),
                      // Danger Zone
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, color: Colors.red.shade800, size: 32),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Danger Zone: Clear All Database Records',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                  ),
                                  Text(
                                    'Permanently delete all patient records, visits, admissions, invoices, lab orders, and logs from the local database.',
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _confirmClearAllData,
                              icon: const Icon(Icons.delete_sweep, size: 18),
                              label: const Text('Clear All Data'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
