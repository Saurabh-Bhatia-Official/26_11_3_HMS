package com.caresync.backend.appointment.dto;

import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;

public record AppointmentRescheduleRequest(@NotNull OffsetDateTime startsAt) {}
