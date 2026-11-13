// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patients_dao.dart';

// ignore_for_file: type=lint
mixin _$PatientsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PatientsTable get patients => attachedDatabase.patients;
  $PatientAllergiesTable get patientAllergies =>
      attachedDatabase.patientAllergies;
  PatientsDaoManager get managers => PatientsDaoManager(this);
}

class PatientsDaoManager {
  final _$PatientsDaoMixin _db;
  PatientsDaoManager(this._db);
  $$PatientsTableTableManager get patients =>
      $$PatientsTableTableManager(_db.attachedDatabase, _db.patients);
  $$PatientAllergiesTableTableManager get patientAllergies =>
      $$PatientAllergiesTableTableManager(
          _db.attachedDatabase, _db.patientAllergies);
}
