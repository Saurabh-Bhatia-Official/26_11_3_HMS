package com.caresync.backend.hospital;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalRegistration;
import com.caresync.backend.hospital.entity.HospitalStatus;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class HospitalRegistrationLifecycleTests {
    @Test
    void expiryClearsPendingCredentialAndReleasesUsernameReservation() {
        Instant submittedAt = Instant.parse("2026-01-01T00:00:00Z");
        Instant expiredAt = submittedAt.plusSeconds(7 * 24 * 60 * 60L);
        Hospital hospital = new Hospital(UUID.randomUUID(), "Sample Hospital", "SAMPLE", "Clinic",
                null, null, null, null, submittedAt);
        HospitalRegistration registration = new HospitalRegistration(UUID.randomUUID(), hospital,
                "pending-admin", "Hospital Admin", "bcrypt-hash-that-is-never-returned", submittedAt);

        registration.expire(expiredAt);

        assertEquals(HospitalStatus.REJECTED, registration.getStatus());
        assertEquals(HospitalStatus.REJECTED, hospital.getStatus());
        assertEquals(expiredAt, registration.getReviewedAt());
        assertNull(registration.getReviewedByAccountId());
        assertNull(registration.getAdminPasswordHash());
        assertThrows(IllegalStateException.class, () -> registration.expire(expiredAt.plusSeconds(1)));
    }
}
