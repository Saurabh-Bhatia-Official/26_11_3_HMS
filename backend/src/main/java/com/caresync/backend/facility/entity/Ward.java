
package com.caresync.backend.facility.entity;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "wards",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_ward_hospital_code",
            columnNames = {"hospital_id", "ward_code"}
        ),
        @UniqueConstraint(
            name = "uk_ward_hospital_name",
            columnNames = {"hospital_id", "name"}
        )
    },  
    indexes = {
        @Index(name = "idx_ward_hospital_id", columnList = "hospital_id")
    }
)
public class Ward {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID uuid;

    @Column(name = "hospital_id", nullable = false)
    private Long hospitalId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "ward_code", nullable = false, length = 30)
    private String wardCode;

    @Column(length = 500)
    private String description;

    @Column(name = "is_active", nullable = false)
private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Ward() {
        // Required by JPA
    }

    public Ward(Long hospitalId, String name, String wardCode, String description) {
        this.hospitalId = hospitalId;
        this.name = name;
        this.wardCode = wardCode;
        this.description = description;
    }

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        if (uuid == null) {
            uuid = UUID.randomUUID();
        }
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public UUID getUuid() {
        return uuid;
    }

    public Long getHospitalId() {
        return hospitalId;
    }

    public String getName() {
        return name;
    }

    public String getWardCode() {
        return wardCode;
    }

    public String getDescription() {
        return description;
    }

    public boolean isActive() {
        return active;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void updateDetails(String name, String wardCode, String description) {
        this.name = name;
        this.wardCode = wardCode;
        this.description = description;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
