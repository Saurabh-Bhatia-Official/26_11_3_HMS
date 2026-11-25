
package com.caresync.backend.facility.entity;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
    name = "beds",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_bed_room_number",
            columnNames = {"room_id", "bed_no"}
        )
    },
    indexes = {
        @Index(name = "idx_bed_hospital_id", columnList = "hospital_id"),
        @Index(name = "idx_bed_room_id", columnList = "room_id"),
        @Index(name = "idx_bed_status", columnList = "status")
    }
)
public class Bed {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID uuid;

    @Column(name = "hospital_id", nullable = false)
    private Long hospitalId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(name = "bed_no", nullable = false, length = 30)
    private String bedNo;

    @Column(name = "bed_type", nullable = false, length = 50)
    private String bedType;

    @Column(name = "daily_tariff_paise", nullable = false)
    private int dailyTariffPaise;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BedStatus status = BedStatus.AVAILABLE;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Bed() {
        // Required by JPA
    }

    public Bed(
            Long hospitalId,
            Room room,
            String bedNo,
            String bedType,
            int dailyTariffPaise,
            BedStatus status
    ) {
        this.hospitalId = hospitalId;
        this.room = room;
        this.bedNo = bedNo;
        this.bedType = bedType;
        this.dailyTariffPaise = dailyTariffPaise;
        this.status = status != null ? status : BedStatus.AVAILABLE;
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

    public Room getRoom() {
        return room;
    }

    public String getBedNo() {
        return bedNo;
    }

    public String getBedType() {
        return bedType;
    }

    public int getDailyTariffPaise() {
        return dailyTariffPaise;
    }

    public BedStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void updateDetails(
            Room room,
            String bedNo,
            String bedType,
            int dailyTariffPaise
    ) {
        this.room = room;
        this.bedNo = bedNo;
        this.bedType = bedType;
        this.dailyTariffPaise = dailyTariffPaise;
    }

    public void setStatus(BedStatus status) {
        this.status = status;
    }
}