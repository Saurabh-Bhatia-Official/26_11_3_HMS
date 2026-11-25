package com.caresync.backend.department.dto;

import jakarta.validation.constraints.NotNull;

public record DepartmentStatusRequest(@NotNull Boolean active) {}
