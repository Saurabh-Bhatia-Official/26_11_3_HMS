package com.caresync.backend.hospital.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;

@Component
public class HospitalRegistrationCleanupJob {
    private final HospitalManagementService hospitals;
    private final Clock clock;

    public HospitalRegistrationCleanupJob(
            HospitalManagementService hospitals,
            @Value("${caresync.hospital.registration.cleanup-delay:PT1H}") Duration cleanupDelay) {
        this.hospitals = hospitals;
        this.clock = Clock.systemUTC();
        if (cleanupDelay.isZero() || cleanupDelay.isNegative()) {
            throw new IllegalArgumentException("Registration cleanup delay must be positive");
        }
        this.cleanupDelay = cleanupDelay;
    }

    private final Duration cleanupDelay;

    @Scheduled(fixedDelayString = "${caresync.hospital.registration.cleanup-delay:PT1H}")
    public void expirePendingRegistrations() {
        hospitals.expirePendingRegistrations(clock.instant());
    }
}
