package com.caresync.backend.department.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record DepartmentUpdateRequest(
        @NotBlank @Size(max = 120) String name,
        @NotBlank @Pattern(regexp = "[A-Za-z0-9][A-Za-z0-9._-]{1,31}") String code,
        @Size(max = 500) String description) {
    public DepartmentUpdateRequest {
        name = name == null ? null : name.trim();
        code = code == null ? null : code.trim();
        description = description == null || description.isBlank() ? null : description.trim();
    }
}
