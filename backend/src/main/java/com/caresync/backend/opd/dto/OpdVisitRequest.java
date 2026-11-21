package com.caresync.backend.opd.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record OpdVisitRequest(

        @NotNull @Positive
        Long patientId,

        @NotNull @Positive
        Long doctorId,

        @NotNull @Positive
        Long departmentId,

        @Positive
        Long appointmentId,

        LocalDate visitDate
) {}
