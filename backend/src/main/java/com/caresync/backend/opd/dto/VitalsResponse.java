package com.caresync.backend.opd.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record VitalsResponse(
        Long id,
        UUID uuid,
        Long visitId,
        Integer bpSystolic,
        Integer bpDiastolic,
        Integer pulse,
        BigDecimal temperatureC,
        Integer spo2,
        BigDecimal weightKg,
        BigDecimal heightCm,
        BigDecimal bmi,
        Instant recordedAt,
        Long recordedBy,
        String notes
) {}
