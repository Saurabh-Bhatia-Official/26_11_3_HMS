package com.caresync.backend.appointment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.OffsetDateTime;
import java.util.UUID;

public record AppointmentCreateRequest(
        @NotNull UUID patientUuid,
        @NotNull UUID doctorUuid,
        UUID departmentUuid,
        @NotNull OffsetDateTime startsAt,
        @NotBlank @Size(max = 40) String appointmentType,
        @Size(max = 500) String reason,
        @Size(max = 2000) String notes) {
    public AppointmentCreateRequest {
        appointmentType = appointmentType == null ? null : appointmentType.trim();
        reason = normalize(reason);
        notes = normalize(notes);
    }

    private static String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
