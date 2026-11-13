import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';
export 'package:hospital_management/features/patients/patients_provider.dart';

// ── Staff Providers ─────────────────────────────────────────────────────────

final staffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllStaff();
});

// ── Beds Providers ──────────────────────────────────────────────────────────

final bedsListProvider = FutureProvider<List<BedModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllBeds();
});

// ── Appointments Providers ──────────────────────────────────────────────────

final appointmentsListProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllAppointments();
});

// ── OPD Visits Providers ────────────────────────────────────────────────────

final opdQueueProvider = FutureProvider<List<OpdVisitModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllOpdVisits();
});

final opdVisitDetailProvider = FutureProvider.family<OpdVisitModel?, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getOpdVisitById(id);
});

// ── IPD Admissions Providers ────────────────────────────────────────────────

final ipdAdmissionsListProvider = FutureProvider<List<IpdAdmissionModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllIpdAdmissions();
});

final ipdAdmissionDetailProvider = FutureProvider.family<IpdAdmissionModel?, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getIpdAdmissionById(id);
});

// ── Lab Orders Providers ────────────────────────────────────────────────────

final labOrdersListProvider = FutureProvider<List<LabOrderModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllLabOrders();
});

final labOrderDetailProvider = FutureProvider.family<LabOrderModel?, String>((ref, orderNo) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getLabOrderById(orderNo);
});

// ── Pharmacy Providers ──────────────────────────────────────────────────────

final medicinesListProvider = FutureProvider<List<MedicineModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllMedicines();
});

final lowStockMedicinesProvider = FutureProvider<List<MedicineModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getLowStockMedicines();
});

final nearExpiryBatchesProvider = FutureProvider<List<MedicineBatchModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getNearExpiryBatches();
});

final allBatchesProvider = FutureProvider<List<MedicineBatchModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllBatches();
});

final allSuppliersProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllSuppliers();
});

final allPurchasesProvider = FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllPurchases();
});

final allStockAdjustmentsProvider = FutureProvider<List<StockAdjustmentModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllStockAdjustments();
});

// ── Billing Providers ───────────────────────────────────────────────────────

final invoicesListProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllInvoices();
});

final invoiceDetailProvider = FutureProvider.family<InvoiceModel?, String>((ref, invoiceNo) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getInvoiceById(invoiceNo);
});

// ── Audit Logs Provider ─────────────────────────────────────────────────────

final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllAuditLogs();
});

// ── Dashboard Aggregates Provider ───────────────────────────────────────────

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getDashboardStats();
});

// ── Reports Aggregates Provider ─────────────────────────────────────────────

final reportsDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getReportsData();
});

