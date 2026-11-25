package com.caresync.backend.hospital.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record HospitalRegistrationRequest(
        @NotBlank @Size(max = 255) String name,
        @NotBlank @Size(max = 255) String code,
        @NotBlank @Size(max = 255) String type,
        @Size(max = 255) String address,
        @Size(max = 255) String phone,
        @Email @Size(max = 255) String email,
        @Size(max = 255) String taxId,
        @NotBlank @Pattern(regexp = "[A-Za-z0-9._-]{3,64}") String adminUsername,
        @NotBlank @Size(min = 12, max = 256) String adminPassword,
        @NotBlank @Size(max = 160) String adminFullName) {

    public HospitalRegistrationRequest {
        address = blankToNull(address);
        phone = blankToNull(phone);
        email = blankToNull(email);
        taxId = blankToNull(taxId);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    @Override
    public String toString() {
        return "HospitalRegistrationRequest[details=<redacted>, adminCredentials=<redacted>]";
    }
}
