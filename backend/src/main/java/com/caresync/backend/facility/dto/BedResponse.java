package com.caresync.backend.facility.dto;

import java.time.Instant;
import java.util.UUID;

import com.caresync.backend.facility.entity.BedStatus;

public record BedResponse(
        Long id,
        UUID uuid,
        Long roomId,
        String roomNumber,
        Long wardId,
        String wardName,
        String bedNo,
        String bedType,
        int dailyTariffPaise,
        BedStatus status,
        Instant createdAt,
        Instant updatedAt
) {}