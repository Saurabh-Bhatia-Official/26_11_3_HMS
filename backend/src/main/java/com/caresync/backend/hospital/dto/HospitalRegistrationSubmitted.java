package com.caresync.backend.hospital.dto;

import java.time.Instant;
import java.util.UUID;

public record HospitalRegistrationSubmitted(UUID registrationId, String status, Instant submittedAt) {}
