package com.caresync.backend.opd.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "opd_vitals",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_opd_vitals_visit_hospital",
                columnNames = {"visit_id", "hospital_uuid"}))
public class Vitals {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID uuid;

    @Column(name = "visit_id", nullable = false, updatable = false)
    private Long visitId;

    @Column(name = "hospital_uuid", nullable = false, updatable = false)
    private UUID hospitalUuid;

    @Column(name = "bp_systolic")
    private Integer bpSystolic;

    @Column(name = "bp_diastolic")
    private Integer bpDiastolic;

    private Integer pulse;

    @Column(name = "temperature_c", precision = 4, scale = 1)
    private BigDecimal temperatureC;

    private Integer spo2;

    @Column(name = "weight_kg", precision = 6, scale = 2)
    private BigDecimal weightKg;

    @Column(name = "height_cm", precision = 6, scale = 2)
    private BigDecimal heightCm;

    @Column(precision = 5, scale = 2)
    private BigDecimal bmi;

    @Column(name = "recorded_by", nullable = false, updatable = false)
    private Long recordedBy;

    @Column(name = "recorded_at", nullable = false, updatable = false)
    private Instant recordedAt;

    @Column(length = 2000)
    private String notes;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Vitals() {}

    public Vitals(Long visitId, UUID hospitalUuid, Long recordedBy,
                  Integer bpSystolic, Integer bpDiastolic, Integer pulse,
                  BigDecimal temperatureC, Integer spo2, BigDecimal weightKg,
                  BigDecimal heightCm, String notes) {
        this.visitId = visitId;
        this.hospitalUuid = hospitalUuid;
        this.recordedBy = recordedBy;
        apply(bpSystolic, bpDiastolic, pulse, temperatureC, spo2, weightKg, heightCm, notes);
    }

    public void update(Integer bpSystolic, Integer bpDiastolic, Integer pulse,
                       BigDecimal temperatureC, Integer spo2, BigDecimal weightKg,
                       BigDecimal heightCm, String notes) {
        apply(bpSystolic, bpDiastolic, pulse, temperatureC, spo2, weightKg, heightCm, notes);
    }

    private void apply(Integer systolic, Integer diastolic, Integer pulse,
                       BigDecimal temperature, Integer oxygen, BigDecimal weight,
                       BigDecimal height, String notes) {
        this.bpSystolic = systolic;
        this.bpDiastolic = diastolic;
        this.pulse = pulse;
        this.temperatureC = temperature;
        this.spo2 = oxygen;
        this.weightKg = weight;
        this.heightCm = height;
        this.bmi = calculateBmi(weight, height);
        this.notes = notes == null || notes.isBlank() ? null : notes.trim();
    }

    private static BigDecimal calculateBmi(BigDecimal weight, BigDecimal height) {
        if (weight == null || height == null || height.signum() <= 0) return null;
        BigDecimal heightMetres = height.movePointLeft(2);
        return weight.divide(heightMetres.multiply(heightMetres), 2,
                java.math.RoundingMode.HALF_UP);
    }

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        if (uuid == null) uuid = UUID.randomUUID();
        if (recordedAt == null) recordedAt = now;
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() { updatedAt = Instant.now(); }

    public Long getId() { return id; }
    public UUID getUuid() { return uuid; }
    public Long getVisitId() { return visitId; }
    public UUID getHospitalUuid() { return hospitalUuid; }
    public Integer getBpSystolic() { return bpSystolic; }
    public Integer getBpDiastolic() { return bpDiastolic; }
    public Integer getPulse() { return pulse; }
    public BigDecimal getTemperatureC() { return temperatureC; }
    public Integer getSpo2() { return spo2; }
    public BigDecimal getWeightKg() { return weightKg; }
    public BigDecimal getHeightCm() { return heightCm; }
    public BigDecimal getBmi() { return bmi; }
    public Long getRecordedBy() { return recordedBy; }
    public Instant getRecordedAt() { return recordedAt; }
    public String getNotes() { return notes; }
    public boolean isDeleted() { return deleted; }
}
