package com.caresync.backend.doctor.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record DoctorProfileUpdateRequest(
        UUID departmentId,
        @NotBlank @Size(max = 120) String specialization,
        @NotBlank @Size(max = 160) String qualification,
        @Size(max = 120) String registrationReference) {
    public DoctorProfileUpdateRequest {
        specialization = specialization == null ? null : specialization.trim();
        qualification = qualification == null ? null : qualification.trim();
        registrationReference = registrationReference == null || registrationReference.isBlank()
                ? null : registrationReference.trim();
    }
}
