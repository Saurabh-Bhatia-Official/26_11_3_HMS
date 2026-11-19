import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hospital_management/core/auth/session_service.dart';
import 'package:hospital_management/data/database/app_database.dart';
import 'package:hospital_management/data/models/hms_models.dart';
import 'package:hospital_management/data/remote/backend_api_client.dart';
import 'package:hospital_management/data/remote/hms_remote_repository.dart';
export 'package:hospital_management/features/patients/patients_provider.dart';

// ── Staff Providers ─────────────────────────────────────────────────────────

final staffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .staff();
    } on BackendConnectionException {
      return db.hmsDao.getAllStaff();
    }
  }
  return db.hmsDao.getAllStaff();
});

// ── Beds Providers ──────────────────────────────────────────────────────────

final bedsListProvider = FutureProvider<List<BedModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllBeds();
});

// ── Appointments Providers ──────────────────────────────────────────────────

final appointmentsListProvider =
    FutureProvider<List<AppointmentModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllAppointments();
});

// ── OPD Visits Providers ────────────────────────────────────────────────────

final opdQueueProvider = FutureProvider<List<OpdVisitModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllOpdVisits();
});

final opdVisitDetailProvider =
    FutureProvider.family<OpdVisitModel?, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getOpdVisitById(id);
});

// ── IPD Admissions Providers ────────────────────────────────────────────────

final ipdAdmissionsListProvider =
    FutureProvider<List<IpdAdmissionModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllIpdAdmissions();
});

final ipdAdmissionDetailProvider =
    FutureProvider.family<IpdAdmissionModel?, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getIpdAdmissionById(id);
});

// ── Lab Orders Providers ────────────────────────────────────────────────────

final labOrdersListProvider = FutureProvider<List<LabOrderModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .labOrders();
    } on BackendConnectionException {
      return db.hmsDao.getAllLabOrders();
    }
  }
  return db.hmsDao.getAllLabOrders();
});

final labOrderDetailProvider =
    FutureProvider.family<LabOrderModel?, String>((ref, orderNo) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      final orders =
          await HmsRemoteRepository(ref.read(backendApiClientProvider))
              .labOrders();
      for (final order in orders) {
        if (order.orderNo == orderNo) return order;
      }
      return null;
    } on BackendConnectionException {
      return db.hmsDao.getLabOrderById(orderNo);
    }
  }
  return db.hmsDao.getLabOrderById(orderNo);
});

// ── Pharmacy Providers ──────────────────────────────────────────────────────

final medicinesListProvider = FutureProvider<List<MedicineModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .medicines();
    } on BackendConnectionException {
      return db.hmsDao.getAllMedicines();
    }
  }
  return db.hmsDao.getAllMedicines();
});

final lowStockMedicinesProvider =
    FutureProvider<List<MedicineModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .lowStockMedicines();
    } on BackendConnectionException {
      return db.hmsDao.getLowStockMedicines();
    }
  }
  return db.hmsDao.getLowStockMedicines();
});

final nearExpiryBatchesProvider =
    FutureProvider<List<MedicineBatchModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .nearExpiryBatches();
    } on BackendConnectionException {
      return db.hmsDao.getNearExpiryBatches();
    }
  }
  return db.hmsDao.getNearExpiryBatches();
});

final allBatchesProvider =
    FutureProvider<List<MedicineBatchModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .batches();
    } on BackendConnectionException {
      return db.hmsDao.getAllBatches();
    }
  }
  return db.hmsDao.getAllBatches();
});

final allSuppliersProvider = FutureProvider<List<SupplierModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .suppliers();
    } on BackendConnectionException {
      return db.hmsDao.getAllSuppliers();
    }
  }
  return db.hmsDao.getAllSuppliers();
});

final allPurchasesProvider =
    FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllPurchases();
});

final allStockAdjustmentsProvider =
    FutureProvider<List<StockAdjustmentModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .stockAdjustments();
    } on BackendConnectionException {
      return db.hmsDao.getAllStockAdjustments();
    }
  }
  return db.hmsDao.getAllStockAdjustments();
});

// ── Billing Providers ───────────────────────────────────────────────────────

final invoicesListProvider = FutureProvider<List<InvoiceModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      return await HmsRemoteRepository(ref.read(backendApiClientProvider))
          .invoices();
    } on BackendConnectionException {
      return db.hmsDao.getAllInvoices();
    }
  }
  return db.hmsDao.getAllInvoices();
});

final invoiceDetailProvider =
    FutureProvider.family<InvoiceModel?, String>((ref, invoiceNo) async {
  final db = ref.watch(appDatabaseProvider);
  if (_remoteEnabled(ref)) {
    try {
      final invoices =
          await HmsRemoteRepository(ref.read(backendApiClientProvider))
              .invoices();
      for (final invoice in invoices) {
        if (invoice.invoiceNo == invoiceNo ||
            invoice.id.toString() == invoiceNo) {
          return invoice;
        }
      }
      return null;
    } on BackendConnectionException {
      return db.hmsDao.getInvoiceById(invoiceNo);
    }
  }
  return db.hmsDao.getInvoiceById(invoiceNo);
});

// ── Audit Logs Provider ─────────────────────────────────────────────────────

final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.hmsDao.getAllAuditLogs();
});

// ── Dashboard Aggregates Provider ───────────────────────────────────────────

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final local = await db.hmsDao.getDashboardStats();
  if (!_remoteEnabled(ref)) return local;
  try {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final remote = await HmsRemoteRepository(ref.read(backendApiClientProvider))
        .reportSummary(
      from: today,
      to: today,
    );
    return {
      ...local,
      'todayRevenuePaise': remote['revenuePaise'],
      'lowStockMedicines': remote['lowStockMedicines'],
      'pendingLabOrders': remote['pendingLabOrders'],
    };
  } on BackendConnectionException {
    return local;
  }
});

// ── Reports Aggregates Provider ─────────────────────────────────────────────

final reportsDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final local = await db.hmsDao.getReportsData();
  if (!_remoteEnabled(ref)) return local;
  try {
    final now = DateTime.now().toUtc();
    final firstOfMonth =
        DateTime.utc(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final today = now.toIso8601String().substring(0, 10);
    final remote = await HmsRemoteRepository(ref.read(backendApiClientProvider))
        .reportSummary(from: firstOfMonth, to: today);
    return {
      ...local,
      'totalRevenuePaise': remote['revenuePaise'],
      'totalDuePaise':
          remote['currentOutstandingPaise'] ?? local['totalDuePaise'],
    };
  } on BackendConnectionException {
    return local;
  }
});

bool _remoteEnabled(Ref ref) =>
    ref.watch(backendApiClientProvider).isConfigured &&
    (ref.watch(sessionProvider).user?.isRemote ?? false);
