import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/domain/entities/patient.dart';

void main() {
  group('HMS Models Completeness & Serialization Tests', () {
    test('1. StaffModel & DepartmentModel & DoctorModel serialization', () {
      final staff = StaffModel(
        id: 1,
        uuid: 'staff-uuid-1',
        name: 'Dr. Jane Doe',
        role: 'Doctor',
        regNo: 'DOC-1234',
        department: 'Cardiology',
        phone: '+91 98765 00001',
        email: 'jane.doe@hospital.local',
        feePaise: 80000,
        status: 'Active',
        gender: 'Female',
        qualification: 'MBBS, MD',
      );

      final map = staff.toMap();
      expect(map['name'], equals('Dr. Jane Doe'));
      expect(staff.feeFormatted, equals('₹800.00'));

      final json = staff.toJson();
      final fromJson = StaffModel.fromJson(json);
      expect(fromJson.name, equals(staff.name));
      expect(fromJson.qualification, equals('MBBS, MD'));

      final copy = staff.copyWith(feePaise: 90000);
      expect(copy.feePaise, equals(90000));
      expect(copy.name, equals(staff.name));

      final dept = DepartmentModel(
        id: 1,
        uuid: 'dept-1',
        name: 'Cardiology',
        description: 'Heart and vascular care',
      );
      expect(DepartmentModel.fromJson(dept.toJson()).name, equals('Cardiology'));

      final doc = DoctorModel(
        id: 1,
        uuid: 'doc-1',
        staffId: 1,
        doctorName: 'Dr. Jane Doe',
        specialisation: 'Interventional Cardiology',
        consultationFeePaise: 80000,
      );
      expect(doc.consultationFeeFormatted, equals('₹800.00'));
    });

    test('2. BedModel, WardModel, RoomModel, BedTransferModel serialization', () {
      final bed = BedModel(
        id: 1,
        bedNo: 'ICU-01',
        ward: 'ICU',
        type: 'ICU',
        tariffPaise: 500000,
        status: 'occupied',
        patientName: 'Ramesh Kumar',
        uhid: 'UHID-000001',
      );

      expect(bed.tariffFormatted, equals('₹5000/day'));
      expect(bed.isOccupied, isTrue);

      final bedJson = bed.toJson();
      final fromJson = BedModel.fromJson(bedJson);
      expect(fromJson.bedNo, equals('ICU-01'));
      expect(fromJson.patientName, equals('Ramesh Kumar'));

      final cleared = bed.copyWith(clearPatient: true);
      expect(cleared.patientName, isNull);

      final ward = WardModel(
        id: 1,
        uuid: 'w-1',
        name: 'General Male Ward',
        totalBeds: 20,
        occupiedBeds: 15,
      );
      expect(ward.availableBeds, equals(5));
      expect(ward.occupancyRate, equals(75.0));

      final transfer = BedTransferModel(
        id: 1,
        uuid: 'bt-1',
        admissionId: 10,
        fromBedNo: 'GW-01',
        toBedNo: 'ICU-02',
        transferredAt: '2026-10-31 10:00',
        reason: 'Patient vitals unstable',
        transferredBy: 'Dr. Sharma',
      );
      expect(BedTransferModel.fromJson(transfer.toJson()).toBedNo, equals('ICU-02'));
    });

    test('3. AppointmentModel, AppointmentSlotModel, QueueTokenModel serialization', () {
      final apt = AppointmentModel(
        id: 1,
        tokenNo: '05',
        patientName: 'Sunita Devi',
        uhid: 'UHID-000002',
        doctorName: 'Dr. Ramesh Sharma',
        department: 'General Medicine',
        date: '2026-10-31',
        timeSlot: '10:30 AM',
        status: 'Scheduled',
        visitType: 'Consultation',
        notes: 'Followup',
      );

      expect(apt.isScheduled, isTrue);
      final json = apt.toJson();
      final fromJson = AppointmentModel.fromJson(json);
      expect(fromJson.patientName, equals('Sunita Devi'));
      expect(fromJson.tokenNo, equals('05'));

      final token = QueueTokenModel(
        tokenNo: '09',
        patientName: 'Vikram Patel',
        uhid: 'UHID-000003',
        doctorName: 'Dr. Sharma',
        department: 'OPD',
        status: 'Waiting',
        issueTime: '11:15 AM',
      );
      expect(QueueTokenModel.fromJson(token.toJson()).tokenNo, equals('09'));
    });

    test('4. OpdVisitModel, VitalsModel, ConsultationModel serialization', () {
      final opd = OpdVisitModel(
        id: 1,
        tokenNo: '01',
        patientName: 'Ramesh Kumar',
        uhid: 'UHID-000001',
        doctorName: 'Dr. Sharma',
        department: 'Cardiology',
        ageGender: '45 M',
        status: 'In Consultation',
        complaint: 'Chest pain',
        history: 'HTN for 5 years',
        examination: 'Chest clear',
        diagnosis: 'I20.9 - Angina Pectoris',
        advice: 'Low salt diet',
        bpSys: '130',
        bpDia: '85',
        pulse: '76',
        temp: '98.4',
        spo2: '99',
        weight: '72',
        height: '172',
        medications: const [
          {'name': 'Tab. Aspirin 75mg', 'dose': '1 Tab', 'frequency': 'OD'}
        ],
      );

      expect(opd.vitalsSummary, contains('BP 130/85'));
      expect(opd.bmi, isNotNull);
      expect(opd.bmi!, closeTo(24.3, 0.2));

      final json = opd.toJson();
      final fromJson = OpdVisitModel.fromJson(json);
      expect(fromJson.diagnosis, contains('Angina'));
      expect(fromJson.medications.length, equals(1));

      final vitals = VitalsModel(
        id: 1,
        uuid: 'vit-1',
        visitId: 1,
        bpSystolic: 120,
        bpDiastolic: 80,
        pulse: 72,
        temperatureC: 37.0,
        spo2: 98,
        recordedAt: '2026-10-31 09:30',
      );
      expect(vitals.bpDisplay, equals('120/80 mmHg'));
      expect(vitals.pulseDisplay, equals('72 bpm'));
    });

    test('5. IpdAdmissionModel, NursingNoteModel, MedicationAdministrationModel serialization', () {
      final ipd = IpdAdmissionModel(
        id: 1,
        patientName: 'Sunita Devi',
        uhid: 'UHID-000002',
        ward: 'Female Ward',
        bedNo: 'FW-04',
        doctorName: 'Dr. Sharma',
        admitDate: '2026-10-25',
        days: 6,
        diagnosis: 'Acute Gastroenteritis',
        status: 'Admitted',
        depositPaise: 1000000,
        notes: const [
          {'time': '08:00', 'note': 'Patient comfortable, hydration maintained'}
        ],
        medications: const [
          {'medicine': 'IV DNS 500ml', 'frequency': 'TDS'}
        ],
      );

      expect(ipd.isAdmitted, isTrue);
      expect(ipd.depositFormatted, equals('₹10000'));

      final json = ipd.toJson();
      final fromJson = IpdAdmissionModel.fromJson(json);
      expect(fromJson.patientName, equals('Sunita Devi'));
      expect(fromJson.notes.length, equals(1));

      final emar = MedicationAdministrationModel(
        id: 1,
        uuid: 'emar-1',
        admissionId: 1,
        medicineName: 'Inj. Ceftriaxone 1g',
        dose: '1g IV',
        route: 'IV',
        scheduledTime: '10:00 AM',
        status: 'given',
        givenTime: '10:05 AM',
        administeredBy: 'Staff Nurse Priya',
      );
      expect(emar.isGiven, isTrue);
      expect(MedicationAdministrationModel.fromJson(emar.toJson()).status, equals('given'));
    });

    test('6. LabOrderModel, LabTestModel, LabParameterResultModel serialization', () {
      final labOrder = LabOrderModel(
        id: 1,
        orderNo: 'LAB-2026-0001',
        patientName: 'Ramesh Kumar',
        uhid: 'UHID-000001',
        testName: 'Complete Blood Count (CBC)',
        doctorName: 'Dr. Sharma',
        sampleType: 'Blood',
        priority: 'Routine',
        status: 'Resulted',
        orderedAt: '2026-10-31 08:30',
        parameters: const [
          {'name': 'Hemoglobin', 'value': '14.2', 'unit': 'g/dL', 'ref': '13.0 - 17.0'}
        ],
      );

      expect(labOrder.isResulted, isTrue);
      final json = labOrder.toJson();
      final fromJson = LabOrderModel.fromJson(json);
      expect(fromJson.orderNo, equals('LAB-2026-0001'));
      expect(fromJson.parameters.first['name'], equals('Hemoglobin'));

      final labTest = LabTestModel(
        id: 1,
        uuid: 'test-1',
        name: 'Lipid Profile',
        pricePaise: 80000,
      );
      expect(labTest.priceFormatted, equals('₹800.00'));
    });

    test('7. MedicineModel, MedicineBatchModel, SupplierModel, PurchaseOrderModel serialization', () {
      final med = MedicineModel(
        id: 1,
        name: 'Paracetamol',
        genericName: 'Acetaminophen',
        category: 'Analgesics',
        stockQty: 500,
        reorderLevel: 100,
        unit: 'Tablet',
        supplier: 'Apollo Pharma',
        form: 'Tablet',
        strength: '650mg',
      );

      expect(med.isLowStock, isFalse);
      final json = med.toJson();
      final fromJson = MedicineModel.fromJson(json);
      expect(fromJson.name, equals('Paracetamol'));
      expect(fromJson.strength, equals('650mg'));

      final batch = MedicineBatchModel(
        id: 1,
        medicineId: 1,
        medicineName: 'Paracetamol 650mg',
        batchNo: 'B2026-12',
        expiryDate: '2028-12-31',
        stockQty: 500,
        mrpPaise: 3500,
        costPaise: 2000,
      );
      expect(batch.mrpFormatted, equals('₹35.00'));
      expect(batch.isExpired, isFalse);
      expect(MedicineBatchModel.fromJson(batch.toJson()).batchNo, equals('B2026-12'));
    });

    test('8. InvoiceModel, InvoiceItemModel, PaymentModel, ServiceModel serialization', () {
      final inv = InvoiceModel(
        id: 1,
        invoiceNo: 'INV-2026-001',
        patientName: 'Ramesh Kumar',
        uhid: 'UHID-000001',
        billType: 'OPD Consultation',
        subtotalPaise: 50000,
        taxPaise: 0,
        totalPaise: 50000,
        paidPaise: 50000,
        duePaise: 0,
        paymentMode: 'Cash',
        status: 'Paid',
        dateTime: '2026-10-31 10:00',
        items: const [
          {'name': 'Doctor Consultation', 'qty': 1, 'rate': 500, 'total': 500}
        ],
      );

      expect(inv.isPaid, isTrue);
      expect(inv.totalFormatted, equals('₹500.00'));
      expect(inv.dueFormatted, equals('₹0.00'));

      final json = inv.toJson();
      final fromJson = InvoiceModel.fromJson(json);
      expect(fromJson.invoiceNo, equals('INV-2026-001'));
      expect(fromJson.items.length, equals(1));

      final payment = PaymentModel(
        id: 1,
        uuid: 'pay-1',
        invoiceId: 1,
        paymentMode: 'UPI',
        amountPaise: 50000,
        referenceNo: 'UPI9876543210',
        receivedBy: 'Reception Staff',
        paidAt: '2026-10-31 10:05',
      );
      expect(payment.amountFormatted, equals('₹500.00'));
    });

    test('9. PrescriptionModel & PrescriptionItemModel serialization', () {
      final rx = PrescriptionModel(
        id: 1,
        uuid: 'rx-1',
        visitId: 1,
        doctorId: 2,
        doctorName: 'Dr. Sharma',
        patientName: 'Ramesh Kumar',
        uhid: 'UHID-000001',
        prescribedAt: '2026-10-31 10:00',
        items: const [
          PrescriptionItemModel(
            id: 1,
            uuid: 'rxi-1',
            prescriptionId: 1,
            medicineId: 1,
            medicineName: 'Tab. Paracetamol 650mg',
            dose: '1 Tab',
            frequency: 'TDS',
            duration: '3 days',
            instructions: 'After food',
            qtyPrescribed: 9,
          )
        ],
      );

      expect(rx.isActive, isTrue);
      expect(rx.items.first.summary, contains('Tab. Paracetamol 650mg'));
      final fromJson = PrescriptionModel.fromJson(rx.toJson());
      expect(fromJson.items.length, equals(1));
      expect(fromJson.items.first.frequency, equals('TDS'));
    });

    test('10. PatientModel & Domain Patient bridging', () {
      final domainPatient = Patient(
        id: 5,
        uuid: 'patient-uuid-5',
        uhid: 'UHID-000005',
        name: 'Aarti Singh',
        gender: 'Female',
        dob: DateTime(1995, 5, 15),
        phone: '+91 99999 11111',
        bloodGroup: 'B+',
        createdAt: DateTime(2026, 1, 1),
      );

      final model = PatientModel.fromDomain(domainPatient);
      expect(model.name, equals('Aarti Singh'));
      expect(model.uhid, equals('UHID-000005'));
      expect(model.bloodGroup, equals('B+'));

      final convertedBack = model.toDomain();
      expect(convertedBack.name, equals(domainPatient.name));
      expect(convertedBack.uhid, equals(domainPatient.uhid));
      expect(convertedBack.bloodGroup, equals(domainPatient.bloodGroup));
      expect(convertedBack.gender, equals('Female'));
    });

    test('11. Report models & KPIs calculation', () {
      const kpis = DashboardKpiModel(
        todayAppointments: 18,
        todayOpdVisits: 14,
        admittedPatients: 6,
        totalBeds: 24,
        occupiedBeds: 18,
        todayRevenuePaise: 4500000,
        lowStockCount: 2,
        pendingLabOrders: 3,
      );

      expect(kpis.availableBeds, equals(6));
      expect(kpis.bedOccupancyPct, equals(75.0));
      expect(kpis.todayRevenueFormatted, equals('₹45000'));

      final json = kpis.toJson();
      final fromJson = DashboardKpiModel.fromJson(json);
      expect(fromJson.todayAppointments, equals(18));
      expect(fromJson.lowStockCount, equals(2));
    });
  });
}

