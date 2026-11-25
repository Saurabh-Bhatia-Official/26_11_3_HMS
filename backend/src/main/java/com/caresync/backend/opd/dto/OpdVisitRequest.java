
package com.caresync.backend.opd.dto;

import java.time.LocalDate;
import java.util.UUID;

import jakarta.validation.constraints.Positive;

public record OpdVisitRequest(

        // Required for walk-in visits; derived from appointment otherwise
        @Positive
        Long patientId,

        // Required for walk-in visits; derived from appointment otherwise
        UUID doctorUuid,

        // Optional for walk-in visits; derived from appointment otherwise
        UUID departmentUuid,

        // Used for appointment-based check-in
        UUID appointmentUuid,

        // Defaults to hospital-local current date in the service
        LocalDate visitDate

) {}
