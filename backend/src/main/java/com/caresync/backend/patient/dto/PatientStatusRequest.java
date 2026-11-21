package com.caresync.backend.patient.dto;

import com.caresync.backend.patient.entity.PatientStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

public record PatientStatusRequest(@NotNull PatientStatus status, @PositiveOrZero long version) {}
