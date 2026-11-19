package com.caresync.backend.facility.dto;

import com.caresync.backend.facility.entity.BedStatus;

import jakarta.validation.constraints.NotNull;

public record BedStatusUpdateRequest(

        @NotNull(message = "Bed status is required")
        BedStatus status

) {}