import 'dart:convert';

/// Pharmacy Medicine master item model.
class MedicineModel {
  final int id;
  final String name;
  final String genericName;
  final String category;
  final int stockQty;
  final int reorderLevel;
  final String unit;
  final String supplier;
  final String uuid;
  final String form;
  final String strength;
  final String manufacturer;
  final double taxRatePct;
  final String hsnCode;
  final String rackLocation;
  final int mrpPaise;
  final String createdAt;
  final String updatedAt;

  const MedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.category,
    required this.stockQty,
    required this.reorderLevel,
    required this.unit,
    required this.supplier,
    this.uuid = '',
    this.form = 'Tablet',
    this.strength = '',
    this.manufacturer = '',
    this.taxRatePct = 0.0,
    this.hsnCode = '',
    this.rackLocation = '',
    this.mrpPaise = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get mrpFormatted => mrpPaise > 0 ? '₹${(mrpPaise / 100).toStringAsFixed(2)}' : '-';
  bool get isLowStock => stockQty <= reorderLevel;
  bool get isOutOfStock => stockQty <= 0;

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      genericName: map['generic_name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      stockQty: map['stock_qty'] as int? ?? 0,
      reorderLevel: map['reorder_level'] as int? ?? 10,
      unit: map['unit'] as String? ?? 'Tablet',
      supplier: map['supplier'] as String? ?? '',
      uuid: map['uuid'] as String? ?? '',
      form: map['form'] as String? ?? 'Tablet',
      strength: map['strength'] as String? ?? '',
      manufacturer: map['manufacturer'] as String? ?? '',
      taxRatePct: (map['tax_rate_pct'] as num?)?.toDouble() ?? 0.0,
      hsnCode: map['hsn_code'] as String? ?? '',
      rackLocation: map['rack_location'] as String? ?? '',
      mrpPaise: (map['mrp_paise'] ?? map['mrp'] ?? 0) as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'name': name,
        'generic_name': genericName,
        'category': category,
        'stock_qty': stockQty,
        'reorder_level': reorderLevel,
        'unit': unit,
        'supplier': supplier,
        'uuid': uuid,
        'form': form,
        'strength': strength,
        'manufacturer': manufacturer,
        'tax_rate_pct': taxRatePct,
        'hsn_code': hsnCode,
        'rack_location': rackLocation,
        'mrp_paise': mrpPaise,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory MedicineModel.fromJson(String source) =>
      MedicineModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  MedicineModel copyWith({
    int? id,
    String? name,
    String? genericName,
    String? category,
    int? stockQty,
    int? reorderLevel,
    String? unit,
    String? supplier,
    String? uuid,
    String? form,
    String? strength,
    String? manufacturer,
    double? taxRatePct,
    String? hsnCode,
    String? rackLocation,
    int? mrpPaise,
    String? createdAt,
    String? updatedAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      category: category ?? this.category,
      stockQty: stockQty ?? this.stockQty,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unit: unit ?? this.unit,
      supplier: supplier ?? this.supplier,
      uuid: uuid ?? this.uuid,
      form: form ?? this.form,
      strength: strength ?? this.strength,
      manufacturer: manufacturer ?? this.manufacturer,
      taxRatePct: taxRatePct ?? this.taxRatePct,
      hsnCode: hsnCode ?? this.hsnCode,
      rackLocation: rackLocation ?? this.rackLocation,
      mrpPaise: mrpPaise ?? this.mrpPaise,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          strength == other.strength;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ strength.hashCode;

  @override
  String toString() =>
      'MedicineModel(name: $name $strength, stock: $stockQty $unit, lowStock: $isLowStock)';
}

/// Pharmacy Medicine Batch with expiry and pricing
class MedicineBatchModel {
  final int id;
  final int medicineId;
  final String medicineName;
  final String batchNo;
  final String expiryDate;
  final int stockQty;
  final int mrpPaise;
  final int costPaise;
  final String uuid;
  final String manufactureDate;
  final int supplierId;
  final String createdAt;
  final String updatedAt;

  const MedicineBatchModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.batchNo,
    required this.expiryDate,
    required this.stockQty,
    required this.mrpPaise,
    required this.costPaise,
    this.uuid = '',
    this.manufactureDate = '',
    this.supplierId = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  String get mrpFormatted => '₹${(mrpPaise / 100).toStringAsFixed(2)}';
  String get costFormatted => '₹${(costPaise / 100).toStringAsFixed(2)}';

  bool get isExpired {
    try {
      final exp = DateTime.parse(expiryDate);
      return DateTime.now().isAfter(exp);
    } catch (_) {
      return false;
    }
  }

  bool get isNearExpiry {
    try {
      final exp = DateTime.parse(expiryDate);
      final diff = exp.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 90;
    } catch (_) {
      return false;
    }
  }

  factory MedicineBatchModel.fromMap(Map<String, dynamic> map) {
    return MedicineBatchModel(
      id: map['id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int? ?? 0,
      medicineName: map['medicine_name'] as String? ?? '',
      batchNo: map['batch_no'] as String? ?? '',
      expiryDate: map['expiry_date'] as String? ?? '',
      stockQty: map['stock_qty'] as int? ?? 0,
      mrpPaise: map['mrp_paise'] as int? ?? 0,
      costPaise: (map['cost_paise'] ?? map['purchase_price_paise']) as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      manufactureDate: map['manufacture_date'] as String? ?? '',
      supplierId: map['supplier_id'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'batch_no': batchNo,
        'expiry_date': expiryDate,
        'stock_qty': stockQty,
        'mrp_paise': mrpPaise,
        'cost_paise': costPaise,
        'uuid': uuid,
        'manufacture_date': manufactureDate,
        'supplier_id': supplierId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory MedicineBatchModel.fromJson(String source) =>
      MedicineBatchModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  MedicineBatchModel copyWith({
    int? id,
    int? medicineId,
    String? medicineName,
    String? batchNo,
    String? expiryDate,
    int? stockQty,
    int? mrpPaise,
    int? costPaise,
    String? uuid,
    String? manufactureDate,
    int? supplierId,
    String? createdAt,
    String? updatedAt,
  }) {
    return MedicineBatchModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      batchNo: batchNo ?? this.batchNo,
      expiryDate: expiryDate ?? this.expiryDate,
      stockQty: stockQty ?? this.stockQty,
      mrpPaise: mrpPaise ?? this.mrpPaise,
      costPaise: costPaise ?? this.costPaise,
      uuid: uuid ?? this.uuid,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      supplierId: supplierId ?? this.supplierId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineBatchModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          batchNo == other.batchNo &&
          medicineId == other.medicineId;

  @override
  int get hashCode => id.hashCode ^ batchNo.hashCode ^ medicineId.hashCode;

  @override
  String toString() =>
      'MedicineBatchModel($medicineName, Batch: $batchNo, Exp: $expiryDate, Qty: $stockQty)';
}

/// Pharmacy Supplier / Vendor record model
class SupplierModel {
  final int id;
  final String uuid;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String gstNo;
  final String createdAt;
  final String updatedAt;

  const SupplierModel({
    required this.id,
    required this.uuid,
    required this.name,
    this.contactPerson = '',
    required this.phone,
    this.email = '',
    this.address = '',
    this.gstNo = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      contactPerson: map['contact_person'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      gstNo: map['gst_no'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'name': name,
        'contact_person': contactPerson,
        'phone': phone,
        'email': email,
        'address': address,
        'gst_no': gstNo,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory SupplierModel.fromJson(String source) =>
      SupplierModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  SupplierModel copyWith({
    int? id,
    String? uuid,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? gstNo,
    String? createdAt,
    String? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNo: gstNo ?? this.gstNo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

/// Purchase Order item line
class PurchaseItemModel {
  final int id;
  final int medicineId;
  final String medicineName;
  final String batchNo;
  final String expiryDate;
  final int qty;
  final int unitPricePaise;
  final int mrpPaise;
  final int totalPaise;

  const PurchaseItemModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.batchNo,
    required this.expiryDate,
    required this.qty,
    required this.unitPricePaise,
    required this.mrpPaise,
    required this.totalPaise,
  });

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      id: map['id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int? ?? 0,
      medicineName: map['medicine_name'] as String? ?? '',
      batchNo: map['batch_no'] as String? ?? '',
      expiryDate: map['expiry_date'] as String? ?? '',
      qty: map['qty'] as int? ?? 0,
      unitPricePaise: map['unit_price_paise'] as int? ?? 0,
      mrpPaise: map['mrp_paise'] as int? ?? 0,
      totalPaise: map['total_paise'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'batch_no': batchNo,
        'expiry_date': expiryDate,
        'qty': qty,
        'unit_price_paise': unitPricePaise,
        'mrp_paise': mrpPaise,
        'total_paise': totalPaise,
      };

  String toJson() => jsonEncode(toMap());

  factory PurchaseItemModel.fromJson(String source) =>
      PurchaseItemModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Pharmacy Purchase Order / Inward Consignment
class PurchaseOrderModel {
  final int id;
  final String uuid;
  final int supplierId;
  final String supplierName;
  final String invoiceNo;
  final String invoiceDate;
  final int totalAmountPaise;
  final String status;
  final List<PurchaseItemModel> items;

  const PurchaseOrderModel({
    required this.id,
    required this.uuid,
    required this.supplierId,
    required this.supplierName,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.totalAmountPaise,
    this.status = 'received',
    this.items = const [],
  });

  String get totalFormatted => '₹${(totalAmountPaise / 100).toStringAsFixed(2)}';

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map) {
    List<PurchaseItemModel> itemsList = [];
    final raw = map['items'];
    if (raw is List) {
      itemsList = raw.map((e) => PurchaseItemModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    return PurchaseOrderModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      supplierId: map['supplier_id'] as int? ?? 0,
      supplierName: map['supplier_name'] as String? ?? '',
      invoiceNo: map['invoice_no'] as String? ?? '',
      invoiceDate: map['invoice_date'] as String? ?? '',
      totalAmountPaise: map['total_amount_paise'] as int? ?? 0,
      status: map['status'] as String? ?? 'received',
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'invoice_no': invoiceNo,
        'invoice_date': invoiceDate,
        'total_amount_paise': totalAmountPaise,
        'status': status,
        'items': items.map((i) => i.toMap()).toList(),
      };

  String toJson() => jsonEncode(toMap());

  factory PurchaseOrderModel.fromJson(String source) =>
      PurchaseOrderModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Stock audit adjustment model
class StockAdjustmentModel {
  final int id;
  final int medicineId;
  final String medicineName;
  final String batchNo;
  final int adjustmentQty;
  final String reason;
  final String adjustedBy;
  final String adjustedAt;

  const StockAdjustmentModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.batchNo,
    required this.adjustmentQty,
    required this.reason,
    required this.adjustedBy,
    required this.adjustedAt,
  });

  factory StockAdjustmentModel.fromMap(Map<String, dynamic> map) {
    return StockAdjustmentModel(
      id: map['id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int? ?? 0,
      medicineName: map['medicine_name'] as String? ?? '',
      batchNo: map['batch_no'] as String? ?? '',
      adjustmentQty: map['adjustment_qty'] as int? ?? 0,
      reason: map['reason'] as String? ?? '',
      adjustedBy: map['adjusted_by'] as String? ?? '',
      adjustedAt: map['adjusted_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'batch_no': batchNo,
        'adjustment_qty': adjustmentQty,
        'reason': reason,
        'adjusted_by': adjustedBy,
        'adjusted_at': adjustedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory StockAdjustmentModel.fromJson(String source) =>
      StockAdjustmentModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Dispensation record line item
class DispensationItemModel {
  final String medicineName;
  final String batchNo;
  final int qty;
  final int unitPricePaise;
  final int totalPaise;

  const DispensationItemModel({
    required this.medicineName,
    required this.batchNo,
    required this.qty,
    required this.unitPricePaise,
    required this.totalPaise,
  });

  factory DispensationItemModel.fromMap(Map<String, dynamic> map) {
    return DispensationItemModel(
      medicineName: map['medicine_name'] as String? ?? '',
      batchNo: map['batch_no'] as String? ?? '',
      qty: map['qty'] as int? ?? 0,
      unitPricePaise: map['unit_price_paise'] as int? ?? 0,
      totalPaise: map['total_paise'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'medicine_name': medicineName,
        'batch_no': batchNo,
        'qty': qty,
        'unit_price_paise': unitPricePaise,
        'total_paise': totalPaise,
      };

  String toJson() => jsonEncode(toMap());

  factory DispensationItemModel.fromJson(String source) =>
      DispensationItemModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Pharmacy Dispensation transaction
class DispensationModel {
  final int id;
  final int prescriptionId;
  final String patientName;
  final String uhid;
  final String dispensedAt;
  final String dispensedBy;
  final int totalAmountPaise;
  final List<DispensationItemModel> items;

  const DispensationModel({
    required this.id,
    required this.prescriptionId,
    required this.patientName,
    required this.uhid,
    required this.dispensedAt,
    required this.dispensedBy,
    required this.totalAmountPaise,
    this.items = const [],
  });

  String get totalFormatted => '₹${(totalAmountPaise / 100).toStringAsFixed(2)}';

  factory DispensationModel.fromMap(Map<String, dynamic> map) {
    List<DispensationItemModel> itemsList = [];
    final raw = map['items'];
    if (raw is List) {
      itemsList = raw.map((e) => DispensationItemModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    return DispensationModel(
      id: map['id'] as int? ?? 0,
      prescriptionId: map['prescription_id'] as int? ?? 0,
      patientName: map['patient_name'] as String? ?? '',
      uhid: map['uhid'] as String? ?? '',
      dispensedAt: map['dispensed_at'] as String? ?? '',
      dispensedBy: map['dispensed_by'] as String? ?? '',
      totalAmountPaise: map['total_amount_paise'] as int? ?? 0,
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'prescription_id': prescriptionId,
        'patient_name': patientName,
        'uhid': uhid,
        'dispensed_at': dispensedAt,
        'dispensed_by': dispensedBy,
        'total_amount_paise': totalAmountPaise,
        'items': items.map((i) => i.toMap()).toList(),
      };

  String toJson() => jsonEncode(toMap());

  factory DispensationModel.fromJson(String source) =>
      DispensationModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

