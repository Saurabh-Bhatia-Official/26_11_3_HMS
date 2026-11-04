// lib/data/database/tables/pharmacy_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Suppliers
// ---------------------------------------------------------------------------
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get contactPerson =>
      text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get gstNo => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Medicines
// ---------------------------------------------------------------------------
/// form: tablet | capsule | syrup | injection | cream | other
class Medicines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get genericName =>
      text().withDefault(const Constant(''))();
  TextColumn get form => text()();
  TextColumn get strength => text().withDefault(const Constant(''))();
  TextColumn get manufacturer =>
      text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant(''))();
  RealColumn get taxRatePct =>
      real().withDefault(const Constant(0.0))();
  IntColumn get reorderLevel =>
      integer().withDefault(const Constant(10))();
  TextColumn get hsnCode => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name, form, strength},
      ];
}

// ---------------------------------------------------------------------------
// MedicineBatches
// ---------------------------------------------------------------------------
class MedicineBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get medicineId => integer().references(Medicines, #id)();
  TextColumn get batchNo => text()();
  /// YYYY-MM-DD
  TextColumn get expiryDate => text()();
  TextColumn get manufactureDate => text().nullable()();
  IntColumn get qtyOnHand =>
      integer().withDefault(const Constant(0))();
  IntColumn get purchasePricePaise => integer()();
  IntColumn get mrpPaise => integer()();
  IntColumn get supplierId =>
      integer().nullable().references(Suppliers, #id)();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {medicineId, batchNo},
      ];
}

// ---------------------------------------------------------------------------
// Purchases
// ---------------------------------------------------------------------------
/// status: draft | received | partial
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get invoiceNo => text()();
  TextColumn get invoiceDate => text()();
  IntColumn get totalAmountPaise => integer()();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))();
  /// FK → users.id
  IntColumn get receivedBy => integer().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// PurchaseItems
// ---------------------------------------------------------------------------
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(Purchases, #id)();
  IntColumn get medicineId => integer().references(Medicines, #id)();
  TextColumn get batchNo => text()();
  TextColumn get expiryDate => text()();
  IntColumn get qty => integer()();
  IntColumn get unitPricePaise => integer()();
  IntColumn get mrpPaise => integer()();
  RealColumn get taxPct => real().withDefault(const Constant(0.0))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Dispensing
// ---------------------------------------------------------------------------
class Dispensing extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  /// FK → prescriptions.id (nullable for counter sales)
  IntColumn get prescriptionId => integer().nullable()();
  /// FK → visits.id
  IntColumn get visitId => integer().nullable()();
  /// FK → patients.id
  IntColumn get patientId => integer()();
  /// FK → users.id
  IntColumn get dispensedBy => integer()();
  TextColumn get dispensedAt => text()();
  IntColumn get totalAmountPaise => integer()();
  BoolColumn get isCounterSale =>
      boolean().withDefault(const Constant(false))();
  /// FK → invoices.id
  IntColumn get invoiceId => integer().nullable()();
  TextColumn get createdAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// DispensingItems
// ---------------------------------------------------------------------------
class DispensingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dispensingId => integer().references(Dispensing, #id)();
  IntColumn get medicineId => integer().references(Medicines, #id)();
  IntColumn get batchId => integer().references(MedicineBatches, #id)();
  IntColumn get qty => integer()();
  IntColumn get unitPricePaise => integer()();
  RealColumn get taxPct => real().withDefault(const Constant(0.0))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// StockAdjustments
// ---------------------------------------------------------------------------
class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get medicineId => integer().references(Medicines, #id)();
  IntColumn get batchId => integer().references(MedicineBatches, #id)();
  /// Positive = addition, negative = subtraction
  IntColumn get adjustmentQty => integer()();
  TextColumn get reason => text()();
  /// FK → users.id
  IntColumn get adjustedBy => integer()();
  TextColumn get adjustedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
