package com.caresync.backend.appointment.dto;

import com.caresync.backend.appointment.entity.AppointmentEvent;
import com.caresync.backend.appointment.entity.AppointmentStatus;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.UUID;

public record AppointmentEventResponse(UUID eventUuid, String eventType, AppointmentStatus previousStatus,
                                       AppointmentStatus newStatus, OffsetDateTime previousStartsAt,
                                       OffsetDateTime previousEndsAt, OffsetDateTime newStartsAt,
                                       OffsetDateTime newEndsAt, Instant occurredAt) {
    public static AppointmentEventResponse from(AppointmentEvent event) {
        return new AppointmentEventResponse(event.getId(), event.getEventType(), event.getPreviousStatus(),
                event.getNewStatus(), event.getPreviousStartsAt(), event.getPreviousEndsAt(),
                event.getNewStartsAt(), event.getNewEndsAt(), event.getOccurredAt());
    }
}
