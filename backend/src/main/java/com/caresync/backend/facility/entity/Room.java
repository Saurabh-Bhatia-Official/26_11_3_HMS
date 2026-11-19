
package com.caresync.backend.facility.entity;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "rooms",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_room_ward_number",
            columnNames = {"ward_id", "room_number"}
        )
    },
    indexes = {
        @Index(name = "idx_room_hospital_id", columnList = "hospital_id"),
        @Index(name = "idx_room_ward_id", columnList = "ward_id")
    }
)
public class Room {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID uuid;

    @Column(name = "hospital_id", nullable = false)
    private Long hospitalId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ward_id", nullable = false)
    private Ward ward;

    @Column(name = "room_number", nullable = false, length = 30)
    private String roomNumber;

    @Column(name = "room_type", nullable = false, length = 50)
    private String roomType;

    @Column(length = 50)
    private String floor;

    @Column(length = 500)
    private String description;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Room() {
        // Required by JPA
    }

    public Room(
            Long hospitalId,
            Ward ward,
            String roomNumber,
            String roomType,
            String floor,
            String description
    ) {
        this.hospitalId = hospitalId;
        this.ward = ward;
        this.roomNumber = roomNumber;
        this.roomType = roomType;
        this.floor = floor;
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

    public Ward getWard() {
        return ward;
    }

    public String getRoomNumber() {
        return roomNumber;
    }

    public String getRoomType() {
        return roomType;
    }

    public String getFloor() {
        return floor;
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

    public void updateDetails(
            Ward ward,
            String roomNumber,
            String roomType,
            String floor,
            String description
    ) {
        this.ward = ward;
        this.roomNumber = roomNumber;
        this.roomType = roomType;
        this.floor = floor;
        this.description = description;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
