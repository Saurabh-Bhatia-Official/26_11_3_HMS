import 'package:equatable/equatable.dart';

/// Severity levels for patient allergies.
enum AllergySeverity {
  mild,
  moderate,
  severe;

  String get label {
    switch (this) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.severe:
        return 'Severe';
    }
  }

  static AllergySeverity fromString(String s) {
    switch (s.toLowerCase()) {
      case 'moderate':
        return AllergySeverity.moderate;
      case 'severe':
        return AllergySeverity.severe;
      default:
        return AllergySeverity.mild;
    }
  }
}

/// A single allergy record linked to a [Patient].
class PatientAllergy extends Equatable {
  const PatientAllergy({
    required this.id,
    required this.patientId,
    required this.allergen,
    this.reaction,
    required this.severity,
    required this.createdAt,
  });

  final int id;
  final int patientId;

  /// Name of the allergen, e.g. "Penicillin", "Peanuts".
  final String allergen;

  /// Observed reaction description.
  final String? reaction;

  /// Severity: mild / moderate / severe.
  final AllergySeverity severity;

  final DateTime createdAt;

  PatientAllergy copyWith({
    int? id,
    int? patientId,
    String? allergen,
    String? reaction,
    AllergySeverity? severity,
    DateTime? createdAt,
  }) {
    return PatientAllergy(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      allergen: allergen ?? this.allergen,
      reaction: reaction ?? this.reaction,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, patientId, allergen, reaction, severity, createdAt];
}
