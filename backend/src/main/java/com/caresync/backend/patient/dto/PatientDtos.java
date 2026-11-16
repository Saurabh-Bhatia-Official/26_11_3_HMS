package com.caresync.backend.patient.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class PatientDtos {
    private PatientDtos() {}

    public record CreateRequest(
            @NotBlank @Pattern(regexp = "^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$") String uuid,
            @NotBlank @Size(max = 30) String uhid,
            @NotBlank @Size(max = 200) String name) {}

    public record Response(long id, String uuid, String uhid, String name) {}
}
