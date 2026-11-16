package com.caresync.backend.staff.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;

/**
 * Input contract for creating a staff profile. Tenant identity and persistence
 * metadata are deliberately excluded and must be supplied by trusted backend code.
 */
public record StaffCreateRequest(
        @NotBlank
        @Pattern(regexp = "(?i)^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
        String uuid,
        @NotBlank String name,
        @NotBlank String role,
        String regNo,
        String department,
        @Pattern(regexp = "^\\+?(?=(?:\\D*\\d){7,15}\\D*$)[0-9 ()-]{7,24}$") String phone,
        @Email String email,
        Integer consultationFeePaise,
        String status,
        String qualification) {

    public StaffCreateRequest {
        phone = normalizeOptional(phone);
        email = normalizeOptional(email);
    }

    private static String normalizeOptional(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
