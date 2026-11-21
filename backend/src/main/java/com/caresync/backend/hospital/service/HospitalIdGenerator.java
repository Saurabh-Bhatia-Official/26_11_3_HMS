package com.caresync.backend.hospital.service;

import org.springframework.stereotype.Component;

import com.caresync.backend.hospital.entity.HospitalIdAllocation;
import com.caresync.backend.hospital.repository.HospitalIdAllocationRepository;

@Component
public class HospitalIdGenerator {
    private static final long FIRST_PUBLIC_ID = 100_000_000_000L;
    private final HospitalIdAllocationRepository allocations;

    public HospitalIdGenerator(HospitalIdAllocationRepository allocations) {
        this.allocations = allocations;
    }

    public long nextCandidate() {
        HospitalIdAllocation reservation = allocations.saveAndFlush(HospitalIdAllocation.allocate());
        return FIRST_PUBLIC_ID + reservation.getHospitalId() - 1;
    }
}
