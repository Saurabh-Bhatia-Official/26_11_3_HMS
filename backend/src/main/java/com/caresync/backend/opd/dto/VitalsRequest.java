package com.caresync.backend.opd.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record VitalsRequest(
        @Min(50) @Max(300) Integer bpSystolic,
        @Min(30) @Max(200) Integer bpDiastolic,
        @Min(20) @Max(250) Integer pulse,
        @DecimalMin("25.0") @DecimalMax("45.0") BigDecimal temperatureC,
        @Min(0) @Max(100) Integer spo2,
        @DecimalMin("0.5") @DecimalMax("500.0") BigDecimal weightKg,
        @DecimalMin("30.0") @DecimalMax("250.0") BigDecimal heightCm,
        @Size(max = 2000) String notes
) {
    public boolean isEmpty() {
        return bpSystolic == null && bpDiastolic == null && pulse == null
                && temperatureC == null && spo2 == null && weightKg == null
                && heightCm == null && (notes == null || notes.isBlank());
    }
}
