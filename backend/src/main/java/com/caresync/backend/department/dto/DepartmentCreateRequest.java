package com.caresync.backend.department.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record DepartmentCreateRequest(
        @NotBlank @Size(max = 120) String name,
        @NotBlank @Pattern(regexp = "[A-Za-z0-9][A-Za-z0-9._-]{1,31}") String code,
        @Size(max = 500) String description) {
    public DepartmentCreateRequest {
        name = name == null ? null : name.trim();
        code = code == null ? null : code.trim();
        description = blankToNull(description);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
