package com.caresync.backend.hospital.dto;

import java.time.Instant;
import java.util.UUID;

public record HospitalRegistrationReviewResponse(
        UUID registrationId,
        String status,
        String name,
        String code,
        String type,
        String address,
        String phone,
        String email,
        String taxId,
        String firstAdminUsername,
        String firstAdminFullName,
        Instant submittedAt) {}
