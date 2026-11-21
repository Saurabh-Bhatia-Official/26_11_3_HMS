package com.caresync.backend.opd.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.caresync.backend.opd.entity.OpdVisitStatus;

public record OpdVisitResponse(
        Long id,
        UUID uuid,
        Long patientId,
        Long doctorId,
        Long departmentId,
        Long appointmentId,
        String visitType,
        Integer tokenNo,
        LocalDate visitDate,
        OpdVisitStatus status,
        Instant createdAt,
        Instant updatedAt
) {}
