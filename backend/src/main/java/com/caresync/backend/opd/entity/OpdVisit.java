
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
        @Index(name = "idx_opd_visit_status", columnList = "status"),
        @Index(name = "idx_opd_visit_hospital_uuid", columnList = "hospital_uuid"),
        @Index(name = "idx_opd_visit_doctor_uuid", columnList = "doctor_uuid"),
        @Index(name = "idx_opd_visit_appointment_uuid", columnList = "appointment_uuid")
    }
)
public class OpdVisit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID uuid;

    // Legacy numeric hospital identifier
    @Column(name = "hospital_id", nullable = false)
    private Long hospitalId;

    // Modern hospital identifier
    @Column(name = "hospital_uuid")
    private UUID hospitalUuid;

    // Patient primary key remains BIGINT
    @Column(name = "patient_id", nullable = false)
    private Long patientId;

    // Legacy numeric references (nullable for new UUID-based records)
    @Column(name = "doctor_id")
    private Long doctorId;

    @Column(name = "department_id")
    private Long departmentId;

    @Column(name = "appointment_id")
    private Long appointmentId;

    // Modern references
    @Column(name = "doctor_uuid")
    private UUID doctorUuid;

    @Column(name = "department_uuid")
    private UUID departmentUuid;

    @Column(name = "appointment_uuid")
    private UUID appointmentUuid;

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

    /**
     * Constructor for new UUID-based OPD visits.
     */
    public OpdVisit(
            Long hospitalId,
            UUID hospitalUuid,
            Long patientId,
            UUID doctorUuid,
            UUID departmentUuid,
            UUID appointmentUuid,
            String visitType,
            Integer tokenNo,
            LocalDate visitDate
    ) {
        this.hospitalId = hospitalId;
        this.hospitalUuid = hospitalUuid;
        this.patientId = patientId;
        this.doctorUuid = doctorUuid;
        this.departmentUuid = departmentUuid;
        this.appointmentUuid = appointmentUuid;
        this.visitType = visitType;
        this.tokenNo = tokenNo;
        this.visitDate = visitDate;
        this.status = OpdVisitStatus.WAITING_FOR_VITALS;
    }

    /**
     * Legacy constructor retained for existing callers.
     */
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

        if (uuid == null) {
            uuid = UUID.randomUUID();
        }

        if (createdAt == null) {
            createdAt = now;
        }

        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() { return id; }
    public UUID getUuid() { return uuid; }

    public Long getHospitalId() { return hospitalId; }
    public UUID getHospitalUuid() { return hospitalUuid; }

    public Long getPatientId() { return patientId; }

    public Long getDoctorId() { return doctorId; }
    public Long getDepartmentId() { return departmentId; }
    public Long getAppointmentId() { return appointmentId; }

    public UUID getDoctorUuid() { return doctorUuid; }
    public UUID getDepartmentUuid() { return departmentUuid; }
    public UUID getAppointmentUuid() { return appointmentUuid; }

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
