package com.caresync.backend.doctor.dto;

import java.time.LocalTime;
import java.time.OffsetDateTime;

public record DoctorAvailabilitySlotResponse(LocalTime localStartTime, LocalTime localEndTime,
                                             OffsetDateTime startsAt, OffsetDateTime endsAt,
                                             int slotMinutes) {}
