package com.caresync.backend.staff.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalDate;

public final class StaffDtos {
    private StaffDtos() {}

    public record DepartmentRequest(
            @NotBlank @Size(max = 100) String name,
            @Size(max = 500) String description,
            Boolean active) {}

    public record DepartmentResponse(
            long id, String uuid, String name, String description, boolean active,
            Instant createdAt, Instant updatedAt) {}

    public record StaffRequest(
            @NotBlank @Size(max = 160) String name,
            @NotBlank @Pattern(regexp = "M|F|Other") String gender,
            LocalDate dob,
            @NotBlank @Pattern(regexp = "[0-9]{10}") String phone,
            @Email @Size(max = 254) String email,
            @Size(max = 500) String address,
            @NotBlank @Pattern(regexp = "doctor|nurse|lab|pharmacy|reception|admin|accounts|staff")
            String role,
            Long departmentId,
            @Size(max = 160) String qualification,
            @Size(max = 64) String regNo,
            @Size(max = 500) String photoPath,
            @Size(max = 160) String specialisation,
            @Min(0) long consultationFeePaise,
            @Min(0) long followupFeePaise,
            @Min(0) @Max(365) Integer followupDays,
            @Min(1) @Max(500) Integer maxSlotsPerDay,
            Boolean active) {}

    public record StaffResponse(
            long id, String uuid, String name, String gender, LocalDate dob, String phone, String email,
            String address, String role, Long departmentId, String department, String qualification,
            String regNo, String photoPath, String specialisation, long consultationFeePaise,
            long followupFeePaise, int followupDays, int maxSlotsPerDay, boolean active,
            Instant createdAt, Instant updatedAt) {}
}
