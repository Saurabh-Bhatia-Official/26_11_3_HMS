package com.caresync.backend.staff.dto;

import java.time.Instant;

/** Public staff profile representation; it contains no authentication secrets or tenant authority. */
public record StaffResponse(
        Long id,
        String uuid,
        String name,
        String role,
        String regNo,
        String department,
        String phone,
        String email,
        Integer consultationFeePaise,
        String status,
        String qualification,
        Instant createdAt,
        Instant updatedAt) {
}
