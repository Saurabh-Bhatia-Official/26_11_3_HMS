package com.caresync.backend.staff.service;

/** Validated staff profile input for the application service boundary. */
public record StaffCreateCommand(
        String uuid,
        String name,
        String role,
        String regNo,
        String department,
        String phone,
        String email,
        int consultationFeePaise,
        String status,
        String qualification) {
}
