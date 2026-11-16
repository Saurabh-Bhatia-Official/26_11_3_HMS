package com.caresync.backend.hospital.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;

/** Database-backed, concurrency-safe source for public Hospital IDs. */
@Entity
@Table(name = "hospital_id_allocations")
public class HospitalIdAllocation {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "hospital_public_id_sequence")
    @SequenceGenerator(name = "hospital_public_id_sequence", sequenceName = "hospital_public_id_sequence",
            initialValue = 1, allocationSize = 1)
    @Column(name = "allocation_number", nullable = false, updatable = false)
    private Long hospitalId;

    protected HospitalIdAllocation() {}

    public static HospitalIdAllocation allocate() {
        return new HospitalIdAllocation();
    }

    public Long getHospitalId() { return hospitalId; }
}
