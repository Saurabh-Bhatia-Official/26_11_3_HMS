package com.caresync.backend.hospital.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record HospitalTimeZoneRequest(@NotBlank @Size(max = 64) String timeZone) {
    public HospitalTimeZoneRequest {
        timeZone = timeZone == null ? null : timeZone.trim();
    }
}
