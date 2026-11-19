package com.caresync.backend.doctor.dto;

import jakarta.validation.constraints.NotNull;

public record DoctorProfileStatusRequest(@NotNull Boolean active) {}
