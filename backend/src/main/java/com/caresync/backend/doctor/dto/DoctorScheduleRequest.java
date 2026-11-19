package com.caresync.backend.doctor.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.time.LocalDate;
import java.time.LocalTime;

public record DoctorScheduleRequest(
        @Min(1) @Max(7) int dayOfWeek,
        @NotNull LocalTime startTime,
        @NotNull LocalTime endTime,
        @Positive int slotMinutes,
        @NotNull LocalDate effectiveFrom,
        LocalDate effectiveUntil,
        boolean active) {}
