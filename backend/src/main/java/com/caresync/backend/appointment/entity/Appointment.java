package com.caresync.backend.appointment.entity;

import com.caresync.backend.department.entity.Department;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.patient.entity.Patient;
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
import jakarta.persistence.Version;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "appointments",
        uniqueConstraints = @UniqueConstraint(name = "uk_appointment_id_hospital",
                columnNames = {"appointment_uuid", "hospital_uuid"}),
        indexes = {
                @Index(name = "ix_appointment_hospital_start", columnList = "hospital_uuid, starts_at"),
                @Index(name = "ix_appointment_doctor_start_status", columnList = "hospital_uuid, doctor_uuid, starts_at, status"),
                @Index(name = "ix_appointment_patient_start", columnList = "hospital_uuid, patient_id, starts_at")
        })
public class Appointment {
    @Id
    @Column(name = "appointment_uuid", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", nullable = false, updatable = false)
    private Hospital hospital;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false, updatable = false)
    private Patient patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "doctor_uuid", nullable = false, updatable = false)
    private DoctorProfile doctor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_uuid", updatable = false)
    private Department department;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by_membership_id", nullable = false, updatable = false)
    private HospitalMembership createdByMembership;

    @Column(name = "starts_at", nullable = false)
    private OffsetDateTime startsAt;

    @Column(name = "ends_at", nullable = false)
    private OffsetDateTime endsAt;

    @Column(name = "appointment_type", nullable = false, length = 40)
    private String appointmentType;

    @Column(name = "reason", length = 500)
    private String reason;

    @Column(name = "notes", length = 2000)
    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    private AppointmentStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    @Column(name = "record_version", nullable = false)
    private long version;

    protected Appointment() {}

    public Appointment(UUID id, Hospital hospital, Patient patient, DoctorProfile doctor, Department department,
                       HospitalMembership creator, OffsetDateTime startsAt, OffsetDateTime endsAt,
                       String appointmentType, String reason, String notes, Instant now) {
        this.id = id;
        this.hospital = hospital;
        this.patient = patient;
        this.doctor = doctor;
        this.department = department;
        this.createdByMembership = creator;
        this.startsAt = startsAt;
        this.endsAt = endsAt;
        this.appointmentType = appointmentType;
        this.reason = reason;
        this.notes = notes;
        this.status = AppointmentStatus.SCHEDULED;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void reschedule(OffsetDateTime start, OffsetDateTime end, Instant now) {
        startsAt = start;
        endsAt = end;
        updatedAt = now;
    }

    public void transition(AppointmentStatus next, Instant now) {
        status = next;
        updatedAt = now;
    }

    public UUID getId() { return id; }
    public Hospital getHospital() { return hospital; }
    public Patient getPatient() { return patient; }
    public DoctorProfile getDoctor() { return doctor; }
    public Department getDepartment() { return department; }
    public HospitalMembership getCreatedByMembership() { return createdByMembership; }
    public OffsetDateTime getStartsAt() { return startsAt; }
    public OffsetDateTime getEndsAt() { return endsAt; }
    public String getAppointmentType() { return appointmentType; }
    public String getReason() { return reason; }
    public String getNotes() { return notes; }
    public AppointmentStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public long getVersion() { return version; }
}
