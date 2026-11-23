import 'dart:convert';
import 'dart:math' as math;

import 'package:hospital_management/data/models/billing_models.dart';
import 'package:hospital_management/data/models/lab_models.dart';
import 'package:hospital_management/data/models/pharmacy_models.dart';
import 'package:hospital_management/data/models/report_models.dart';
import 'package:hospital_management/data/models/staff_models.dart';
import 'package:hospital_management/data/remote/backend_api_client.dart';

class HmsRemoteRepository {
  const HmsRemoteRepository(this._api);

  final BackendApiClient _api;

  Future<List<StaffModel>> staff() async {
    final rows = _asList(await _api.get('/api/staff'));
    return rows
        .map((row) => StaffModel.fromMap({
              'id': row['id'],
              'uuid': row['uuid'],
              'name': row['name'],
              'role': _title(row['role'] as String? ?? ''),
              'reg_no': row['regNo'],
              'department': row['department'] ?? '',
              'phone': row['phone'],
              'email': row['email'],
              'consultation_fee': row['consultationFeePaise'],
              'status': row['active'] == true ? 'Active' : 'Inactive',
              'gender': row['gender'],
              'dob': row['dob'],
              'address': row['address'],
              'qualification': row['qualification'],
              'photo_path': row['photoPath'],
              'created_at': row['createdAt'],
              'updated_at': row['updatedAt'],
            }))
        .toList();
  }

  Future<List<LabOrderModel>> labOrders() async {
    final rows = _asList(await _api.get('/api/lab/orders'));
    return rows.map((row) {
      final results = _asList(row['results'] ?? const []);
      final parameters = results
          .map((result) => {
                'param': result['parameterName'],
                'val': result['value'],
                'unit': result['unit'],
                'ref': result['referenceRange'],
                'flag': result['abnormalFlag'],
              })
          .toList();
      return LabOrderModel.fromMap({
        'id': row['id'],
        'order_no': row['orderNo'],
        'patient_name': row['patientName'],
        'uhid': row['uhid'],
        'test_name': row['testName'],
        'doctor_name': row['doctorName'],
        'sample_type': row['sampleType'],
        'priority': _title(row['priority'] as String? ?? 'routine'),
        'status': _labStatus(row['status'] as String? ?? 'pending'),
        'ordered_at': row['orderedAt'],
        'params_json': jsonEncode(parameters),
        'patient_id': row['patientId'],
        'test_id': row['testId'],
        'sample_collected_at': row['sampleCollectedAt'],
        'result_date': row['resultedAt'],
        'technician_notes': row['notes'],
        'created_at': row['createdAt'],
        'updated_at': row['updatedAt'],
      });
    }).toList();
  }

  Future<List<MedicineModel>> medicines() async {
    final rows = _asList(await _api.get('/api/pharmacy/medicines'));
    return rows
        .map((row) => MedicineModel.fromMap({
              'id': row['id'],
              'uuid': row['uuid'],
              'name': row['name'],
              'generic_name': row['genericName'],
              'category': row['category'],
              'stock_qty': row['stockQty'],
              'reorder_level': row['reorderLevel'],
              'unit': row['unit'],
              'supplier': '',
              'form': row['form'],
              'strength': row['strength'],
              'manufacturer': row['manufacturer'],
              'tax_rate_pct': row['taxRatePct'],
              'hsn_code': row['hsnCode'],
              'mrp_paise': 0,
              'created_at': row['createdAt'],
              'updated_at': row['updatedAt'],
            }))
        .toList();
  }

  Future<List<MedicineBatchModel>> batches() async {
    final medicines = _asList(await _api.get('/api/pharmacy/medicines'));
    final batches = <MedicineBatchModel>[];
    for (final medicine in medicines) {
      final medicineId = medicine['id'];
      if (medicineId is! int) continue;
      final rows = _asList(
          await _api.get('/api/pharmacy/medicines/$medicineId/batches'));
      batches.addAll(rows.map((row) => MedicineBatchModel.fromMap({
            'id': row['id'],
            'medicine_id': row['medicineId'],
            'medicine_name': row['medicineName'],
            'batch_no': row['batchNo'],
            'expiry_date': row['expiryDate'],
            'stock_qty': row['quantityOnHand'],
            'mrp_paise': row['mrpPaise'],
            'cost_paise': row['purchasePricePaise'],
            'uuid': row['uuid'],
            'manufacture_date': row['manufactureDate'],
            'supplier_id': row['supplierId'],
            'created_at': row['createdAt'],
            'updated_at': row['updatedAt'],
          })));
    }
    return batches;
  }

  Future<List<SupplierModel>> suppliers() async {
    final rows = _asList(await _api.get('/api/pharmacy/suppliers'));
    return rows
        .map((row) => SupplierModel.fromMap({
              'id': row['id'],
              'uuid': row['uuid'],
              'name': row['name'],
              'contact_person': row['contactPerson'],
              'phone': row['phone'],
              'email': row['email'],
              'address': row['address'],
              'gst_no': row['gstNo'],
              'created_at': row['createdAt'],
              'updated_at': row['updatedAt'],
            }))
        .toList();
  }

  Future<List<InvoiceModel>> invoices() async {
    final rows = _asList(await _api.get('/api/billing/invoices'));
    return rows.map((row) {
      final items = _asList(row['items'] ?? const [])
          .map((item) => {
                'uuid': item['uuid'] ?? '',
                'invoice_id': row['id'],
                'item_type': item['itemType'],
                'item_id': item['itemId'],
                'description': item['description'],
                'qty': item['qty'],
                'unit_price_paise': item['unitPricePaise'],
                'discount_paise': item['discountPaise'],
                'tax_rate_pct': item['taxRatePct'],
                'total_paise': item['totalPaise'],
              })
          .toList();
      return InvoiceModel.fromMap({
        'id': row['id'],
        'invoice_no': row['invoiceNo'],
        'patient_name': row['patientName'],
        'uhid': row['uhid'],
        'bill_type': row['invoiceType'],
        'subtotal_paise': row['subtotalPaise'],
        'tax_paise': row['taxPaise'],
        'total_paise': row['totalPaise'],
        'paid_paise': row['paidPaise'],
        'due_paise': row['duePaise'],
        'payment_mode':
            _latestPaymentMode(_asList(row['payments'] ?? const [])),
        'status': _title(row['status'] as String? ?? 'issued'),
        'date_time': row['createdAt'],
        'items_json': jsonEncode(items),
        'patient_id': row['patientId'],
        'visit_id': row['visitId'] ?? 0,
        'admission_id': row['admissionId'] ?? 0,
        'discount_paise': row['discountPaise'],
        'discount_reason': row['discountReason'],
        'notes': row['notes'],
        'created_at': row['createdAt'],
        'updated_at': row['updatedAt'],
      });
    }).toList();
  }

  Future<Map<String, dynamic>> dashboardStats({String? date}) async {
    final value = await _api.get('/api/reports/dashboard/stats', query: {
      if (date != null) 'date': date,
    });
    final row = _asObject(value);
    final data = _asObject(row['data'] ?? row);
    final bedOcc = _asObject(data['bedOccupancy'] ?? const {});
    return {
      'todayOpdPatients': data['todayOpdPatients'] ?? 0,
      'todayRevenue': (data['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      'todayRevenuePaise': data['todayRevenuePaise'] ?? 0,
      'bedOccupancy': {
        'totalBeds': bedOcc['totalBeds'] ?? 0,
        'occupiedBeds': bedOcc['occupiedBeds'] ?? 0,
        'availableBeds': bedOcc['availableBeds'] ?? 0,
        'occupancyPercentage':
            (bedOcc['occupancyPercentage'] as num?)?.toDouble() ?? 0.0,
      },
      'pendingLabTests': data['pendingLabTests'] ?? 0,
      'todayOpdVisits': data['todayOpdVisits'] ?? 0,
      'todayAppointments': data['todayAppointments'] ?? 0,
      'currentAdmissions': data['currentAdmissions'] ?? 0,
      'lowStockMedicines': data['lowStockMedicines'] ?? 0,
    };
  }

  Future<Map<String, dynamic>> reportSummary({String? from, String? to}) async {
    final value = await _api.get('/api/reports/summary', query: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
    final row = _asObject(value);
    return {
      'revenuePaise': row['revenuePaise'] ?? 0,
      'currentOutstandingPaise': row['currentOutstandingPaise'] ?? 0,
      'lowStockMedicines': row['lowStockMedicineCount'] ?? 0,
      'pendingLabOrders': row['pendingLabOrderCount'] ?? 0,
      'activeStaff': row['activeStaffCount'] ?? 0,
    };
  }

  Future<List<MedicineModel>> lowStockMedicines() async =>
      (await medicines()).where((medicine) => medicine.isLowStock).toList();

  Future<List<MedicineBatchModel>> nearExpiryBatches() async {
    return (await batches()).where((batch) => batch.isNearExpiry).toList();
  }

  Future<List<StockAdjustmentModel>> stockAdjustments() async {
    final rows = _asList(await _api.get('/api/pharmacy/stock/adjustments'));
    return rows
        .map((row) => StockAdjustmentModel.fromMap({
              'id': row['id'],
              'medicine_id': row['medicineId'],
              'medicine_name': row['medicineName'],
              'batch_no': row['batchNo'],
              'adjustment_qty': row['adjustmentQuantity'],
              'reason': row['reason'],
              'adjusted_by': row['adjustedBy'],
              'adjusted_at': row['createdAt'],
            }))
        .toList();
  }

  Future<List<DailyRevenueReportModel>> dailyRevenue(
      String from, String to) async {
    final value =
        await _api.get('/api/reports/revenue', query: {'from': from, 'to': to});
    return _asList(value)
        .map((row) => DailyRevenueReportModel.fromMap({
              'date': row['date'],
              'total_revenue_paise':
                  math.max(0, row['revenuePaise'] as int? ?? 0),
            }))
        .toList();
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List &&
        value.every((row) => row is Map<String, dynamic>)) {
      return value.cast<Map<String, dynamic>>();
    }
    throw const BackendApiException(
        'Backend returned an invalid list response.');
  }

  static Map<String, dynamic> _asObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const BackendApiException('Backend returned an invalid response.');
  }

  static String _title(String value) => value
      .split('_')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static String _labStatus(String value) => switch (value) {
        'pending' => 'Pending Collection',
        'collected' => 'Collected',
        'processing' => 'Processing',
        'resulted' || 'verified' || 'delivered' => 'Completed',
        _ => _title(value),
      };

  static String _latestPaymentMode(List<Map<String, dynamic>> payments) =>
      payments.isEmpty
          ? 'Cash'
          : _title(payments.last['paymentMode'] as String? ?? 'cash');
}
