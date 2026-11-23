package com.caresync.backend.common;

import jakarta.persistence.Column;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;

import java.time.Instant;
import java.util.UUID;

@MappedSuperclass
public abstract class HospitalScopedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 36, updatable = false)
    private String uuid;

    @Column(name = "hospital_id", nullable = false, updatable = false)
    private Long hospitalId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;

    protected HospitalScopedEntity() {}

    protected HospitalScopedEntity(Long hospitalId) {
        this.hospitalId = hospitalId;
    }

    protected HospitalScopedEntity(Long hospitalId, String uuid) {
        this.hospitalId = hospitalId;
        this.uuid = uuid;
    }

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        if (uuid == null) uuid = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public String getUuid() { return uuid; }
    public Long getHospitalId() { return hospitalId; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public boolean isDeleted() { return deleted; }
    public void markDeleted() { deleted = true; }
}
