
package com.caresync.backend.facility.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record RoomRequest(

        @NotNull(message = "Ward ID is required")
        @Positive(message = "Ward ID must be positive")
        Long wardId,

        @NotBlank(message = "Room number is required")
        @Size(max = 30, message = "Room number cannot exceed 30 characters")
        String roomNumber,

        @NotBlank(message = "Room type is required")
        @Size(max = 50, message = "Room type cannot exceed 50 characters")
        String roomType,

        @Size(max = 50, message = "Floor cannot exceed 50 characters")
        String floor,

        @Size(max = 500, message = "Description cannot exceed 500 characters")
        String description

) {
}

