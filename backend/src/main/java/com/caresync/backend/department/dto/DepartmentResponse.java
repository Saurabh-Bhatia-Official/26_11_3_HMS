package com.caresync.backend.department.dto;

import com.caresync.backend.department.entity.Department;

import java.time.Instant;
import java.util.UUID;

public record DepartmentResponse(UUID id, UUID hospitalUuid, String name, String code,
                                 String description, boolean active, Instant createdAt,
                                 Instant updatedAt) {
    public static DepartmentResponse from(Department department) {
        return new DepartmentResponse(department.getId(), department.getHospital().getId(),
                department.getName(), department.getCode(), department.getDescription(),
                department.isActive(), department.getCreatedAt(), department.getUpdatedAt());
    }
}
