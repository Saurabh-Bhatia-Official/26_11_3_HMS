package com.caresync.backend.facility.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record WardRequest(

        @NotBlank(message = "Ward name is required")
        @Size(max = 100, message = "Ward name cannot exceed 100 characters")
        String name,

        @NotBlank(message = "Ward code is required")
        @Size(max = 30, message = "Ward code cannot exceed 30 characters")
        String wardCode,

        @Size(max = 500, message = "Description cannot exceed 500 characters")
        String description

) {
}