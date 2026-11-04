import 'package:hospital_management/domain/entities/patient.dart';
import 'package:hospital_management/domain/entities/patient_allergy.dart';

/// Abstract repository contract for patient data operations.
/// Implementations live in `lib/data/repositories/`.
abstract class PatientRepository {
  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Persists a new [patient] and returns the created record with assigned [id]
  /// and generated [uhid].
  Future<Patient> create(Patient patient);

  /// Updates an existing patient's data and returns the updated record.
  Future<Patient> update(Patient patient);

  /// Soft-deletes the patient with [id] (sets is_deleted = 1).
  Future<void> softDelete(int id);

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns the patient with the given [id], or null if not found / deleted.
  Future<Patient?> findById(int id);

  /// Returns the patient with the given [uhid], or null.
  Future<Patient?> findByUhid(String uhid);

  /// Returns patients whose name, phone, or UHID contains [query].
  /// Returns all active patients when [query] is empty.
  Future<List<Patient>> search(
    String query, {
    int limit = 20,
    int offset = 0,
  });

  /// Returns all active (non-deleted) patients with pagination.
  Future<List<Patient>> getAll({
    int limit = 50,
    int offset = 0,
  });

  /// Generates the next available UHID string, e.g. "UHID-000042".
  /// Reads the `uhid_prefix` and `uhid_sequence` settings rows.
  Future<String> generateUhid();

  // ── Allergies ─────────────────────────────────────────────────────────────

  /// Returns all allergies for the patient with [patientId].
  Future<List<PatientAllergy>> getAllergies(int patientId);

  /// Persists a new [allergy] record.
  Future<void> addAllergy(PatientAllergy allergy);

  /// Permanently deletes the allergy with [allergyId].
  Future<void> deleteAllergy(int allergyId);
}
