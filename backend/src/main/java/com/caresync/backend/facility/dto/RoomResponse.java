
package com.caresync.backend.facility.dto;

import java.time.Instant;
import java.util.UUID;

public record RoomResponse(
        Long id,
        UUID uuid,
        Long wardId,
        String roomNumber,
        String roomType,
        String floor,
        String description,
        boolean active,
        Instant createdAt,
        Instant updatedAt
) {
}
