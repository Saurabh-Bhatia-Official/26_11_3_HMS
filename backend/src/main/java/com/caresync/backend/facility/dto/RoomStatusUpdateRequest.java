
package com.caresync.backend.facility.dto;

import jakarta.validation.constraints.NotNull;

public record RoomStatusUpdateRequest(

        @NotNull(message = "Active status is required")
        Boolean active

) {
}
