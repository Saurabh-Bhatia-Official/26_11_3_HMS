package com.caresync.backend.appointment.dto;

import com.caresync.backend.appointment.entity.AppointmentStatus;
import jakarta.validation.constraints.NotNull;

public record AppointmentStatusRequest(@NotNull AppointmentStatus status) {}
