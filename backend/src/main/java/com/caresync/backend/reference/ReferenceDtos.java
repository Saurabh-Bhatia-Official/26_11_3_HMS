package com.caresync.backend.reference;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Min;

import java.time.LocalDate;
import java.time.Instant;

public final class ReferenceDtos {
    private ReferenceDtos() {}

    private static final String UUID_PATTERN =
            "(?i)[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}";

    public record VisitRequest(
            @NotBlank @Pattern(regexp = UUID_PATTERN) String uuid,
            @NotBlank @Pattern(regexp = UUID_PATTERN) String patientUuid,
            @Min(1) Long doctorId,
            @NotBlank @Pattern(regexp = "opd|ipd|emergency|followup") String visitType,
            @NotNull LocalDate visitDate,
            @NotBlank @Pattern(regexp = "open|closed") String status) {}

    public record AdmissionRequest(
            @NotBlank @Pattern(regexp = UUID_PATTERN) String uuid,
            @NotBlank @Pattern(regexp = UUID_PATTERN) String patientUuid,
            @NotBlank @Pattern(regexp = UUID_PATTERN) String visitUuid,
            @NotNull LocalDate admitDate,
            @NotBlank @Size(max = 500) String reason,
            @NotBlank @Pattern(regexp = "admitted|discharged|transferred") String status) {}

    public record PrescriptionRequest(
            @NotBlank @Pattern(regexp = UUID_PATTERN) String uuid,
            @NotBlank @Pattern(regexp = UUID_PATTERN) String visitUuid,
            @Min(1) Long doctorId) {}

    public record VisitResponse(long id, String uuid, long patientId, Long doctorId, String visitType,
                                LocalDate visitDate, String status, Instant createdAt, Instant updatedAt) {}
    public record AdmissionResponse(long id, String uuid, long patientId, long visitId, String visitUuid,
                                    LocalDate admitDate, String reason, String status,
                                    Instant createdAt, Instant updatedAt) {}
    public record PrescriptionResponse(long id, String uuid, long patientId, long visitId, String visitUuid,
                                       Long doctorId, String status, Instant createdAt, Instant updatedAt) {}

    public record BedRequest(
            String uuid,
            @NotBlank String bedNumber,
            String ward,
            String bedType,
            @Min(0) Long tariffPaise,
            String status) {}

    public record BedAllocationRequest(
            Long patientId,
            String patientName,
            String uhid,
            Long admissionId) {}

    public record BedResponse(
            long id,
            String uuid,
            String bedNumber,
            String ward,
            String bedType,
            long tariffPaise,
            String status,
            Long patientId,
            String patientName,
            String uhid,
            Long admissionId,
            Instant createdAt,
            Instant updatedAt) {}
}
