package com.caresync.backend.doctor.entity;

import com.caresync.backend.hospital.entity.Hospital;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "doctor_schedule_exceptions",
        uniqueConstraints = @UniqueConstraint(name = "uk_doctor_schedule_exception_id_hospital",
                columnNames = {"exception_uuid", "hospital_uuid"}),
        indexes = @Index(name = "ix_doctor_schedule_exception_lookup",
                columnList = "hospital_uuid, doctor_uuid, exception_date, active"))
public class DoctorScheduleException {
    @Id
    @Column(name = "exception_uuid", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", nullable = false, updatable = false)
    private Hospital hospital;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "doctor_uuid", nullable = false, updatable = false)
    private DoctorProfile doctor;

    @Column(name = "exception_date", nullable = false)
    private LocalDate date;

    @Enumerated(EnumType.STRING)
    @Column(name = "exception_type", nullable = false, length = 16)
    private ScheduleExceptionType type;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    @Column(name = "reason", length = 255)
    private String reason;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected DoctorScheduleException() {}

    public DoctorScheduleException(UUID id, Hospital hospital, DoctorProfile doctor, LocalDate date,
                                   ScheduleExceptionType type, LocalTime startTime, LocalTime endTime,
                                   String reason, Instant now) {
        this.id = id;
        this.hospital = hospital;
        this.doctor = doctor;
        this.date = date;
        this.type = type;
        this.startTime = startTime;
        this.endTime = endTime;
        this.reason = reason;
        this.active = true;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void update(LocalDate date, ScheduleExceptionType type, LocalTime startTime,
                       LocalTime endTime, String reason, boolean active, Instant now) {
        this.date = date;
        this.type = type;
        this.startTime = startTime;
        this.endTime = endTime;
        this.reason = reason;
        this.active = active;
        this.updatedAt = now;
    }

    public UUID getId() { return id; }
    public Hospital getHospital() { return hospital; }
    public DoctorProfile getDoctor() { return doctor; }
    public LocalDate getDate() { return date; }
    public ScheduleExceptionType getType() { return type; }
    public LocalTime getStartTime() { return startTime; }
    public LocalTime getEndTime() { return endTime; }
    public String getReason() { return reason; }
    public boolean isActive() { return active; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
