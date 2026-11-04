import 'dart:convert';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

/// Database Access Object for Hospital Management System core modules.
///
/// Uses direct SQLite operations via Drift to provide persistent storage
/// across desktop sessions without hardcoded mock data.
class HmsDao {
  final AppDatabase db;

  HmsDao(this.db);

  String _esc(String? s) {
    if (s == null) return '';
    return s.replaceAll("'", "''");
  }

  /// Ensure all tables exist in SQLite and populate seed data if tables are empty.
  Future<void> initTablesAndSeed() async {
    // 1. Staff Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        reg_no TEXT,
        department TEXT,
        phone TEXT,
        email TEXT,
        consultation_fee INTEGER DEFAULT 0,
        status TEXT DEFAULT 'Active',
        qualification TEXT,
        created_at TEXT,
        updated_at TEXT
      );
    ''');
    try { await db.customStatement('ALTER TABLE staff ADD COLUMN qualification TEXT;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE staff ADD COLUMN updated_at TEXT;'); } catch (_) {}

    // 2. Beds Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS beds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bed_no TEXT UNIQUE NOT NULL,
        ward TEXT NOT NULL,
        bed_type TEXT NOT NULL,
        tariff_paise INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        patient_name TEXT,
        uhid TEXT,
        created_at TEXT
      );
    ''');

    // 3. Appointments Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token_no TEXT,
        patient_name TEXT NOT NULL,
        uhid TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        department TEXT NOT NULL,
        date TEXT NOT NULL,
        time_slot TEXT NOT NULL,
        status TEXT NOT NULL,
        visit_type TEXT NOT NULL,
        notes TEXT,
        created_at TEXT
      );
    ''');

    // 4. OPD Visits Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS opd_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token_no TEXT,
        patient_name TEXT NOT NULL,
        uhid TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        department TEXT NOT NULL,
        age_gender TEXT,
        status TEXT NOT NULL,
        complaint TEXT,
        history TEXT,
        examination TEXT,
        diagnosis TEXT,
        advice TEXT,
        bp_sys TEXT,
        bp_dia TEXT,
        pulse TEXT,
        temp TEXT,
        spo2 TEXT,
        weight TEXT,
        height TEXT,
        medications_json TEXT,
        created_at TEXT
      );
    ''');

    // 5. IPD Admissions Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS ipd_admissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_name TEXT NOT NULL,
        uhid TEXT NOT NULL,
        ward TEXT NOT NULL,
        bed_no TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        admit_date TEXT NOT NULL,
        days INTEGER DEFAULT 1,
        diagnosis TEXT,
        status TEXT NOT NULL,
        deposit_paise INTEGER DEFAULT 0,
        notes_json TEXT,
        medications_json TEXT,
        created_at TEXT
      );
    ''');

    // 6. Lab Orders Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS lab_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_no TEXT UNIQUE NOT NULL,
        patient_name TEXT NOT NULL,
        uhid TEXT NOT NULL,
        test_name TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        sample_type TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        ordered_at TEXT,
        params_json TEXT,
        created_at TEXT
      );
    ''');

    // 7. Medicines Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        generic_name TEXT,
        category TEXT,
        stock_qty INTEGER DEFAULT 0,
        reorder_level INTEGER DEFAULT 10,
        unit TEXT DEFAULT 'Tablet',
        supplier TEXT,
        uuid TEXT,
        form TEXT,
        strength TEXT,
        manufacturer TEXT,
        tax_rate_pct REAL DEFAULT 0.0,
        hsn_code TEXT,
        rack_location TEXT,
        mrp_paise INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      );
    ''');
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN uuid TEXT;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN form TEXT;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN strength TEXT;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN manufacturer TEXT;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN tax_rate_pct REAL DEFAULT 0.0;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN hsn_code TEXT;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN rack_location TEXT;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN mrp_paise INTEGER DEFAULT 0;'); } catch (_) {}
    try { await db.customStatement('ALTER TABLE medicines ADD COLUMN updated_at TEXT;'); } catch (_) {}

    // 8. Medicine Batches Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS medicine_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER,
        medicine_name TEXT NOT NULL,
        batch_no TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        stock_qty INTEGER DEFAULT 0,
        mrp_paise INTEGER DEFAULT 0,
        cost_paise INTEGER DEFAULT 0,
        created_at TEXT
      );
    ''');

    // 9. Invoices Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT UNIQUE NOT NULL,
        patient_name TEXT NOT NULL,
        uhid TEXT NOT NULL,
        bill_type TEXT NOT NULL,
        subtotal_paise INTEGER DEFAULT 0,
        tax_paise INTEGER DEFAULT 0,
        total_paise INTEGER DEFAULT 0,
        paid_paise INTEGER DEFAULT 0,
        due_paise INTEGER DEFAULT 0,
        payment_mode TEXT DEFAULT 'Cash',
        status TEXT NOT NULL,
        date_time TEXT NOT NULL,
        items_json TEXT,
        created_at TEXT
      );
    ''');

    // 10. Audit Logs Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT NOT NULL,
        action TEXT NOT NULL,
        entity TEXT NOT NULL,
        details TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        created_at TEXT
      );
    ''');

    // 11. Suppliers Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        name TEXT NOT NULL,
        contact_person TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        gst_no TEXT,
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    // 12. Purchases Table (Stock Inward / GRN)
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        invoice_no TEXT NOT NULL,
        supplier_id INTEGER DEFAULT 0,
        supplier_name TEXT NOT NULL,
        invoice_date TEXT NOT NULL,
        total_amount_paise INTEGER DEFAULT 0,
        status TEXT DEFAULT 'received',
        items_json TEXT,
        created_at TEXT
      );
    ''');

    // 13. Stock Adjustments Table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS stock_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER,
        medicine_name TEXT NOT NULL,
        batch_no TEXT NOT NULL,
        adjustment_qty INTEGER NOT NULL,
        reason TEXT NOT NULL,
        adjusted_by TEXT DEFAULT 'Pharmacist',
        adjusted_at TEXT NOT NULL
      );
    ''');

    // 14. Hospitals Table (Multi-Hospital Management for Super Admin)
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS hospitals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        type TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        tax_id TEXT,
        status TEXT DEFAULT 'Active',
        created_at TEXT
      );
    ''');

    // Seed data if empty
    await _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    final now = DateTime.now().toIso8601String();

    // Hospitals Master if empty (Default Super Admin hospital)
    final hospRes = await db.customSelect('SELECT count(*) as count FROM hospitals').getSingle();
    if ((hospRes.data['count'] as int) == 0) {
      await db.customStatement('''
        INSERT INTO hospitals (uuid, name, code, type, address, phone, email, tax_id, status, created_at)
        VALUES ('00000000-0000-0000-0000-000000000001', 'CareSync Central Hospital', 'CS-CENTRAL', 'Multispeciality Hospital', '100 Medical Center Blvd, Health City', '+91 98765 00000', 'central@caresync.health', 'GSTIN27AABCT3518Q1Z5', 'Active', '$now')
      ''');
    }

    // System Audit Log if empty
    final auditRes = await db.customSelect('SELECT count(*) as count FROM audit_logs').getSingle();
    if ((auditRes.data['count'] as int) == 0) {
      await db.customStatement('''
        INSERT INTO audit_logs (user_name, action, entity, details, timestamp, created_at)
        VALUES ('System', 'INITIALIZE', 'Hospital Database', 'Database initialized ready for clinical and administrative operations.', 'Just now', '$now')
      ''');
    }
  }

  // ── Queries & Mutations ───────────────────────────────────────────────────

  // Staff
  Future<List<StaffModel>> getAllStaff() async {
    final rows = await db.customSelect('SELECT * FROM staff ORDER BY id ASC').get();
    return rows.map((r) => StaffModel.fromMap(r.data)).toList();
  }

  Future<void> insertStaff(StaffModel staff) async {
    final now = DateTime.now().toIso8601String();
    await db.customStatement('''
      INSERT INTO staff (uuid, name, role, reg_no, department, phone, email, consultation_fee, status, qualification, created_at, updated_at)
      VALUES ('${_esc(staff.uuid)}', '${_esc(staff.name)}', '${_esc(staff.role)}', '${_esc(staff.regNo)}', '${_esc(staff.department)}', '${_esc(staff.phone)}', '${_esc(staff.email)}', ${staff.feePaise}, '${_esc(staff.status)}', '${_esc(staff.qualification)}', '$now', '$now')
    ''');
    await insertAuditLog('admin', 'CREATE', 'Staff #${staff.name}', 'Added staff member ${staff.name} (${staff.role})');
  }

  Future<void> updateStaff(StaffModel staff) async {
    final now = DateTime.now().toIso8601String();
    await db.customStatement('''
      UPDATE staff SET
        name = '${_esc(staff.name)}',
        role = '${_esc(staff.role)}',
        reg_no = '${_esc(staff.regNo)}',
        department = '${_esc(staff.department)}',
        phone = '${_esc(staff.phone)}',
        email = '${_esc(staff.email)}',
        consultation_fee = ${staff.feePaise},
        status = '${_esc(staff.status)}',
        qualification = '${_esc(staff.qualification)}',
        updated_at = '$now'
      WHERE id = ${staff.id}
    ''');
    await insertAuditLog('admin', 'UPDATE', 'Staff #${staff.name}', 'Updated staff profile for ${staff.name} (${staff.role})');
  }

  Future<void> deleteStaff(int id, String name) async {
    await db.customStatement('DELETE FROM staff WHERE id = $id');
    await insertAuditLog('admin', 'DELETE', 'Staff #$name', 'Removed staff member $name (ID #$id)');
  }

  Future<StaffModel?> getStaffById(int id) async {
    final rows = await db.customSelect('SELECT * FROM staff WHERE id = $id').get();
    if (rows.isEmpty) return null;
    return StaffModel.fromMap(rows.first.data);
  }

  // Beds
  Future<List<BedModel>> getAllBeds() async {
    final rows = await db.customSelect('SELECT * FROM beds ORDER BY id ASC').get();
    return rows.map((r) => BedModel.fromMap(r.data)).toList();
  }

  Future<int> insertBed(BedModel bed) async {
    final now = DateTime.now().toIso8601String();
    final pName = bed.patientName != null ? "'${_esc(bed.patientName!)}'" : 'NULL';
    final pUhid = bed.uhid != null ? "'${_esc(bed.uhid!)}'" : 'NULL';
    final id = await db.customInsert('''
      INSERT INTO beds (bed_no, ward, bed_type, tariff_paise, status, patient_name, uhid, created_at)
      VALUES ('${_esc(bed.bedNo)}', '${_esc(bed.ward)}', '${_esc(bed.type)}', ${bed.tariffPaise}, '${_esc(bed.status)}', $pName, $pUhid, '$now')
    ''');
    await insertAuditLog('admin', 'CREATE', 'Bed #${bed.bedNo}', 'Added bed ${bed.bedNo} (${bed.ward} - ${bed.type})');
    return id;
  }

  Future<void> updateBed(BedModel bed) async {
    await db.customStatement('''
      UPDATE beds SET
        bed_no = '${_esc(bed.bedNo)}',
        ward = '${_esc(bed.ward)}',
        bed_type = '${_esc(bed.type)}',
        tariff_paise = ${bed.tariffPaise},
        status = '${_esc(bed.status)}'
      WHERE id = ${bed.id}
    ''');
    await insertAuditLog('admin', 'UPDATE', 'Bed #${bed.bedNo}', 'Updated bed details for ${bed.bedNo}');
  }

  Future<void> deleteBed(int id, String bedNo) async {
    await db.customStatement('DELETE FROM beds WHERE id = $id');
    await insertAuditLog('admin', 'DELETE', 'Bed #$bedNo', 'Deleted bed $bedNo');
  }

  Future<void> deleteAllBeds() async {
    await db.customStatement('DELETE FROM beds');
    await insertAuditLog('admin', 'DELETE_ALL', 'Beds Master', 'Cleared all bed and ward records');
  }

  // Hospitals (Multi-Hospital Management for Super Admin)
  Future<List<HospitalModel>> getAllHospitals() async {
    final rows = await db.customSelect('SELECT * FROM hospitals ORDER BY id ASC').get();
    return rows.map((r) => HospitalModel.fromMap(r.data)).toList();
  }

  Future<HospitalModel?> getHospitalById(int id) async {
    final rows = await db.customSelect('SELECT * FROM hospitals WHERE id = $id').get();
    if (rows.isEmpty) return null;
    return HospitalModel.fromMap(rows.first.data);
  }

  Future<int> insertHospital(HospitalModel hospital) async {
    final now = DateTime.now().toIso8601String();
    final uuid = hospital.uuid.isNotEmpty ? hospital.uuid : 'hosp-${DateTime.now().millisecondsSinceEpoch}';
    final id = await db.customInsert('''
      INSERT INTO hospitals (uuid, name, code, type, address, phone, email, tax_id, status, created_at)
      VALUES ('${_esc(uuid)}', '${_esc(hospital.name)}', '${_esc(hospital.code)}', '${_esc(hospital.type)}', '${_esc(hospital.address)}', '${_esc(hospital.phone)}', '${_esc(hospital.email)}', '${_esc(hospital.taxId)}', '${_esc(hospital.status)}', '$now')
    ''');
    await insertAuditLog('superadmin', 'CREATE', 'Hospital #${hospital.name}', 'Added hospital entity ${hospital.name} (${hospital.code})');
    return id;
  }

  Future<void> updateHospital(HospitalModel hospital) async {
    await db.customStatement('''
      UPDATE hospitals SET
        name = '${_esc(hospital.name)}',
        code = '${_esc(hospital.code)}',
        type = '${_esc(hospital.type)}',
        address = '${_esc(hospital.address)}',
        phone = '${_esc(hospital.phone)}',
        email = '${_esc(hospital.email)}',
        tax_id = '${_esc(hospital.taxId)}',
        status = '${_esc(hospital.status)}'
      WHERE id = ${hospital.id}
    ''');
    await insertAuditLog('superadmin', 'UPDATE', 'Hospital #${hospital.name}', 'Updated hospital profile for ${hospital.name}');
  }

  Future<void> deleteHospital(int id, String name) async {
    await db.customStatement('DELETE FROM hospitals WHERE id = $id');
    await insertAuditLog('superadmin', 'DELETE', 'Hospital #$name', 'Deleted hospital entity $name');
  }

  Future<void> updateBedStatus(String bedNo, String status, {String? patientName, String? uhid}) async {
    final pName = patientName != null ? "'${_esc(patientName)}'" : 'NULL';
    final pUhid = uhid != null ? "'${_esc(uhid)}'" : 'NULL';
    await db.customStatement('''
      UPDATE beds SET status = '${_esc(status)}', patient_name = $pName, uhid = $pUhid WHERE bed_no = '${_esc(bedNo)}'
    ''');
    await insertAuditLog('admin', 'UPDATE', 'Bed #$bedNo', 'Changed bed status to $status');
  }

  // Appointments
  Future<List<AppointmentModel>> getAllAppointments() async {
    final rows = await db.customSelect('SELECT * FROM appointments ORDER BY id DESC').get();
    return rows.map((r) => AppointmentModel.fromMap(r.data)).toList();
  }

  Future<void> insertAppointment(AppointmentModel appointment) async {
    final now = DateTime.now().toIso8601String();
    await db.customStatement('''
      INSERT INTO appointments (token_no, patient_name, uhid, doctor_name, department, date, time_slot, status, visit_type, notes, created_at)
      VALUES ('${_esc(appointment.tokenNo)}', '${_esc(appointment.patientName)}', '${_esc(appointment.uhid)}', '${_esc(appointment.doctorName)}', '${_esc(appointment.department)}', '${_esc(appointment.date)}', '${_esc(appointment.timeSlot)}', '${_esc(appointment.status)}', '${_esc(appointment.visitType)}', '${_esc(appointment.notes)}', '$now')
    ''');
    await insertAuditLog('reception', 'BOOK', 'Appointment #${appointment.patientName}', 'Booked appointment for ${appointment.patientName} with ${appointment.doctorName}');
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    await db.customStatement('''
      UPDATE appointments SET status = '${_esc(status)}' WHERE id = $id
    ''');
    await insertAuditLog('reception', 'UPDATE', 'Appointment #$id', 'Changed appointment status to $status');
  }

  Future<void> updateAppointment(AppointmentModel appointment) async {
    await db.customStatement('''
      UPDATE appointments SET
        patient_name = '${_esc(appointment.patientName)}',
        uhid = '${_esc(appointment.uhid)}',
        doctor_name = '${_esc(appointment.doctorName)}',
        department = '${_esc(appointment.department)}',
        date = '${_esc(appointment.date)}',
        time_slot = '${_esc(appointment.timeSlot)}',
        status = '${_esc(appointment.status)}',
        visit_type = '${_esc(appointment.visitType)}',
        notes = '${_esc(appointment.notes)}'
      WHERE id = ${appointment.id}
    ''');
    await insertAuditLog('reception', 'UPDATE', 'Appointment #${appointment.patientName}', 'Updated appointment details for ${appointment.patientName}');
  }

  Future<void> deleteAppointment(int id, String patientName) async {
    await db.customStatement('DELETE FROM appointments WHERE id = $id');
    await insertAuditLog('reception', 'CANCEL', 'Appointment #$id', 'Cancelled/Deleted appointment for $patientName');
  }

  // OPD Visits
  Future<List<OpdVisitModel>> getAllOpdVisits() async {
    final rows = await db.customSelect('SELECT * FROM opd_visits ORDER BY id ASC').get();
    return rows.map((r) => OpdVisitModel.fromMap(r.data)).toList();
  }

  Future<OpdVisitModel?> getOpdVisitById(int id) async {
    final rows = await db.customSelect('SELECT * FROM opd_visits WHERE id = $id').get();
    if (rows.isEmpty) return null;
    return OpdVisitModel.fromMap(rows.first.data);
  }

  Future<void> updateOpdVisit(OpdVisitModel visit) async {
    final medsJson = jsonEncode(visit.medications);
    await db.customStatement('''
      UPDATE opd_visits SET 
        status = '${_esc(visit.status)}', 
        complaint = '${_esc(visit.complaint)}', 
        history = '${_esc(visit.history)}', 
        examination = '${_esc(visit.examination)}', 
        diagnosis = '${_esc(visit.diagnosis)}', 
        advice = '${_esc(visit.advice)}', 
        bp_sys = '${_esc(visit.bpSys)}', 
        bp_dia = '${_esc(visit.bpDia)}', 
        pulse = '${_esc(visit.pulse)}', 
        temp = '${_esc(visit.temp)}', 
        spo2 = '${_esc(visit.spo2)}', 
        weight = '${_esc(visit.weight)}', 
        height = '${_esc(visit.height)}', 
        medications_json = '${_esc(medsJson)}' 
      WHERE id = ${visit.id}
    ''');
    await insertAuditLog('doctor', 'UPDATE', 'OPD Visit #${visit.id}', 'Consultation updated for ${visit.patientName}: ${visit.diagnosis}');
  }

  Future<int> insertOpdVisit(OpdVisitModel visit) async {
    final now = DateTime.now().toIso8601String();
    final medsJson = jsonEncode(visit.medications);
    await db.customStatement('''
      INSERT INTO opd_visits (
        token_no, patient_name, uhid, doctor_name, department, age_gender, status,
        complaint, history, examination, diagnosis, advice,
        bp_sys, bp_dia, pulse, temp, spo2, weight, height, medications_json, created_at
      ) VALUES (
        '${_esc(visit.tokenNo)}', '${_esc(visit.patientName)}', '${_esc(visit.uhid)}', '${_esc(visit.doctorName)}', '${_esc(visit.department)}', '${_esc(visit.ageGender)}', '${_esc(visit.status)}',
        '${_esc(visit.complaint)}', '${_esc(visit.history)}', '${_esc(visit.examination)}', '${_esc(visit.diagnosis)}', '${_esc(visit.advice)}',
        '${_esc(visit.bpSys)}', '${_esc(visit.bpDia)}', '${_esc(visit.pulse)}', '${_esc(visit.temp)}', '${_esc(visit.spo2)}', '${_esc(visit.weight)}', '${_esc(visit.height)}', '${_esc(medsJson)}', '$now'
      )
    ''');
    final res = await db.customSelect('SELECT last_insert_rowid() as id').getSingle();
    final id = res.data['id'] as int;
    await insertAuditLog('reception', 'CREATE', 'OPD Visit #$id', 'Registered OPD visit for ${visit.patientName} (${visit.uhid})');
    return id;
  }

  Future<void> deleteOpdVisit(int id, String patientName) async {
    await db.customStatement('DELETE FROM opd_visits WHERE id = $id');
    await insertAuditLog('admin', 'DELETE', 'OPD Visit #$id', 'Deleted OPD visit for $patientName');
  }

  // IPD Admissions
  Future<List<IpdAdmissionModel>> getAllIpdAdmissions() async {
    final rows = await db.customSelect('SELECT * FROM ipd_admissions ORDER BY id DESC').get();
    return rows.map((r) => IpdAdmissionModel.fromMap(r.data)).toList();
  }

  Future<IpdAdmissionModel?> getIpdAdmissionById(int id) async {
    final rows = await db.customSelect('SELECT * FROM ipd_admissions WHERE id = $id').get();
    if (rows.isEmpty) return null;
    return IpdAdmissionModel.fromMap(rows.first.data);
  }

  Future<void> insertIpdAdmission(IpdAdmissionModel admission) async {
    final now = DateTime.now().toIso8601String();
    final notesJson = jsonEncode(admission.notes);
    final medsJson = jsonEncode(admission.medications);
    await db.customStatement('''
      INSERT INTO ipd_admissions (patient_name, uhid, ward, bed_no, doctor_name, admit_date, days, diagnosis, status, deposit_paise, notes_json, medications_json, created_at)
      VALUES ('${_esc(admission.patientName)}', '${_esc(admission.uhid)}', '${_esc(admission.ward)}', '${_esc(admission.bedNo)}', '${_esc(admission.doctorName)}', '${_esc(admission.admitDate)}', ${admission.days}, '${_esc(admission.diagnosis)}', '${_esc(admission.status)}', ${admission.depositPaise}, '${_esc(notesJson)}', '${_esc(medsJson)}', '$now')
    ''');
    // Mark bed occupied
    await updateBedStatus(admission.bedNo, 'Occupied', patientName: admission.patientName, uhid: admission.uhid);
    await insertAuditLog('admin', 'ADMIT', 'Admission #${admission.patientName}', 'Admitted ${admission.patientName} to ${admission.ward} Bed ${admission.bedNo}');
  }

  Future<void> updateIpdMedicationStatus(int admissionId, int medIndex, String status, String givenBy) async {
    final adm = await getIpdAdmissionById(admissionId);
    if (adm == null) return;
    final meds = List<Map<String, dynamic>>.from(adm.medications);
    if (medIndex >= 0 && medIndex < meds.length) {
      meds[medIndex]['status'] = status;
      meds[medIndex]['givenBy'] = givenBy;
      final medsJson = jsonEncode(meds);
      await db.customStatement('''
        UPDATE ipd_admissions SET medications_json = '${_esc(medsJson)}' WHERE id = $admissionId
      ''');
      await insertAuditLog('nurse', 'ADMINISTER', 'Medication #${meds[medIndex]["medicine"]}', 'Administered ${meds[medIndex]["medicine"]} to ${adm.patientName}');
    }
  }

  Future<void> addIpdNursingNote(int admissionId, Map<String, dynamic> note) async {
    final adm = await getIpdAdmissionById(admissionId);
    if (adm == null) return;
    final notes = List<Map<String, dynamic>>.from(adm.notes);
    notes.insert(0, note);
    final notesJson = jsonEncode(notes);
    await db.customStatement('''
      UPDATE ipd_admissions SET notes_json = '${_esc(notesJson)}' WHERE id = $admissionId
    ''');
    await insertAuditLog('nurse', 'NOTE', 'Inpatient Note', 'Added nursing note for ${adm.patientName}');
  }

  // Lab Orders
  Future<List<LabOrderModel>> getAllLabOrders() async {
    final rows = await db.customSelect('SELECT * FROM lab_orders ORDER BY id DESC').get();
    return rows.map((r) => LabOrderModel.fromMap(r.data)).toList();
  }

  Future<LabOrderModel?> getLabOrderById(String orderNo) async {
    final rows = await db.customSelect("SELECT * FROM lab_orders WHERE order_no = '${_esc(orderNo)}'").get();
    if (rows.isEmpty) return null;
    return LabOrderModel.fromMap(rows.first.data);
  }

  Future<void> updateLabOrderResults(String orderNo, List<Map<String, dynamic>> parameters, String status) async {
    final paramsJson = jsonEncode(parameters);
    await db.customStatement('''
      UPDATE lab_orders SET status = '${_esc(status)}', params_json = '${_esc(paramsJson)}' WHERE order_no = '${_esc(orderNo)}'
    ''');
    await insertAuditLog('lab', 'UPDATE', 'Lab Order #$orderNo', 'Results recorded, status set to $status');
  }

  Future<void> insertLabOrder(LabOrderModel order) async {
    final now = DateTime.now().toIso8601String();
    final paramsJson = jsonEncode(order.parameters);
    await db.customStatement('''
      INSERT INTO lab_orders (order_no, patient_name, uhid, test_name, doctor_name, sample_type, priority, status, ordered_at, params_json, created_at)
      VALUES ('${_esc(order.orderNo)}', '${_esc(order.patientName)}', '${_esc(order.uhid)}', '${_esc(order.testName)}', '${_esc(order.doctorName)}', '${_esc(order.sampleType)}', '${_esc(order.priority)}', '${_esc(order.status)}', '${_esc(order.orderedAt)}', '${_esc(paramsJson)}', '$now')
    ''');
    await insertAuditLog('lab', 'CREATE', 'Lab Order #${order.orderNo}', 'Ordered investigation ${order.testName} for ${order.patientName}');
  }

  Future<void> deleteLabOrder(String orderNo, String testName) async {
    await db.customStatement("DELETE FROM lab_orders WHERE order_no = '${_esc(orderNo)}'");
    await insertAuditLog('lab', 'DELETE', 'Lab Order #$orderNo', 'Cancelled/Deleted lab order for $testName');
  }

  // Pharmacy
  Future<List<MedicineModel>> getAllMedicines() async {
    final rows = await db.customSelect('SELECT * FROM medicines ORDER BY name ASC').get();
    return rows.map((r) => MedicineModel.fromMap(r.data)).toList();
  }

  Future<List<MedicineModel>> getLowStockMedicines() async {
    final rows = await db.customSelect('SELECT * FROM medicines WHERE stock_qty <= reorder_level ORDER BY stock_qty ASC').get();
    return rows.map((r) => MedicineModel.fromMap(r.data)).toList();
  }

  Future<List<MedicineBatchModel>> getNearExpiryBatches() async {
    final rows = await db.customSelect('SELECT * FROM medicine_batches ORDER BY id ASC').get();
    return rows.map((r) => MedicineBatchModel.fromMap(r.data)).toList();
  }

  Future<void> dispenseMedicine(int medicineId, int quantity, String patientName) async {
    await db.customStatement('''
      UPDATE medicines SET stock_qty = MAX(0, stock_qty - $quantity) WHERE id = $medicineId
    ''');
    await insertAuditLog('pharmacy', 'DISPENSE', 'Medicine #$medicineId', 'Dispensed $quantity units for patient $patientName');
  }

  Future<void> restockMedicine(int medicineId, int quantity) async {
    await db.customStatement('''
      UPDATE medicines SET stock_qty = stock_qty + $quantity WHERE id = $medicineId
    ''');
    await insertAuditLog('pharmacy', 'RESTOCK', 'Medicine #$medicineId', 'Restocked $quantity units');
  }

  Future<int> insertMedicine(
    MedicineModel medicine, {
    String? batchNo,
    String? expiryDate,
    int? mrpPaise,
    int? costPaise,
  }) async {
    final now = DateTime.now().toIso8601String();
    final uuid = medicine.uuid.isNotEmpty
        ? medicine.uuid
        : 'med-${DateTime.now().millisecondsSinceEpoch}';
    final effectiveMrp = mrpPaise ?? medicine.mrpPaise;

    await db.customStatement('''
      INSERT INTO medicines (
        name, generic_name, category, stock_qty, reorder_level, unit, supplier,
        uuid, form, strength, manufacturer, tax_rate_pct, hsn_code, rack_location,
        mrp_paise, created_at, updated_at
      )
      VALUES (
        '${_esc(medicine.name)}',
        '${_esc(medicine.genericName)}',
        '${_esc(medicine.category)}',
        ${medicine.stockQty},
        ${medicine.reorderLevel},
        '${_esc(medicine.unit)}',
        '${_esc(medicine.supplier)}',
        '${_esc(uuid)}',
        '${_esc(medicine.form)}',
        '${_esc(medicine.strength)}',
        '${_esc(medicine.manufacturer.isNotEmpty ? medicine.manufacturer : medicine.supplier)}',
        ${medicine.taxRatePct},
        '${_esc(medicine.hsnCode)}',
        '${_esc(medicine.rackLocation)}',
        $effectiveMrp,
        '$now',
        '$now'
      )
    ''');

    final res = await db.customSelect('SELECT last_insert_rowid() as id').getSingle();
    final newId = res.data['id'] as int;

    if (batchNo != null && batchNo.trim().isNotEmpty && expiryDate != null && expiryDate.trim().isNotEmpty) {
      final safeCost = costPaise ?? (effectiveMrp * 0.7).round();
      await db.customStatement('''
        INSERT INTO medicine_batches (medicine_id, medicine_name, batch_no, expiry_date, stock_qty, mrp_paise, cost_paise, created_at)
        VALUES ($newId, '${_esc(medicine.name)}', '${_esc(batchNo.trim())}', '${_esc(expiryDate.trim())}', ${medicine.stockQty}, $effectiveMrp, $safeCost, '$now')
      ''');
    }

    await insertAuditLog('pharmacy', 'CREATE', 'Medicine #${medicine.name}', 'Added new medicine ${medicine.name} to pharmacy inventory (${medicine.stockQty} ${medicine.unit}s)');
    return newId;
  }

  Future<void> updateMedicine(MedicineModel medicine) async {
    final now = DateTime.now().toIso8601String();
    await db.customStatement('''
      UPDATE medicines SET
        name = '${_esc(medicine.name)}',
        generic_name = '${_esc(medicine.genericName)}',
        category = '${_esc(medicine.category)}',
        stock_qty = ${medicine.stockQty},
        reorder_level = ${medicine.reorderLevel},
        unit = '${_esc(medicine.unit)}',
        supplier = '${_esc(medicine.supplier)}',
        form = '${_esc(medicine.form)}',
        strength = '${_esc(medicine.strength)}',
        manufacturer = '${_esc(medicine.manufacturer.isNotEmpty ? medicine.manufacturer : medicine.supplier)}',
        rack_location = '${_esc(medicine.rackLocation)}',
        mrp_paise = ${medicine.mrpPaise},
        updated_at = '$now'
      WHERE id = ${medicine.id}
    ''');
    await insertAuditLog('pharmacy', 'UPDATE', 'Medicine #${medicine.name}', 'Updated medicine information for ${medicine.name}');
  }

  Future<void> deleteMedicine(int id, String name) async {
    await db.customStatement('DELETE FROM medicines WHERE id = $id');
    await db.customStatement('DELETE FROM medicine_batches WHERE medicine_id = $id');
    await insertAuditLog('pharmacy', 'DELETE', 'Medicine #$name', 'Removed medicine #$id ($name) from inventory');
  }

  // Pharmacy Batches Management
  Future<List<MedicineBatchModel>> getAllBatches() async {
    final rows = await db.customSelect('SELECT * FROM medicine_batches ORDER BY id DESC').get();
    return rows.map((r) => MedicineBatchModel.fromMap(r.data)).toList();
  }

  Future<void> insertBatch(MedicineBatchModel batch) async {
    final now = DateTime.now().toIso8601String();
    await db.customStatement('''
      INSERT INTO medicine_batches (medicine_id, medicine_name, batch_no, expiry_date, stock_qty, mrp_paise, cost_paise, created_at)
      VALUES (${batch.medicineId}, '${_esc(batch.medicineName)}', '${_esc(batch.batchNo)}', '${_esc(batch.expiryDate)}', ${batch.stockQty}, ${batch.mrpPaise}, ${batch.costPaise}, '$now')
    ''');
    // Increment master stock
    await db.customStatement('''
      UPDATE medicines SET stock_qty = stock_qty + ${batch.stockQty}, updated_at = '$now' WHERE id = ${batch.medicineId}
    ''');
    await insertAuditLog('pharmacy', 'BATCH_ADD', 'Batch #${batch.batchNo}', 'Added new batch ${batch.batchNo} for ${batch.medicineName} (${batch.stockQty} units)');
  }

  Future<void> updateBatch(MedicineBatchModel batch) async {
    await db.customStatement('''
      UPDATE medicine_batches SET
        batch_no = '${_esc(batch.batchNo)}',
        expiry_date = '${_esc(batch.expiryDate)}',
        stock_qty = ${batch.stockQty},
        mrp_paise = ${batch.mrpPaise},
        cost_paise = ${batch.costPaise}
      WHERE id = ${batch.id}
    ''');
    await insertAuditLog('pharmacy', 'BATCH_UPDATE', 'Batch #${batch.batchNo}', 'Updated batch details for ${batch.batchNo}');
  }

  Future<void> deleteBatch(int id, String batchNo, int medicineId) async {
    final rows = await db.customSelect('SELECT stock_qty FROM medicine_batches WHERE id = $id').get();
    int qty = 0;
    if (rows.isNotEmpty) {
      qty = (rows.first.data['stock_qty'] as int?) ?? 0;
    }
    await db.customStatement('DELETE FROM medicine_batches WHERE id = $id');
    if (qty > 0 && medicineId > 0) {
      await db.customStatement('UPDATE medicines SET stock_qty = MAX(0, stock_qty - $qty) WHERE id = $medicineId');
    }
    await insertAuditLog('pharmacy', 'BATCH_DELETE', 'Batch #$batchNo', 'Removed batch $batchNo (deducted $qty units from master stock)');
  }

  // Suppliers & Vendors
  Future<List<SupplierModel>> getAllSuppliers() async {
    final rows = await db.customSelect('SELECT * FROM suppliers ORDER BY id ASC').get();
    return rows.map((r) => SupplierModel.fromMap(r.data)).toList();
  }

  Future<void> insertSupplier(SupplierModel supplier) async {
    final now = DateTime.now().toIso8601String();
    final uuid = supplier.uuid.isNotEmpty ? supplier.uuid : 'sup-${DateTime.now().millisecondsSinceEpoch}';
    await db.customStatement('''
      INSERT INTO suppliers (uuid, name, contact_person, phone, email, address, gst_no, created_at, updated_at)
      VALUES ('${_esc(uuid)}', '${_esc(supplier.name)}', '${_esc(supplier.contactPerson)}', '${_esc(supplier.phone)}', '${_esc(supplier.email)}', '${_esc(supplier.address)}', '${_esc(supplier.gstNo)}', '$now', '$now')
    ''');
    await insertAuditLog('pharmacy', 'SUPPLIER_ADD', 'Supplier #${supplier.name}', 'Added pharmaceutical vendor ${supplier.name}');
  }

  // Purchases / Stock Inward (GRN)
  Future<List<PurchaseOrderModel>> getAllPurchases() async {
    final rows = await db.customSelect('SELECT * FROM purchases ORDER BY id DESC').get();
    return rows.map((r) {
      final data = Map<String, dynamic>.from(r.data);
      if (data['items_json'] != null && data['items_json'] is String) {
        try {
          data['items'] = jsonDecode(data['items_json'] as String);
        } catch (_) {}
      }
      return PurchaseOrderModel.fromMap(data);
    }).toList();
  }

  Future<void> recordStockInward(PurchaseOrderModel po) async {
    final now = DateTime.now().toIso8601String();
    final itemsJson = jsonEncode(po.items.map((i) => i.toMap()).toList());

    await db.customStatement('''
      INSERT INTO purchases (invoice_no, supplier_id, supplier_name, invoice_date, total_amount_paise, status, items_json, created_at)
      VALUES ('${_esc(po.invoiceNo)}', ${po.supplierId}, '${_esc(po.supplierName)}', '${_esc(po.invoiceDate)}', ${po.totalAmountPaise}, '${_esc(po.status)}', '${_esc(itemsJson)}', '$now')
    ''');

    for (final item in po.items) {
      // 1. Update medicine total stock
      await db.customStatement('''
        UPDATE medicines SET stock_qty = stock_qty + ${item.qty}, mrp_paise = ${item.mrpPaise}, updated_at = '$now' WHERE id = ${item.medicineId}
      ''');

      // 2. Insert or update batch
      final batchRes = await db.customSelect("SELECT id, stock_qty FROM medicine_batches WHERE medicine_id = ${item.medicineId} AND batch_no = '${_esc(item.batchNo)}'").get();
      if (batchRes.isNotEmpty) {
        final batchId = batchRes.first.data['id'] as int;
        await db.customStatement('''
          UPDATE medicine_batches SET stock_qty = stock_qty + ${item.qty}, mrp_paise = ${item.mrpPaise}, cost_paise = ${item.unitPricePaise}, expiry_date = '${_esc(item.expiryDate)}' WHERE id = $batchId
        ''');
      } else {
        await db.customStatement('''
          INSERT INTO medicine_batches (medicine_id, medicine_name, batch_no, expiry_date, stock_qty, mrp_paise, cost_paise, created_at)
          VALUES (${item.medicineId}, '${_esc(item.medicineName)}', '${_esc(item.batchNo)}', '${_esc(item.expiryDate)}', ${item.qty}, ${item.mrpPaise}, ${item.unitPricePaise}, '$now')
        ''');
      }
    }

    await insertAuditLog('pharmacy', 'STOCK_INWARD', 'Inward #${po.invoiceNo}', 'Stock inward recorded from ${po.supplierName} (${po.items.length} lines, ${po.totalFormatted})');
  }

  // Stock Adjustments (Wastage / Breakage / Physical Count Audit)
  Future<List<StockAdjustmentModel>> getAllStockAdjustments() async {
    final rows = await db.customSelect('SELECT * FROM stock_adjustments ORDER BY id DESC').get();
    return rows.map((r) => StockAdjustmentModel.fromMap(r.data)).toList();
  }

  Future<void> recordStockAdjustment({
    required int medicineId,
    required String medicineName,
    required String batchNo,
    required int adjustmentQty,
    required String reason,
    String adjustedBy = 'Pharmacist',
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.customStatement('''
      INSERT INTO stock_adjustments (medicine_id, medicine_name, batch_no, adjustment_qty, reason, adjusted_by, adjusted_at)
      VALUES ($medicineId, '${_esc(medicineName)}', '${_esc(batchNo)}', $adjustmentQty, '${_esc(reason)}', '${_esc(adjustedBy)}', '$now')
    ''');

    // Update medicines table
    if (adjustmentQty < 0) {
      await db.customStatement('''
        UPDATE medicines SET stock_qty = MAX(0, stock_qty - ${adjustmentQty.abs()}), updated_at = '$now' WHERE id = $medicineId
      ''');
    } else {
      await db.customStatement('''
        UPDATE medicines SET stock_qty = stock_qty + $adjustmentQty, updated_at = '$now' WHERE id = $medicineId
      ''');
    }

    // Update batch if provided
    if (batchNo.isNotEmpty && batchNo != 'All Batches') {
      if (adjustmentQty < 0) {
        await db.customStatement('''
          UPDATE medicine_batches SET stock_qty = MAX(0, stock_qty - ${adjustmentQty.abs()}) WHERE medicine_id = $medicineId AND batch_no = '${_esc(batchNo)}'
        ''');
      } else {
        await db.customStatement('''
          UPDATE medicine_batches SET stock_qty = stock_qty + $adjustmentQty WHERE medicine_id = $medicineId AND batch_no = '${_esc(batchNo)}'
        ''');
      }
    }

    await insertAuditLog('pharmacy', 'ADJUSTMENT', 'Stock Adjustment #$medicineName', 'Adjusted $adjustmentQty units of $medicineName (Batch: $batchNo). Reason: $reason');
  }

  // Billing
  Future<List<InvoiceModel>> getAllInvoices() async {
    final rows = await db.customSelect('SELECT * FROM invoices ORDER BY id DESC').get();
    return rows.map((r) => InvoiceModel.fromMap(r.data)).toList();
  }

  Future<InvoiceModel?> getInvoiceById(String invoiceNo) async {
    final rows = await db.customSelect("SELECT * FROM invoices WHERE invoice_no = '${_esc(invoiceNo)}' OR id = '${_esc(invoiceNo)}'").get();
    if (rows.isEmpty) return null;
    return InvoiceModel.fromMap(rows.first.data);
  }

  Future<void> quickDischargePatient(int admissionId, String bedNo) async {
    await db.customStatement('''
      UPDATE ipd_admissions SET status = 'Discharged' WHERE id = $admissionId
    ''');
    if (bedNo.isNotEmpty) {
      await updateBedStatus(bedNo, 'Cleaning');
    }
    await insertAuditLog('ipd', 'DISCHARGE', 'Admission #$admissionId', 'Patient discharged from bed $bedNo. Bed marked for cleaning.');
  }

  Future<void> updateIpdAdmission(IpdAdmissionModel admission) async {
    final notesJson = jsonEncode(admission.notes);
    final medsJson = jsonEncode(admission.medications);
    await db.customStatement('''
      UPDATE ipd_admissions SET
        patient_name = '${_esc(admission.patientName)}',
        uhid = '${_esc(admission.uhid)}',
        ward = '${_esc(admission.ward)}',
        bed_no = '${_esc(admission.bedNo)}',
        doctor_name = '${_esc(admission.doctorName)}',
        admit_date = '${_esc(admission.admitDate)}',
        days = ${admission.days},
        diagnosis = '${_esc(admission.diagnosis)}',
        status = '${_esc(admission.status)}',
        deposit_paise = ${admission.depositPaise},
        notes_json = '${_esc(notesJson)}',
        medications_json = '${_esc(medsJson)}'
      WHERE id = ${admission.id}
    ''');
    await insertAuditLog('ipd', 'UPDATE', 'Admission #${admission.patientName}', 'Updated IPD admission record for ${admission.patientName}');
  }

  Future<void> deleteIpdAdmission(int id, String bedNo, String patientName) async {
    await db.customStatement('DELETE FROM ipd_admissions WHERE id = $id');
    if (bedNo.isNotEmpty) {
      await updateBedStatus(bedNo, 'Available');
    }
    await insertAuditLog('ipd', 'DELETE', 'Admission #$id', 'Cancelled/Deleted admission for $patientName; released bed $bedNo');
  }

  Future<void> insertInvoice(InvoiceModel invoice) async {
    final now = DateTime.now().toIso8601String();
    final itemsJson = jsonEncode(invoice.items);
    await db.customStatement('''
      INSERT INTO invoices (invoice_no, patient_name, uhid, bill_type, subtotal_paise, tax_paise, total_paise, paid_paise, due_paise, payment_mode, status, date_time, items_json, created_at)
      VALUES ('${_esc(invoice.invoiceNo)}', '${_esc(invoice.patientName)}', '${_esc(invoice.uhid)}', '${_esc(invoice.billType)}', ${invoice.subtotalPaise}, ${invoice.taxPaise}, ${invoice.totalPaise}, ${invoice.paidPaise}, ${invoice.duePaise}, '${_esc(invoice.paymentMode)}', '${_esc(invoice.status)}', '${_esc(invoice.dateTime)}', '${_esc(itemsJson)}', '$now')
    ''');
    await insertAuditLog('accounts', 'INVOICE', 'Invoice #${invoice.invoiceNo}', 'Generated invoice ${invoice.invoiceNo} for ${invoice.patientName} total ₹${(invoice.totalPaise / 100).toStringAsFixed(2)}');
  }

  Future<void> updateInvoiceStatus(String invoiceNo, String status, int paidPaise) async {
    await db.customStatement('''
      UPDATE invoices SET status = '${_esc(status)}', paid_paise = $paidPaise, due_paise = MAX(0, total_paise - $paidPaise)
      WHERE invoice_no = '${_esc(invoiceNo)}'
    ''');
    await insertAuditLog('accounts', 'UPDATE', 'Invoice #$invoiceNo', 'Updated payment status to $status (Paid ₹${(paidPaise / 100).toStringAsFixed(2)})');
  }

  Future<void> deleteInvoice(int id, String invoiceNo) async {
    await db.customStatement("DELETE FROM invoices WHERE id = $id OR invoice_no = '${_esc(invoiceNo)}'");
    await insertAuditLog('accounts', 'VOID', 'Invoice #$invoiceNo', 'Voided/Deleted invoice $invoiceNo');
  }

  // Audit Logs
  Future<List<AuditLogModel>> getAllAuditLogs() async {
    final rows = await db.customSelect('SELECT * FROM audit_logs ORDER BY id DESC').get();
    return rows.map((r) => AuditLogModel.fromMap(r.data)).toList();
  }

  Future<void> insertAuditLog(String user, String action, String entity, String details) async {
    final now = DateTime.now().toIso8601String();
    final timeStr = 'Today, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    await db.customStatement('''
      INSERT INTO audit_logs (user_name, action, entity, details, timestamp, created_at)
      VALUES ('${_esc(user)}', '${_esc(action)}', '${_esc(entity)}', '${_esc(details)}', '${_esc(timeStr)}', '$now')
    ''');
  }

  // Dashboard Aggregates
  Future<Map<String, dynamic>> getDashboardStats() async {
    final opdVisitsRow = await db.customSelect('SELECT count(*) as count FROM opd_visits').getSingle();
    final appointmentsRow = await db.customSelect('SELECT count(*) as count FROM appointments').getSingle();
    final admissionsRow = await db.customSelect("SELECT count(*) as count FROM ipd_admissions WHERE status = 'Admitted'").getSingle();
    final revenueRow = await db.customSelect("SELECT sum(paid_paise) as sum_paid FROM invoices").getSingle();
    final availableBedsRow = await db.customSelect("SELECT count(*) as count FROM beds WHERE status = 'Available'").getSingle();
    final totalBedsRow = await db.customSelect('SELECT count(*) as count FROM beds').getSingle();
    final pendingLabRow = await db.customSelect("SELECT count(*) as count FROM lab_orders WHERE status != 'Completed'").getSingle();
    final lowStockRow = await db.customSelect('SELECT count(*) as count FROM medicines WHERE stock_qty <= reorder_level').getSingle();

    return {
      'todayOpdVisits': opdVisitsRow.data['count'] as int,
      'todayAppointments': appointmentsRow.data['count'] as int,
      'currentAdmissions': admissionsRow.data['count'] as int,
      'todayRevenuePaise': (revenueRow.data['sum_paid'] as int?) ?? 0,
      'availableBeds': availableBedsRow.data['count'] as int,
      'totalBeds': totalBedsRow.data['count'] as int,
      'pendingLabOrders': pendingLabRow.data['count'] as int,
      'lowStockMedicines': lowStockRow.data['count'] as int,
    };
  }

  // Reports Aggregates
  Future<Map<String, dynamic>> getReportsData() async {
    final revenueRow = await db.customSelect('SELECT sum(total_paise) as total, sum(due_paise) as due FROM invoices').getSingle();
    final opdVisitsRow = await db.customSelect('SELECT count(*) as count FROM opd_visits').getSingle();
    final admissionsRow = await db.customSelect('SELECT count(*) as count FROM ipd_admissions').getSingle();

    final deptRows = await db.customSelect('''
      SELECT bill_type, count(*) as tx_count, sum(total_paise) as dept_total 
      FROM invoices 
      GROUP BY bill_type
    ''').get();

    final deptList = deptRows.map((r) => {
      'name': r.data['bill_type'] as String,
      'count': (r.data['tx_count'] as int).toString(),
      'totalPaise': (r.data['dept_total'] as int?) ?? 0,
    }).toList();

    return {
      'totalRevenuePaise': (revenueRow.data['total'] as int?) ?? 0,
      'totalDuePaise': (revenueRow.data['due'] as int?) ?? 0,
      'totalOpdVisits': opdVisitsRow.data['count'] as int,
      'totalAdmissions': admissionsRow.data['count'] as int,
      'departments': deptList,
    };
  }

  /// Wipes all patient, admission, appointment, visit, invoice, and lab order data from the database.
  Future<void> clearAllData() async {
    await db.customStatement('DELETE FROM opd_visits');
    await db.customStatement('DELETE FROM ipd_admissions');
    await db.customStatement('DELETE FROM appointments');
    await db.customStatement('DELETE FROM lab_orders');
    await db.customStatement('DELETE FROM invoices');
    await db.customStatement('DELETE FROM audit_logs');
    await db.customStatement('DELETE FROM stock_adjustments');
    await db.customStatement('DELETE FROM purchases');
    await db.customStatement('DELETE FROM patients');
    await db.customStatement('DELETE FROM patient_allergies');
    await db.customStatement("UPDATE beds SET status = 'Available', patient_name = '', uhid = ''");
    await insertAuditLog('admin', 'RESET', 'Database', 'All operational and clinical data cleared.');
  }
}
