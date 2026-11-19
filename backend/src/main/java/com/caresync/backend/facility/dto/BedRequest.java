package com.caresync.backend.facility.dto;

import com.caresync.backend.facility.entity.BedStatus;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

public record BedRequest(

        @NotNull(message = "Room ID is required")
        @Positive(message = "Room ID must be positive")
        Long roomId,

        @NotBlank(message = "Bed number is required")
        @Size(max = 30, message = "Bed number cannot exceed 30 characters")
        String bedNo,

        @NotBlank(message = "Bed type is required")
        @Size(max = 50, message = "Bed type cannot exceed 50 characters")
        String bedType,

        @PositiveOrZero(message = "Tariff cannot be negative")
        int dailyTariffPaise,

        BedStatus status

) {}