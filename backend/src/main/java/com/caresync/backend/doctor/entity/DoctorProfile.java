package com.caresync.backend.doctor.entity;

import com.caresync.backend.department.entity.Department;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.membership.entity.HospitalMembership;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Version;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "doctor_profiles",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_doctor_profile_id_hospital",
                        columnNames = {"doctor_uuid", "hospital_uuid"}),
                @UniqueConstraint(name = "uk_doctor_profile_membership", columnNames = "membership_id")
        },
        indexes = {
                @Index(name = "ix_doctor_profile_hospital_active_name",
                        columnList = "hospital_uuid, active, specialization"),
                @Index(name = "ix_doctor_profile_membership", columnList = "membership_id")
        })
public class DoctorProfile {
    @Id
    @Column(name = "doctor_uuid", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", nullable = false, updatable = false)
    private Hospital hospital;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "membership_id", nullable = false, updatable = false)
    private HospitalMembership membership;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_uuid")
    private Department department;

    @Column(name = "specialization", nullable = false, length = 120)
    private String specialization;

    @Column(name = "qualification", nullable = false, length = 160)
    private String qualification;

    /** Professional registration reference only; no verification is performed by CareSync. */
    @Column(name = "registration_reference", length = 120)
    private String registrationReference;

    @Column(name = "active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    @Column(name = "record_version", nullable = false)
    private long version;

    protected DoctorProfile() {}

    public DoctorProfile(UUID id, Hospital hospital, HospitalMembership membership, Department department,
                         String specialization, String qualification, String registrationReference, Instant now) {
        this.id = id;
        this.hospital = hospital;
        this.membership = membership;
        this.department = department;
        this.specialization = specialization;
        this.qualification = qualification;
        this.registrationReference = registrationReference;
        this.active = true;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void update(Department department, String specialization, String qualification,
                       String registrationReference, Instant now) {
        this.department = department;
        this.specialization = specialization;
        this.qualification = qualification;
        this.registrationReference = registrationReference;
        this.updatedAt = now;
    }

    public void setActive(boolean active, Instant now) {
        this.active = active;
        this.updatedAt = now;
    }

    public UUID getId() { return id; }
    public Hospital getHospital() { return hospital; }
    public HospitalMembership getMembership() { return membership; }
    public Department getDepartment() { return department; }
    public String getSpecialization() { return specialization; }
    public String getQualification() { return qualification; }
    public String getRegistrationReference() { return registrationReference; }
    public boolean isActive() { return active; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public long getVersion() { return version; }
}
