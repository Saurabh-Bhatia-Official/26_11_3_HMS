package com.caresync.backend.department.entity;

import com.caresync.backend.hospital.entity.Hospital;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "departments",
        uniqueConstraints = @UniqueConstraint(name = "uk_department_id_hospital",
                columnNames = {"department_uuid", "hospital_uuid"}),
        indexes = @Index(name = "ix_department_hospital_active_name",
                columnList = "hospital_uuid, active, name"))
public class Department {
    @Id
    @Column(name = "department_uuid", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", nullable = false, updatable = false)
    private Hospital hospital;

    @Column(name = "code", nullable = false, length = 32)
    private String code;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Department() {}

    public Department(UUID id, Hospital hospital, String code, String name, String description, Instant now) {
        this.id = id;
        this.hospital = hospital;
        this.code = code;
        this.name = name;
        this.description = description;
        this.active = true;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void update(String code, String name, String description, Instant now) {
        this.code = code;
        this.name = name;
        this.description = description;
        this.updatedAt = now;
    }

    public void setActive(boolean active, Instant now) {
        this.active = active;
        this.updatedAt = now;
    }

    public UUID getId() { return id; }
    public Hospital getHospital() { return hospital; }
    public String getCode() { return code; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public boolean isActive() { return active; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
