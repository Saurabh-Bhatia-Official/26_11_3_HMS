package com.caresync.backend.doctor.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record DoctorProfileCreateRequest(
        @NotNull UUID membershipId,
        UUID departmentId,
        @NotBlank @Size(max = 120) String specialization,
        @NotBlank @Size(max = 160) String qualification,
        @Size(max = 120) String registrationReference) {
    public DoctorProfileCreateRequest {
        specialization = specialization == null ? null : specialization.trim();
        qualification = qualification == null ? null : qualification.trim();
        registrationReference = blankToNull(registrationReference);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
