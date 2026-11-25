package com.caresync.backend.doctor.dto;

import com.caresync.backend.doctor.entity.ScheduleExceptionType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

public record DoctorScheduleExceptionRequest(
        @NotNull LocalDate date,
        @NotNull ScheduleExceptionType type,
        LocalTime startTime,
        LocalTime endTime,
        @Size(max = 255) String reason,
        boolean active) {
    public DoctorScheduleExceptionRequest {
        reason = reason == null || reason.isBlank() ? null : reason.trim();
    }
}
