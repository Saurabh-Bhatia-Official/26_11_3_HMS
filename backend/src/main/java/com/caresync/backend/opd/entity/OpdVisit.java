package com.caresync.backend.opd.entity;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import jakarta.persistence.*;

@Entity
@Table(
    name = "opd_visits",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_opd_visit_hospital_appointment",
            columnNames = {"hospital_id", "appointment_id"}
        )
    },
    indexes = {
        @Index(name = "idx_opd_visit_hospital", columnList = "hospital_id"),
        @Index(name = "idx_opd_visit_patient", columnList = "patient_id"),
        @Index(name = "idx_opd_visit_doctor", columnList = "doctor_id"),
        @Index(name = "idx_opd_visit_date", columnList = "visit_date"),
        @Index(name = "idx_opd_visit_status", columnList = "status")
    }
)
public class OpdVisit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID uuid;

    @Column(name = "hospital_id", nullable = false)
    private Long hospitalId;

    @Column(name = "patient_id", nullable = false)
    private Long patientId;

    @Column(name = "doctor_id", nullable = false)
    private Long doctorId;

    @Column(name = "department_id", nullable = false)
    private Long departmentId;

    @Column(name = "appointment_id")
    private Long appointmentId;

    @Column(name = "visit_type", nullable = false, length = 20)
    private String visitType;

    @Column(name = "token_no", nullable = false)
    private Integer tokenNo;

    @Column(name = "visit_date", nullable = false)
    private LocalDate visitDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private OpdVisitStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected OpdVisit() {}

    public OpdVisit(
            Long hospitalId,
            Long patientId,
            Long doctorId,
            Long departmentId,
            Long appointmentId,
            String visitType,
            Integer tokenNo,
            LocalDate visitDate
    ) {
        this.hospitalId = hospitalId;
        this.patientId = patientId;
        this.doctorId = doctorId;
        this.departmentId = departmentId;
        this.appointmentId = appointmentId;
        this.visitType = visitType;
        this.tokenNo = tokenNo;
        this.visitDate = visitDate;
        this.status = OpdVisitStatus.WAITING_FOR_VITALS;
    }

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        if (uuid == null) uuid = UUID.randomUUID();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public UUID getUuid() { return uuid; }
    public Long getHospitalId() { return hospitalId; }
    public Long getPatientId() { return patientId; }
    public Long getDoctorId() { return doctorId; }
    public Long getDepartmentId() { return departmentId; }
    public Long getAppointmentId() { return appointmentId; }
    public String getVisitType() { return visitType; }
    public Integer getTokenNo() { return tokenNo; }
    public LocalDate getVisitDate() { return visitDate; }
    public OpdVisitStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }

    public void setStatus(OpdVisitStatus status) {
        this.status = status;
    }
}
