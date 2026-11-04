// lib/data/database/tables/billing_tables.dart
// ignore_for_file: lines_longer_than_80_chars

import 'package:drift/drift.dart';

import 'patients_tables.dart';
import 'visits_tables.dart';

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------
class Services extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  IntColumn get pricePaise => integer().withDefault(const Constant(0))();
  RealColumn get taxRatePct =>
      real().withDefault(const Constant(0.0))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Invoices
// ---------------------------------------------------------------------------
/// invoice_type: opd | ipd | lab | pharmacy | counter
/// status: draft | issued | partial | paid | cancelled | refunded
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get invoiceNo => text().unique()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get visitId =>
      integer().nullable().references(Visits, #id)();
  /// FK → admissions.id (nullable plain int to avoid circular import)
  IntColumn get admissionId => integer().nullable()();
  TextColumn get invoiceType => text()();
  IntColumn get subtotalPaise => integer()();
  IntColumn get discountPaise =>
      integer().withDefault(const Constant(0))();
  TextColumn get discountReason => text().nullable()();
  IntColumn get discountApprovedBy => integer().nullable()();
  IntColumn get taxPaise =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalPaise => integer()();
  IntColumn get paidPaise =>
      integer().withDefault(const Constant(0))();
  IntColumn get duePaise => integer()();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get updatedBy => integer().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// InvoiceItems
// ---------------------------------------------------------------------------
/// item_type: service | lab | medicine | room | procedure
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  TextColumn get itemType => text()();
  /// FK to the relevant master table (nullable for free-text items)
  IntColumn get itemId => integer().nullable()();
  TextColumn get description => text()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  IntColumn get unitPricePaise => integer()();
  IntColumn get discountPaise =>
      integer().withDefault(const Constant(0))();
  RealColumn get taxRatePct =>
      real().withDefault(const Constant(0.0))();
  IntColumn get totalPaise => integer()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Payments
// ---------------------------------------------------------------------------
/// payment_mode: cash | card | upi | cheque | advance | insurance
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  TextColumn get paymentMode => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get referenceNo => text().nullable()();
  /// FK → users.id
  IntColumn get receivedBy => integer()();
  TextColumn get paidAt => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}

// ---------------------------------------------------------------------------
// Refunds
// ---------------------------------------------------------------------------
/// status: pending | approved | rejected
class Refunds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get paymentId => integer().references(Payments, #id)();
  IntColumn get amountPaise => integer()();
  TextColumn get reason => text()();
  /// FK → users.id
  IntColumn get approvedBy => integer()();
  TextColumn get refundedAt => text()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
}
