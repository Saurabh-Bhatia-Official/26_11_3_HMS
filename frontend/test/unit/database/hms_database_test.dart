import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.open();
  });

  tearDown(() async {
    await db.close();
  });

  group('HMS SQLite Database & Persistence Tests', () {
    test('1. Database seeds tables on startup without hardcoded UI fallback',
        () async {
      final staff = await db.hmsDao.getAllStaff();
      expect(staff, isEmpty);

      final beds = await db.hmsDao.getAllBeds();
      expect(beds,
          isEmpty); // Beds table starts completely clean without hardcoded dummy entries

      final appointments = await db.hmsDao.getAllAppointments();
      expect(appointments, isEmpty);

      final opdVisits = await db.hmsDao.getAllOpdVisits();
      expect(opdVisits, isEmpty);

      final ipd = await db.hmsDao.getAllIpdAdmissions();
      expect(ipd, isEmpty);

      final lab = await db.hmsDao.getAllLabOrders();
      expect(lab, isEmpty);

      final meds = await db.hmsDao.getAllMedicines();
      expect(meds, isEmpty);

      final invoices = await db.hmsDao.getAllInvoices();
      expect(invoices, isEmpty);

      final suppliers = await db.hmsDao.getAllSuppliers();
      expect(suppliers, isEmpty);

      final logs = await db.hmsDao.getAllAuditLogs();
      expect(logs, isNotEmpty);
    });

    test('2. Staff insertion and retrieval works through database', () async {
      const newStaff = StaffModel(
        id: 0,
        uuid: 'staff-uuid-001',
        name: 'Dr. Test Cardiologist',
        role: 'Doctor',
        regNo: 'MCI-99999',
        department: 'Cardiology',
        phone: '+91 99999 88888',
        email: 'test.cardio@hospital.local',
        feePaise: 75000,
        status: 'Active',
        qualification: 'MBBS, MD',
      );

      await db.hmsDao.insertStaff(newStaff);
      final list = await db.hmsDao.getAllStaff();
      final savedDoctor = list.singleWhere(
        (staff) => staff.name == 'Dr. Test Cardiologist',
      );
      expect(savedDoctor.role, contains('Doctor'));
      expect(savedDoctor.department, equals('Cardiology'));
      expect(savedDoctor.regNo, equals('MCI-99999'));
      expect(savedDoctor.email, equals('test.cardio@hospital.local'));
      expect(savedDoctor.qualification, equals('MBBS, MD'));
      expect(savedDoctor.isActive, isTrue);
    });

    test('Receptionist staff records can be saved without a license number',
        () async {
      await db.hmsDao.insertStaff(const StaffModel(
        id: 0,
        uuid: 'staff-receptionist-001',
        name: 'Test Receptionist',
        role: 'Receptionist',
        regNo: '',
        department: 'Reception',
        phone: '+91 98888 77777',
        email: 'reception.test@hospital.local',
        feePaise: 0,
        status: 'Active',
      ));

      final staff = await db.hmsDao.getAllStaff();
      final receptionist =
          staff.singleWhere((member) => member.name == 'Test Receptionist');
      expect(receptionist.role, equals('Receptionist'));
      expect(receptionist.department, equals('Reception'));
      expect(receptionist.regNo, isEmpty);
      expect(receptionist.isActive, isTrue);
    });

    test('3. Bed creation, update, and status updates dynamically in SQLite',
        () async {
      await db.hmsDao.insertBed(const BedModel(
        id: 0,
        bedNo: 'ICU-01',
        ward: 'ICU',
        type: 'ICU',
        tariffPaise: 350000,
        status: 'Available',
      ));
      await db.hmsDao.updateBedStatus('ICU-01', 'Occupied',
          patientName: 'John Doe', uhid: 'UHID-999');
      final beds = await db.hmsDao.getAllBeds();
      final updated = beds.firstWhere((b) => b.bedNo == 'ICU-01');
      expect(updated.status, equals('Occupied'));
      expect(updated.patientName, equals('John Doe'));
    });

    test('4. Appointment booking and status updates in SQLite', () async {
      const newApt = AppointmentModel(
        id: 0,
        tokenNo: '10',
        patientName: 'Jane Smith',
        uhid: 'UHID-000010',
        doctorName: 'Dr. Sharma',
        department: 'Cardiology',
        date: 'Today',
        timeSlot: '11:00 AM',
        status: 'Scheduled',
        visitType: 'Scheduled',
        notes: 'Followup visit',
      );

      await db.hmsDao.insertAppointment(newApt);
      final list = await db.hmsDao.getAllAppointments();
      expect(list.any((a) => a.patientName == 'Jane Smith'), isTrue);
    });

    test('5. OPD visit diagnosis & vitals persist to database', () async {
      await db.hmsDao.insertOpdVisit(const OpdVisitModel(
        id: 0,
        tokenNo: '1',
        patientName: 'Test Patient',
        uhid: 'UHID-001',
        doctorName: 'Dr. Ramesh Sharma',
        department: 'Cardiology',
        ageGender: '45/M',
        status: 'Waiting',
        complaint: 'Headache',
        history: 'None',
        examination: 'Normal',
        diagnosis: '',
        advice: '',
        bpSys: '120',
        bpDia: '80',
        pulse: '72',
        temp: '98.6',
        spo2: '99',
        weight: '70',
        height: '170',
        medications: [],
      ));
      final visits = await db.hmsDao.getAllOpdVisits();
      final first = visits.first;

      final updated = OpdVisitModel(
        id: first.id,
        tokenNo: first.tokenNo,
        patientName: first.patientName,
        uhid: first.uhid,
        doctorName: first.doctorName,
        department: first.department,
        ageGender: first.ageGender,
        status: 'Completed',
        complaint: 'Severe headache',
        history: 'Migraine',
        examination: 'BP normal',
        diagnosis: 'G43.9 - Migraine',
        advice: 'Rest and hydration',
        bpSys: '125',
        bpDia: '82',
        pulse: '74',
        temp: '98.6',
        spo2: '99',
        weight: '68',
        height: '168',
        medications: const [
          {
            'name': 'Tab. Paracetamol 650mg',
            'dosage': '1 Tab',
            'frequency': 'SOS',
            'duration': '3 days',
            'instructions': 'Take after food'
          }
        ],
      );

      await db.hmsDao.updateOpdVisit(updated);
      final retrieved = await db.hmsDao.getOpdVisitById(first.id);
      expect(retrieved?.status, equals('Completed'));
      expect(retrieved?.diagnosis, contains('Migraine'));
      expect(retrieved?.medications.length, equals(1));
    });

    test('6. Pharmacy medicine dispensing deducts stock in SQLite', () async {
      final medId = await db.hmsDao.insertMedicine(const MedicineModel(
        id: 0,
        name: 'Tab. Aspirin 75mg',
        genericName: 'Aspirin',
        category: 'Cardiology',
        form: 'Tablet',
        strength: '75mg',
        unit: 'Strip',
        supplier: 'Test Supplier',
        manufacturer: 'Bayer India',
        stockQty: 100,
        reorderLevel: 20,
        mrpPaise: 2500,
      ));
      final medsBefore = await db.hmsDao.getAllMedicines();
      final aspirin = medsBefore.firstWhere((m) => m.id == medId);
      final initialStock = aspirin.stockQty;

      await db.hmsDao.dispenseMedicine(aspirin.id, 20, 'Ramesh Kumar');

      final medsAfter = await db.hmsDao.getAllMedicines();
      final updatedAspirin = medsAfter.firstWhere((m) => m.id == aspirin.id);
      expect(updatedAspirin.stockQty, equals(initialStock - 20));
    });

    test('7. Dashboard & Reports aggregates reflect database data dynamically',
        () async {
      await db.hmsDao.insertBed(const BedModel(
        id: 0,
        bedNo: 'B-101',
        ward: 'General',
        type: 'General',
        tariffPaise: 100000,
        status: 'Available',
      ));
      final statsEmpty = await db.hmsDao.getDashboardStats();
      expect(statsEmpty['totalBeds'], greaterThan(0));

      // Add dynamic test records to verify aggregation
      await db.hmsDao.insertOpdVisit(const OpdVisitModel(
        id: 0,
        tokenNo: '1',
        patientName: 'Test Patient',
        uhid: 'UHID-001',
        doctorName: 'Dr. Ramesh Sharma',
        department: 'Cardiology',
        ageGender: '45/M',
        status: 'Waiting',
        complaint: 'Routine Checkup',
        history: 'None',
        examination: 'Normal',
        diagnosis: 'Healthy',
        advice: 'Annual followup',
        bpSys: '120',
        bpDia: '80',
        pulse: '72',
        temp: '98.6',
        spo2: '99',
        weight: '70',
        height: '170',
        medications: [],
      ));
      await db.hmsDao.insertInvoice(const InvoiceModel(
        id: 0,
        invoiceNo: 'INV-TEST-001',
        patientName: 'Test Patient',
        uhid: 'UHID-001',
        billType: 'OPD Consultation',
        subtotalPaise: 50000,
        taxPaise: 0,
        totalPaise: 50000,
        paidPaise: 50000,
        duePaise: 0,
        paymentMode: 'Cash',
        status: 'Paid',
        dateTime: 'Today, 10:00 AM',
        items: [],
      ));

      final stats = await db.hmsDao.getDashboardStats();
      expect(stats['todayOpdVisits'], greaterThan(0));
      expect(stats['totalBeds'], greaterThan(0));
      expect(stats['todayRevenuePaise'], greaterThan(0));

      final reports = await db.hmsDao.getReportsData();
      expect(reports['totalRevenuePaise'], greaterThan(0));
      expect((reports['departments'] as List).isNotEmpty, isTrue);
    });

    test('8. Pharmacy 1-click restock increases stock quantity in SQLite',
        () async {
      final medId = await db.hmsDao.insertMedicine(const MedicineModel(
        id: 0,
        name: 'Tab. Restock Test',
        genericName: 'Paracetamol',
        category: 'Analgesic',
        form: 'Tablet',
        strength: '650mg',
        unit: 'Strip',
        supplier: 'Test Supplier',
        manufacturer: 'Test Lab',
        stockQty: 20,
        reorderLevel: 50,
        mrpPaise: 3200,
      ));
      final meds = await db.hmsDao.getAllMedicines();
      final firstMed = meds.firstWhere((m) => m.id == medId);
      final stockBefore = firstMed.stockQty;

      await db.hmsDao.restockMedicine(firstMed.id, 50);

      final medsAfter = await db.hmsDao.getAllMedicines();
      final updated = medsAfter.firstWhere((m) => m.id == firstMed.id);
      expect(updated.stockQty, equals(stockBefore + 50));
    });

    test(
        '9. IPD nursing notes and quick discharge updates bed status to Cleaning',
        () async {
      await db.hmsDao.insertBed(const BedModel(
        id: 0,
        bedNo: 'MG-01',
        ward: 'Male General',
        type: 'General',
        tariffPaise: 80000,
        status: 'Available',
      ));
      await db.hmsDao.insertIpdAdmission(const IpdAdmissionModel(
        id: 0,
        patientName: 'Test IPD Patient',
        uhid: 'UHID-IPD-001',
        ward: 'Male General',
        bedNo: 'MG-01',
        doctorName: 'Dr. Ramesh Sharma',
        admitDate: '2026-10-31',
        days: 1,
        diagnosis: 'Chest Pain observation',
        status: 'Admitted',
        depositPaise: 500000,
        notes: [],
        medications: [],
      ));

      final admissions = await db.hmsDao.getAllIpdAdmissions();
      expect(admissions, isNotEmpty);
      final firstAdm = admissions.first;

      await db.hmsDao.addIpdNursingNote(firstAdm.id, {
        'time': 'Just now',
        'author': 'Staff Nurse',
        'note': 'Vitals checked, patient afebrile',
      });

      final admWithNote = await db.hmsDao.getIpdAdmissionById(firstAdm.id);
      expect(
          admWithNote?.notes
              .any((n) => n['note'] == 'Vitals checked, patient afebrile'),
          isTrue);

      await db.hmsDao.quickDischargePatient(firstAdm.id, firstAdm.bedNo);
      final dischargedAdm = await db.hmsDao.getIpdAdmissionById(firstAdm.id);
      expect(dischargedAdm?.status, equals('Discharged'));

      final beds = await db.hmsDao.getAllBeds();
      final bed = beds.firstWhere((b) => b.bedNo == firstAdm.bedNo);
      expect(bed.status, equals('Cleaning'));
    });

    test(
        '10. Laboratory order insertion persists to database and can be retrieved',
        () async {
      const newOrder = LabOrderModel(
        id: 0,
        orderNo: 'L-999',
        patientName: 'Test Lab Patient',
        uhid: 'UHID-000099',
        testName: 'Complete Blood Count (CBC)',
        doctorName: 'Dr. Ramesh Sharma',
        sampleType: 'Whole Blood (EDTA)',
        priority: 'STAT (Emergency)',
        status: 'Pending Collection',
        orderedAt: 'Today, 10:00 AM',
        parameters: [
          {
            'param': 'Hemoglobin (Hb)',
            'val': '14.5',
            'unit': 'g/dL',
            'refLow': 13.0,
            'refHigh': 17.0
          },
        ],
      );

      await db.hmsDao.insertLabOrder(newOrder);

      final retrieved = await db.hmsDao.getLabOrderById('L-999');
      expect(retrieved, isNotNull);
      expect(retrieved?.patientName, equals('Test Lab Patient'));
      expect(retrieved?.testName, equals('Complete Blood Count (CBC)'));
      expect(retrieved?.priority, equals('STAT (Emergency)'));
      expect(retrieved?.parameters.length, equals(1));

      final completedParameters = [
        {
          'param': 'Hemoglobin (Hb)',
          'val': '14.5',
          'unit': 'g/dL',
          'refLow': 13.0,
          'refHigh': 17.0,
        },
      ];
      await db.hmsDao
          .updateLabOrderResults('L-999', completedParameters, 'Completed');

      final editedParameters = [
        {
          'param': 'Hemoglobin (Hb)',
          'val': '15.2',
          'unit': 'g/dL',
          'refLow': 13.0,
          'refHigh': 17.0,
        },
      ];
      await db.hmsDao
          .updateLabOrderResults('L-999', editedParameters, 'Completed');

      final editedOrder = await db.hmsDao.getLabOrderById('L-999');
      expect(editedOrder?.status, equals('Completed'));
      expect(editedOrder?.parameters.single['val'], equals('15.2'));
    });

    test(
        '11. Hospital owner settings upsert and retrieval persists via SettingsDao',
        () async {
      await db.settingsDao
          .upsertSetting('hospital_name', 'Sunrise Memorial Hospital');
      await db.settingsDao.upsertSetting('opd_fee', '650');
      await db.settingsDao.upsertSetting('auto_bed_cleaning', 'true');

      final nameRow = await db.settingsDao.getSetting('hospital_name');
      final feeRow = await db.settingsDao.getSetting('opd_fee');
      final cleanRow = await db.settingsDao.getSetting('auto_bed_cleaning');

      expect(nameRow?.value, equals('Sunrise Memorial Hospital'));
      expect(feeRow?.value, equals('650'));
      expect(cleanRow?.value, equals('true'));
    });

    test('12. Staff updating and deleting works through database', () async {
      await db.hmsDao.insertStaff(const StaffModel(
        id: 0,
        uuid: 'staff-uuid-12',
        name: 'Dr. Test Staff',
        role: 'Doctor',
        regNo: 'MCI-12345',
        department: 'Cardiology',
        phone: '+91 91234 56789',
        email: 'test.staff@hospital.local',
        feePaise: 50000,
        status: 'Active',
      ));
      final staffList = await db.hmsDao.getAllStaff();
      final target = staffList.first;

      final updated = target.copyWith(
        name: 'Dr. Test Staff (Senior Consultant)',
        phone: '+91 91234 99999',
        qualification: 'MBBS, MD, DM (Cardiology)',
        feePaise: 95000,
      );

      await db.hmsDao.updateStaff(updated);
      final refreshed = await db.hmsDao.getStaffById(target.id);
      expect(refreshed?.name, equals('Dr. Test Staff (Senior Consultant)'));
      expect(refreshed?.phone, equals('+91 91234 99999'));
      expect(refreshed?.qualification, equals('MBBS, MD, DM (Cardiology)'));
      expect(refreshed?.feePaise, equals(95000));

      // Test delete
      await db.hmsDao.deleteStaff(target.id, updated.name);
      final afterDelete = await db.hmsDao.getStaffById(target.id);
      expect(afterDelete, isNull);
    });

    test(
        '13. Medicine insertion with batch and MRP, updating, and deletion in SQLite',
        () async {
      const newMed = MedicineModel(
        id: 0,
        name: 'Tab. Metformin 500mg',
        genericName: 'Metformin Hydrochloride',
        category: 'Antidiabetic',
        form: 'Tablet',
        strength: '500mg',
        unit: 'Strip (10 tabs)',
        supplier: 'USV Private Limited',
        manufacturer: 'USV Private Limited',
        stockQty: 80,
        reorderLevel: 20,
        mrpPaise: 4200,
        rackLocation: 'Rack B-4',
      );

      final medId = await db.hmsDao.insertMedicine(
        newMed,
        batchNo: 'MET-5001',
        expiryDate: '30/11/2027',
        mrpPaise: 4200,
      );

      expect(medId, greaterThan(0));

      final allMeds = await db.hmsDao.getAllMedicines();
      final added = allMeds.firstWhere((m) => m.id == medId);
      expect(added.name, equals('Tab. Metformin 500mg'));
      expect(added.genericName, equals('Metformin Hydrochloride'));
      expect(added.form, equals('Tablet'));
      expect(added.mrpPaise, equals(4200));
      expect(added.mrpFormatted, equals('₹42.00'));
      expect(added.stockQty, equals(80));

      // Batch check
      final batches = await db.hmsDao.getNearExpiryBatches();
      expect(batches.any((b) => b.batchNo == 'MET-5001'), isTrue);

      // Update medicine
      final updatedMed = added.copyWith(
        stockQty: 100,
        mrpPaise: 4500,
        rackLocation: 'Rack B-5',
      );
      await db.hmsDao.updateMedicine(updatedMed);

      final afterUpdate =
          (await db.hmsDao.getAllMedicines()).firstWhere((m) => m.id == medId);
      expect(afterUpdate.stockQty, equals(100));
      expect(afterUpdate.mrpPaise, equals(4500));
      expect(afterUpdate.mrpFormatted, equals('₹45.00'));

      // Delete medicine
      await db.hmsDao.deleteMedicine(medId, updatedMed.name);
      final afterDelete =
          (await db.hmsDao.getAllMedicines()).where((m) => m.id == medId);
      expect(afterDelete, isEmpty);
    });

    test('14. Appointment update & delete in SQLite', () async {
      await db.hmsDao.insertAppointment(const AppointmentModel(
        id: 0,
        tokenNo: '20',
        patientName: 'Target Patient',
        uhid: 'UHID-000020',
        doctorName: 'Dr. Sunita Verma',
        department: 'Orthopaedics',
        date: 'Today',
        timeSlot: '02:00 PM',
        status: 'Scheduled',
        visitType: 'Scheduled',
        notes: 'Followup',
      ));
      final aptList = await db.hmsDao.getAllAppointments();
      final target = aptList.first;

      await db.hmsDao.updateAppointmentStatus(target.id, 'In Consultation');
      final updatedList = await db.hmsDao.getAllAppointments();
      expect(updatedList.firstWhere((a) => a.id == target.id).status,
          equals('In Consultation'));

      await db.hmsDao.deleteAppointment(target.id, target.patientName);
      final afterDelete = await db.hmsDao.getAllAppointments();
      expect(afterDelete.any((a) => a.id == target.id), isFalse);
    });

    test('15. IPD admission update & delete in SQLite releases bed', () async {
      await db.hmsDao.insertBed(const BedModel(
        id: 0,
        bedNo: 'FG-01',
        ward: 'Female General',
        type: 'General',
        tariffPaise: 80000,
        status: 'Available',
      ));
      await db.hmsDao.insertIpdAdmission(const IpdAdmissionModel(
        id: 0,
        patientName: 'Adm Test Patient',
        uhid: 'UHID-ADM-002',
        ward: 'Female General',
        bedNo: 'FG-01',
        doctorName: 'Dr. Sunita Verma',
        admitDate: '2026-10-31',
        days: 1,
        diagnosis: 'Fracture observation',
        status: 'Admitted',
        depositPaise: 200000,
        notes: [],
        medications: [],
      ));
      final admissions = await db.hmsDao.getAllIpdAdmissions();
      final target = admissions.first;

      await db.hmsDao
          .deleteIpdAdmission(target.id, target.bedNo, target.patientName);
      final afterDelete = await db.hmsDao.getAllIpdAdmissions();
      expect(afterDelete.any((a) => a.id == target.id), isFalse);

      final beds = await db.hmsDao.getAllBeds();
      final releasedBed = beds.firstWhere((b) => b.bedNo == target.bedNo);
      expect(releasedBed.status, equals('Available'));
    });

    test('16. Lab order delete in SQLite', () async {
      await db.hmsDao.insertLabOrder(const LabOrderModel(
        id: 0,
        orderNo: 'L-DEL-001',
        patientName: 'Del Patient',
        uhid: 'UHID-DEL-001',
        testName: 'Lipid Profile',
        doctorName: 'Dr. Ramesh Sharma',
        sampleType: 'Serum',
        priority: 'Routine',
        status: 'Sample Collected',
        orderedAt: 'Today',
        parameters: [],
      ));
      final orders = await db.hmsDao.getAllLabOrders();
      final target = orders.first;

      await db.hmsDao.deleteLabOrder(target.orderNo, target.testName);
      final afterDelete = await db.hmsDao.getAllLabOrders();
      expect(afterDelete.any((o) => o.orderNo == target.orderNo), isFalse);
    });

    test('17. Invoice update payment status and delete in SQLite', () async {
      await db.hmsDao.insertInvoice(const InvoiceModel(
        id: 0,
        invoiceNo: 'INV-DEL-001',
        patientName: 'Invoice Test Patient',
        uhid: 'UHID-INV-001',
        billType: 'OPD Consultation',
        subtotalPaise: 50000,
        taxPaise: 0,
        totalPaise: 50000,
        paidPaise: 0,
        duePaise: 50000,
        paymentMode: 'Cash',
        status: 'Pending',
        dateTime: 'Today, 11:00 AM',
        items: [],
      ));
      final invoices = await db.hmsDao.getAllInvoices();
      final target = invoices.first;

      await db.hmsDao
          .updateInvoiceStatus(target.invoiceNo, 'Paid', target.totalPaise);
      final updated = await db.hmsDao.getInvoiceById(target.invoiceNo);
      expect(updated?.status, equals('Paid'));
      expect(updated?.duePaise, equals(0));

      await db.hmsDao.deleteInvoice(target.id, target.invoiceNo);
      final afterDelete = await db.hmsDao.getInvoiceById(target.invoiceNo);
      expect(afterDelete, isNull);
    });

    test(
        '18. Pharmacy POS multi-item counter sale deducting inventory and creating invoice in SQLite',
        () async {
      final aspId = await db.hmsDao.insertMedicine(const MedicineModel(
        id: 0,
        name: 'Tab. Aspirin 75mg',
        genericName: 'Aspirin',
        category: 'Cardiology',
        form: 'Tablet',
        strength: '75mg',
        unit: 'Strip',
        supplier: 'Test Supplier',
        manufacturer: 'Bayer India',
        stockQty: 50,
        reorderLevel: 10,
        mrpPaise: 2500,
      ));
      final pcmId = await db.hmsDao.insertMedicine(const MedicineModel(
        id: 0,
        name: 'Tab. Paracetamol 650mg',
        genericName: 'Paracetamol',
        category: 'Analgesic',
        form: 'Tablet',
        strength: '650mg',
        unit: 'Strip',
        supplier: 'Test Supplier',
        manufacturer: 'Cipla Ltd',
        stockQty: 50,
        reorderLevel: 10,
        mrpPaise: 3200,
      ));

      final medsBefore = await db.hmsDao.getAllMedicines();
      final aspirin = medsBefore.firstWhere((m) => m.id == aspId);
      final paracetamol = medsBefore.firstWhere((m) => m.id == pcmId);

      final initialAspQty = aspirin.stockQty;
      final initialPcmQty = paracetamol.stockQty;

      // Sell 10 Aspirin and 5 Paracetamol via POS
      await db.hmsDao.dispenseMedicine(aspirin.id, 10, 'Walk-in POS Customer');
      await db.hmsDao
          .dispenseMedicine(paracetamol.id, 5, 'Walk-in POS Customer');

      final medsAfter = await db.hmsDao.getAllMedicines();
      expect(medsAfter.firstWhere((m) => m.id == aspirin.id).stockQty,
          equals(initialAspQty - 10));
      expect(medsAfter.firstWhere((m) => m.id == paracetamol.id).stockQty,
          equals(initialPcmQty - 5));

      // Create POS Invoice
      final posInvoice = InvoiceModel(
        id: 0,
        invoiceNo: 'PINV-TEST-001',
        patientName: 'Walk-in POS Customer',
        uhid: 'WALK-IN',
        billType: 'Pharmacy POS Sale',
        subtotalPaise: 41000,
        taxPaise: 2050,
        totalPaise: 43050,
        paidPaise: 43050,
        duePaise: 0,
        paymentMode: 'UPI / QR Code',
        status: 'Paid',
        dateTime: 'Today, 12:30',
        items: [
          {
            'desc': 'Tab. Aspirin 75mg (10 Strips)',
            'rate': '₹25.00',
            'qty': '10',
            'total': '₹250.00'
          },
          {
            'desc': 'Tab. Paracetamol 650mg (5 Strips)',
            'rate': '₹32.00',
            'qty': '5',
            'total': '₹160.00'
          },
        ],
      );

      await db.hmsDao.insertInvoice(posInvoice);
      final retrieved = await db.hmsDao.getInvoiceById('PINV-TEST-001');
      expect(retrieved, isNotNull);
      expect(retrieved?.patientName, equals('Walk-in POS Customer'));
      expect(retrieved?.paymentMode, equals('UPI / QR Code'));
      expect(retrieved?.totalPaise, equals(43050));
    });

    test('19. Supplier insertion and retrieval in SQLite', () async {
      final suppliersBefore = await db.hmsDao.getAllSuppliers();
      expect(suppliersBefore, isEmpty);

      const newSupplier = SupplierModel(
        id: 0,
        uuid: 'sup-test-999',
        name: 'Apex Pharma Distributors',
        contactPerson: 'Karan Mehra',
        phone: '+91 98888 77777',
        email: 'karan@apexpharma.com',
        address: 'Sector 62, Noida',
        gstNo: '09AABCA8899K1Z8',
      );

      await db.hmsDao.insertSupplier(newSupplier);
      final suppliersAfter = await db.hmsDao.getAllSuppliers();
      expect(suppliersAfter.any((s) => s.name == 'Apex Pharma Distributors'),
          isTrue);
    });

    test(
        '20. Stock Inward GRN purchase consignment increments stock & creates batch',
        () async {
      final targetId = await db.hmsDao.insertMedicine(const MedicineModel(
        id: 0,
        name: 'Inj. Ceftriaxone 1g',
        genericName: 'Ceftriaxone',
        category: 'Antibiotic',
        form: 'Injection',
        strength: '1g',
        unit: 'Vial',
        supplier: 'Alkem Laboratories',
        manufacturer: 'Alkem Laboratories',
        stockQty: 10,
        reorderLevel: 20,
        mrpPaise: 8500,
      ));
      final medsBefore = await db.hmsDao.getAllMedicines();
      final targetMed = medsBefore.firstWhere((m) => m.id == targetId);
      final initialStock = targetMed.stockQty;

      final poItem = PurchaseItemModel(
        id: 0,
        medicineId: targetMed.id,
        medicineName: targetMed.name,
        batchNo: 'GRN-BAT-101',
        expiryDate: '2028-12-31',
        qty: 150,
        unitPricePaise: 2000,
        mrpPaise: 3500,
        totalPaise: 300000,
      );

      final po = PurchaseOrderModel(
        id: 0,
        uuid: 'grn-test-001',
        supplierId: 1,
        supplierName: 'Alkem Laboratories',
        invoiceNo: 'INV-TEST-GRN-999',
        invoiceDate: '2026-10-31',
        totalAmountPaise: 300000,
        status: 'received',
        items: [poItem],
      );

      await db.hmsDao.recordStockInward(po);

      // Verify stock incremented by 150
      final medsAfter = await db.hmsDao.getAllMedicines();
      expect(medsAfter.firstWhere((m) => m.id == targetMed.id).stockQty,
          equals(initialStock + 150));

      // Verify batch created
      final batches = await db.hmsDao.getAllBatches();
      expect(
          batches.any((b) => b.batchNo == 'GRN-BAT-101' && b.stockQty >= 150),
          isTrue);

      // Verify purchase order retrieved
      final purchases = await db.hmsDao.getAllPurchases();
      expect(purchases.any((p) => p.invoiceNo == 'INV-TEST-GRN-999'), isTrue);
    });

    test(
        '21. Batch insertion, update, and deletion with master stock synchronization',
        () async {
      final targetId = await db.hmsDao.insertMedicine(const MedicineModel(
        id: 0,
        name: 'Tab. Batch Sync Test',
        genericName: 'Sync Test',
        category: 'Analgesic',
        form: 'Tablet',
        strength: '100mg',
        unit: 'Strip',
        supplier: 'Test Supplier',
        manufacturer: 'Test Manufacturer',
        stockQty: 20,
        reorderLevel: 10,
        mrpPaise: 2000,
      ));
      final meds = await db.hmsDao.getAllMedicines();
      final target = meds.firstWhere((m) => m.id == targetId);
      final initialStock = target.stockQty;

      final batch = MedicineBatchModel(
        id: 0,
        medicineId: target.id,
        medicineName: target.name,
        batchNo: 'TEST-BATCH-777',
        expiryDate: '2029-05-30',
        stockQty: 80,
        mrpPaise: 4000,
        costPaise: 2800,
      );

      await db.hmsDao.insertBatch(batch);
      final medsAfterAdd = await db.hmsDao.getAllMedicines();
      expect(medsAfterAdd.firstWhere((m) => m.id == target.id).stockQty,
          equals(initialStock + 80));

      final batches = await db.hmsDao.getAllBatches();
      final createdBatch =
          batches.firstWhere((b) => b.batchNo == 'TEST-BATCH-777');
      expect(createdBatch.stockQty, equals(80));

      // Delete batch and verify master stock is deducted
      await db.hmsDao
          .deleteBatch(createdBatch.id, createdBatch.batchNo, target.id);
      final medsAfterDel = await db.hmsDao.getAllMedicines();
      expect(medsAfterDel.firstWhere((m) => m.id == target.id).stockQty,
          equals(initialStock));
    });

    test(
        '22. Stock adjustment for breakage / wastage logs audit and adjusts stock',
        () async {
      final targetId = await db.hmsDao.insertMedicine(const MedicineModel(
        id: 0,
        name: 'Tab. Adjustment Test',
        genericName: 'Adjustment Test',
        category: 'Analgesic',
        form: 'Tablet',
        strength: '250mg',
        unit: 'Strip',
        supplier: 'Test Supplier',
        manufacturer: 'Test Manufacturer',
        stockQty: 50,
        reorderLevel: 10,
        mrpPaise: 2000,
      ));
      final medsBefore = await db.hmsDao.getAllMedicines();
      final target = medsBefore.firstWhere((m) => m.id == targetId);
      final initialStock = target.stockQty;

      // Deduct 5 units due to breakage
      await db.hmsDao.recordStockAdjustment(
        medicineId: target.id,
        medicineName: target.name,
        batchNo: 'PCM-890',
        adjustmentQty: -5,
        reason: 'Broken ampoules during ward transit',
        adjustedBy: 'Senior Pharmacist',
      );

      final medsAfter = await db.hmsDao.getAllMedicines();
      expect(medsAfter.firstWhere((m) => m.id == target.id).stockQty,
          equals(initialStock - 5));

      final adjustments = await db.hmsDao.getAllStockAdjustments();
      expect(
          adjustments.any((a) =>
              a.reason.contains('Broken ampoules') && a.adjustmentQty == -5),
          isTrue);
    });
  });
}
