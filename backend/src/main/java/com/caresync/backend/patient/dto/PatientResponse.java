package com.caresync.backend.patient.dto;

import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.patient.entity.PatientStatus;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record PatientResponse(
        Long id,
        UUID uuid,
        String uhid,
        String name,
        String gender,
        LocalDate dateOfBirth,
        Integer ageYears,
        String phone,
        String alternatePhone,
        String email,
        String address,
        String city,
        String state,
        String pincode,
        String bloodGroup,
        String emergencyContactName,
        String emergencyContactPhone,
        PatientStatus status,
        boolean archived,
        Instant createdAt,
        Instant updatedAt,
        long version) {

    public static PatientResponse from(Patient p) {
        return new PatientResponse(p.getId(), p.getUuid(), p.getUhid(), p.getName(), p.getGender(),
                p.getDateOfBirth(), p.getAgeYears(), p.getPhone(), p.getAlternatePhone(), p.getEmail(),
                p.getAddress(), p.getCity(), p.getState(), p.getPincode(), p.getBloodGroup(),
                p.getEmergencyContactName(), p.getEmergencyContactPhone(), p.getStatus(),
                p.getArchivedAt() != null, p.getCreatedAt(), p.getUpdatedAt(), p.getVersion());
    }
}
