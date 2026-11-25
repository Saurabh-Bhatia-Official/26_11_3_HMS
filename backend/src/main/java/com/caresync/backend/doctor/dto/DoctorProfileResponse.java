package com.caresync.backend.doctor.dto;

import com.caresync.backend.doctor.entity.DoctorProfile;

import java.time.Instant;
import java.util.UUID;

public record DoctorProfileResponse(UUID id, UUID hospitalUuid, UUID membershipId, String displayName,
                                    UUID departmentId, String departmentName, String specialization,
                                    String qualification, String registrationReference,
                                    boolean registrationReferenceVerified, boolean active,
                                    Instant createdAt, Instant updatedAt, long version) {
    public static DoctorProfileResponse from(DoctorProfile doctor) {
        return new DoctorProfileResponse(doctor.getId(), doctor.getHospital().getId(),
                doctor.getMembership().getId(), doctor.getMembership().getAccount().getFullName(),
                doctor.getDepartment() == null ? null : doctor.getDepartment().getId(),
                doctor.getDepartment() == null ? null : doctor.getDepartment().getName(),
                doctor.getSpecialization(), doctor.getQualification(), doctor.getRegistrationReference(),
                false, doctor.isActive(), doctor.getCreatedAt(), doctor.getUpdatedAt(), doctor.getVersion());
    }
}
