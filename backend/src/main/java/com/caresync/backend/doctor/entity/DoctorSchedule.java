package com.caresync.backend.doctor.entity;

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
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "doctor_schedules",
        uniqueConstraints = @UniqueConstraint(name = "uk_doctor_schedule_id_hospital",
                columnNames = {"schedule_uuid", "hospital_uuid"}),
        indexes = @Index(name = "ix_doctor_schedule_lookup",
                columnList = "hospital_uuid, doctor_uuid, day_of_week, active, effective_from, effective_until"))
public class DoctorSchedule {
    @Id
    @Column(name = "schedule_uuid", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", nullable = false, updatable = false)
    private Hospital hospital;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "doctor_uuid", nullable = false, updatable = false)
    private DoctorProfile doctor;

    @Column(name = "day_of_week", nullable = false)
    private int dayOfWeek;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "slot_minutes", nullable = false)
    private int slotMinutes;

    @Column(name = "effective_from", nullable = false)
    private LocalDate effectiveFrom;

    @Column(name = "effective_until")
    private LocalDate effectiveUntil;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected DoctorSchedule() {}

    public DoctorSchedule(UUID id, Hospital hospital, DoctorProfile doctor, int dayOfWeek,
                          LocalTime startTime, LocalTime endTime, int slotMinutes,
                          LocalDate effectiveFrom, LocalDate effectiveUntil, Instant now) {
        this.id = id;
        this.hospital = hospital;
        this.doctor = doctor;
        this.dayOfWeek = dayOfWeek;
        this.startTime = startTime;
        this.endTime = endTime;
        this.slotMinutes = slotMinutes;
        this.effectiveFrom = effectiveFrom;
        this.effectiveUntil = effectiveUntil;
        this.active = true;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void update(int dayOfWeek, LocalTime startTime, LocalTime endTime, int slotMinutes,
                       LocalDate effectiveFrom, LocalDate effectiveUntil, boolean active, Instant now) {
        this.dayOfWeek = dayOfWeek;
        this.startTime = startTime;
        this.endTime = endTime;
        this.slotMinutes = slotMinutes;
        this.effectiveFrom = effectiveFrom;
        this.effectiveUntil = effectiveUntil;
        this.active = active;
        this.updatedAt = now;
    }

    public UUID getId() { return id; }
    public Hospital getHospital() { return hospital; }
    public DoctorProfile getDoctor() { return doctor; }
    public int getDayOfWeek() { return dayOfWeek; }
    public LocalTime getStartTime() { return startTime; }
    public LocalTime getEndTime() { return endTime; }
    public int getSlotMinutes() { return slotMinutes; }
    public LocalDate getEffectiveFrom() { return effectiveFrom; }
    public LocalDate getEffectiveUntil() { return effectiveUntil; }
    public boolean isActive() { return active; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
