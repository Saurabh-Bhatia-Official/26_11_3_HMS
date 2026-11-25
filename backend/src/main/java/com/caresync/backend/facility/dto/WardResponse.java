package com.caresync.backend.facility.dto;

import java.time.Instant;
import java.util.UUID;

public record WardResponse(
        Long id,
        UUID uuid,
        String name,
        String wardCode,
        String description,
        boolean active,
        Instant createdAt,
        Instant updatedAt
) {
}