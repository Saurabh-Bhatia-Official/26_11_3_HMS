package com.caresync.backend.reference;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public final class AppointmentDtos {
    private AppointmentDtos() {}

    public record AppointmentRequest(
            String uuid,
            @NotBlank String patientUuid,
            Long doctorId,
            @NotNull LocalDate appointmentDate,
            String timeSlot,
            Integer tokenNo,
            String visitType,
            String status,
            String notes
    ) {}

    public record AppointmentResponse(
            long id,
            String uuid,
            long patientId,
            String patientUuid,
            String patientName,
            String uhid,
            Long doctorId,
            String doctorName,
            LocalDate appointmentDate,
            String timeSlot,
            int tokenNo,
            String visitType,
            String status,
            String notes
    ) {}
}
