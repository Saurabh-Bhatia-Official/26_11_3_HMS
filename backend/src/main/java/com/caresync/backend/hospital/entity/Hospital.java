package com.caresync.backend.hospital.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.Check;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "hospitals",
        uniqueConstraints = @UniqueConstraint(name = "uk_hospital_public_id", columnNames = "hospital_id"),
        indexes = @Index(name = "ix_hospital_status_name", columnList = "status, name"))
@Check(name = "ck_hospital_public_id_12_digits", constraints = "hospital_id IS NULL OR hospital_id BETWEEN 100000000000 AND 999999999999")
public class Hospital {
    @Id
    @Column(name = "hospital_uuid", nullable = false, updatable = false)
    private UUID id;

    /** Separate 12-digit identifier; remains null until central approval. */
    @Column(name = "hospital_id")
    private Long hospitalId;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(nullable = false, length = 255)
    private String code;

    @Column(nullable = false, length = 255)
    private String type;

    @Column(length = 255)
    private String address;

    @Column(length = 255)
    private String phone;

    @Column(length = 255)
    private String email;

    @Column(name = "tax_id", length = 255)
    private String taxId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private HospitalStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    /** IANA time zone configured by an authorized Hospital administrator; null means not configured. */
    @Column(name = "time_zone", length = 64)
    private String timeZone;

    protected Hospital() {}

    public Hospital(UUID id, String name, String code, String type, String address, String phone,
                    String email, String taxId, Instant createdAt) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.type = type;
        this.address = address;
        this.phone = phone;
        this.email = email;
        this.taxId = taxId;
        this.status = HospitalStatus.PENDING;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public Long getHospitalId() { return hospitalId; }
    public String getName() { return name; }
    public String getCode() { return code; }
    public String getType() { return type; }
    public String getAddress() { return address; }
    public String getPhone() { return phone; }
    public String getEmail() { return email; }
    public String getTaxId() { return taxId; }
    public HospitalStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public String getTimeZone() { return timeZone; }

    public void configureTimeZone(String timeZone) { this.timeZone = timeZone; }

    public void approve(long hospitalId) {
        if (status != HospitalStatus.PENDING) throw new IllegalStateException("Only pending hospitals can be approved");
        if (hospitalId < 100_000_000_000L || hospitalId > 999_999_999_999L) {
            throw new IllegalArgumentException("Hospital ID must contain exactly 12 digits");
        }
        this.hospitalId = hospitalId;
        this.status = HospitalStatus.APPROVED;
    }

    public void reject() {
        if (status != HospitalStatus.PENDING) throw new IllegalStateException("Only pending hospitals can be rejected");
        this.status = HospitalStatus.REJECTED;
    }

    public void suspend() {
        if (status != HospitalStatus.APPROVED) throw new IllegalStateException("Only approved hospitals can be suspended");
        this.status = HospitalStatus.SUSPENDED;
    }
}
