import 'dart:convert';

/// Billing Invoice record model for OPD, IPD, Pharmacy and Lab billing.
class InvoiceModel {
  final int id;
  final String invoiceNo;
  final String patientName;
  final String uhid;
  final String billType;
  final int subtotalPaise;
  final int taxPaise;
  final int totalPaise;
  final int paidPaise;
  final int duePaise;
  final String paymentMode;
  final String status;
  final String dateTime;
  final List<Map<String, dynamic>> items;
  final int patientId;
  final int visitId;
  final int admissionId;
  final int discountPaise;
  final String discountReason;
  final String notes;
  final String createdAt;
  final String updatedAt;

  const InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.patientName,
    required this.uhid,
    required this.billType,
    required this.subtotalPaise,
    required this.taxPaise,
    required this.totalPaise,
    required this.paidPaise,
    required this.duePaise,
    required this.paymentMode,
    required this.status,
    required this.dateTime,
    required this.items,
    this.patientId = 0,
    this.visitId = 0,
    this.admissionId = 0,
    this.discountPaise = 0,
    this.discountReason = '',
    this.notes = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get subtotalFormatted => '₹${(subtotalPaise / 100).toStringAsFixed(2)}';
  String get taxFormatted => '₹${(taxPaise / 100).toStringAsFixed(2)}';
  String get totalFormatted => '₹${(totalPaise / 100).toStringAsFixed(2)}';
  String get paidFormatted => '₹${(paidPaise / 100).toStringAsFixed(2)}';
  String get dueFormatted => '₹${(duePaise / 100).toStringAsFixed(2)}';
  String get discountFormatted => '₹${(discountPaise / 100).toStringAsFixed(2)}';

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPartial => status.toLowerCase() == 'partial';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parsedItems = [];
    final itemsJson = map['items_json'] as String?;
    if (itemsJson != null && itemsJson.isNotEmpty) {
      try {
        final list = jsonDecode(itemsJson) as List<dynamic>;
        parsedItems = list
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList();
      } catch (_) {}
    }

    return InvoiceModel(
      id: map['id'] as int? ?? 0,
      invoiceNo: map['invoice_no'] as String? ?? '',
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      billType: map['bill_type'] as String? ?? '',
      subtotalPaise: map['subtotal_paise'] as int? ?? 0,
      taxPaise: map['tax_paise'] as int? ?? 0,
      totalPaise: map['total_paise'] as int? ?? 0,
      paidPaise: map['paid_paise'] as int? ?? 0,
      duePaise: map['due_paise'] as int? ?? 0,
      paymentMode: map['payment_mode'] as String? ?? 'Cash',
      status: map['status'] as String? ?? 'Paid',
      dateTime: (map['date_time'] ?? map['created_at']) as String? ?? '',
      items: parsedItems,
      patientId: map['patient_id'] as int? ?? 0,
      visitId: map['visit_id'] as int? ?? 0,
      admissionId: map['admission_id'] as int? ?? 0,
      discountPaise: map['discount_paise'] as int? ?? 0,
      discountReason: map['discount_reason'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'invoice_no': invoiceNo,
        'patient_name': patientName,
        'uhid': uhid,
        'bill_type': billType,
        'subtotal_paise': subtotalPaise,
        'tax_paise': taxPaise,
        'total_paise': totalPaise,
        'paid_paise': paidPaise,
        'due_paise': duePaise,
        'payment_mode': paymentMode,
        'status': status,
        'date_time': dateTime,
        'items_json': jsonEncode(items),
        'patient_id': patientId,
        'visit_id': visitId,
        'admission_id': admissionId,
        'discount_paise': discountPaise,
        'discount_reason': discountReason,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory InvoiceModel.fromJson(String source) =>
      InvoiceModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  InvoiceModel copyWith({
    int? id,
    String? invoiceNo,
    String? patientName,
    String? uhid,
    String? billType,
    int? subtotalPaise,
    int? taxPaise,
    int? totalPaise,
    int? paidPaise,
    int? duePaise,
    String? paymentMode,
    String? status,
    String? dateTime,
    List<Map<String, dynamic>>? items,
    int? patientId,
    int? visitId,
    int? admissionId,
    int? discountPaise,
    String? discountReason,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      patientName: patientName ?? this.patientName,
      uhid: uhid ?? this.uhid,
      billType: billType ?? this.billType,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      taxPaise: taxPaise ?? this.taxPaise,
      totalPaise: totalPaise ?? this.totalPaise,
      paidPaise: paidPaise ?? this.paidPaise,
      duePaise: duePaise ?? this.duePaise,
      paymentMode: paymentMode ?? this.paymentMode,
      status: status ?? this.status,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      admissionId: admissionId ?? this.admissionId,
      discountPaise: discountPaise ?? this.discountPaise,
      discountReason: discountReason ?? this.discountReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          invoiceNo == other.invoiceNo;

  @override
  int get hashCode => id.hashCode ^ invoiceNo.hashCode;

  @override
  String toString() =>
      'InvoiceModel(inv: $invoiceNo, patient: $patientName, total: $totalFormatted [$status])';
}

/// Line item within an invoice
class InvoiceItemModel {
  final int id;
  final String uuid;
  final int invoiceId;
  final String itemType; // service | lab | medicine | room | procedure
  final int? itemId;
  final String description;
  final int qty;
  final int unitPricePaise;
  final int discountPaise;
  final double taxRatePct;
  final int totalPaise;

  const InvoiceItemModel({
    required this.id,
    required this.uuid,
    required this.invoiceId,
    required this.itemType,
    this.itemId,
    required this.description,
    this.qty = 1,
    required this.unitPricePaise,
    this.discountPaise = 0,
    this.taxRatePct = 0.0,
    required this.totalPaise,
  });

  String get totalFormatted => '₹${(totalPaise / 100).toStringAsFixed(2)}';
  String get unitPriceFormatted => '₹${(unitPricePaise / 100).toStringAsFixed(2)}';

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      invoiceId: map['invoice_id'] as int? ?? 0,
      itemType: map['item_type'] as String? ?? 'service',
      itemId: map['item_id'] as int?,
      description: (map['description'] ?? map['name']) as String? ?? '',
      qty: (map['qty'] ?? map['quantity']) as int? ?? 1,
      unitPricePaise: (map['unit_price_paise'] ?? map['rate_paise']) as int? ?? 0,
      discountPaise: map['discount_paise'] as int? ?? 0,
      taxRatePct: (map['tax_rate_pct'] as num?)?.toDouble() ?? 0.0,
      totalPaise: (map['total_paise'] ?? map['amount_paise']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'invoice_id': invoiceId,
        'item_type': itemType,
        'item_id': itemId,
        'description': description,
        'qty': qty,
        'unit_price_paise': unitPricePaise,
        'discount_paise': discountPaise,
        'tax_rate_pct': taxRatePct,
        'total_paise': totalPaise,
      };

  String toJson() => jsonEncode(toMap());

  factory InvoiceItemModel.fromJson(String source) =>
      InvoiceItemModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Payment receipt record model
class PaymentModel {
  final int id;
  final String uuid;
  final int invoiceId;
  final String paymentMode; // cash | card | upi | cheque | insurance
  final int amountPaise;
  final String? referenceNo;
  final String receivedBy;
  final String paidAt;

  const PaymentModel({
    required this.id,
    required this.uuid,
    required this.invoiceId,
    required this.paymentMode,
    required this.amountPaise,
    this.referenceNo,
    required this.receivedBy,
    required this.paidAt,
  });

  String get amountFormatted => '₹${(amountPaise / 100).toStringAsFixed(2)}';

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      invoiceId: map['invoice_id'] as int? ?? 0,
      paymentMode: map['payment_mode'] as String? ?? 'Cash',
      amountPaise: map['amount_paise'] as int? ?? 0,
      referenceNo: map['reference_no'] as String?,
      receivedBy: map['received_by'] as String? ?? '',
      paidAt: map['paid_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'invoice_id': invoiceId,
        'payment_mode': paymentMode,
        'amount_paise': amountPaise,
        'reference_no': referenceNo,
        'received_by': receivedBy,
        'paid_at': paidAt,
      };

  String toJson() => jsonEncode(toMap());

  factory PaymentModel.fromJson(String source) =>
      PaymentModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Billable Hospital Service catalogue item
class ServiceModel {
  final int id;
  final String uuid;
  final String name;
  final String category;
  final int pricePaise;
  final double taxRatePct;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const ServiceModel({
    required this.id,
    required this.uuid,
    required this.name,
    this.category = 'General',
    this.pricePaise = 0,
    this.taxRatePct = 0.0,
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get priceFormatted =>
      pricePaise > 0 ? '₹${(pricePaise / 100).toStringAsFixed(2)}' : 'Free';

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      pricePaise: map['price_paise'] as int? ?? 0,
      taxRatePct: (map['tax_rate_pct'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['is_active'] is int)
          ? (map['is_active'] as int) == 1
          : (map['is_active'] as bool? ?? true),
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'name': name,
        'category': category,
        'price_paise': pricePaise,
        'tax_rate_pct': taxRatePct,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory ServiceModel.fromJson(String source) =>
      ServiceModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

