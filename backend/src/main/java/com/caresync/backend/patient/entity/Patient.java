
package com.caresync.backend.patient.entity;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.caresync.backend.hospital.entity.Hospital;

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
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Version;

@Entity
@Table(name = "patients",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_patient_uuid", columnNames = "patient_uuid"),
                @UniqueConstraint(name = "uk_patient_hospital_uhid", columnNames = {"hospital_uuid", "uhid"})
        },
        indexes = {
                @Index(name = "ix_patient_hospital_status_created", columnList = "hospital_uuid, status, created_at"),
                @Index(name = "ix_patient_hospital_name", columnList = "hospital_uuid, name"),
                @Index(name = "ix_patient_hospital_phone", columnList = "hospital_uuid, phone")
        })
public class Patient {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "patient_id_generator")
    @SequenceGenerator(name = "patient_id_generator", sequenceName = "patient_id_sequence", allocationSize = 1)
    @Column(name = "patient_id", nullable = false, updatable = false)
    private Long id;

    /** Client-generated immutable cross-device key; never an authorization credential. */
    @Column(name = "patient_uuid", nullable = false, updatable = false)
    private UUID uuid;
    @Column(name = "uuid", nullable = false, updatable = false)
    private String legacyUuid;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", referencedColumnName = "hospital_uuid", nullable = false, updatable = false)
    private Hospital hospital;

    // Numeric hospital identifier, separate from the hospital UUID.
    @Column(name = "hospital_id", nullable = false, updatable = false)
    private Long hospitalId;

    @Column(name = "uhid", nullable = false, length = 30)
    private String uhid;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "gender", length = 16)
    private String gender;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(name = "age_years")
    private Integer ageYears;

    @Column(name = "phone", length = 32)
    private String phone;

    @Column(name = "alternate_phone", length = 32)
    private String alternatePhone;

    @Column(name = "email", length = 254)
    private String email;

    @Column(name = "address", length = 255)
    private String address;

    @Column(name = "city", length = 100)
    private String city;

    @Column(name = "state", length = 100)
    private String state;

    @Column(name = "pincode", length = 32)
    private String pincode;

    @Column(name = "blood_group", length = 3)
    private String bloodGroup;

    @Column(name = "emergency_contact_name", length = 160)
    private String emergencyContactName;

    @Column(name = "emergency_contact_phone", length = 32)
    private String emergencyContactPhone;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    private PatientStatus status;

    @Column(name = "archived_at")
    private Instant archivedAt;

    // Soft-delete flag: new patients are not deleted.
    @Column(name = "is_deleted", nullable = false)
    private boolean isDeleted = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "created_by_account_id", nullable = false, updatable = false)
    private Long createdByAccountId;

    @Column(name = "updated_by_account_id", nullable = false)
    private Long updatedByAccountId;

    @Version
    @Column(name = "record_version", nullable = false)
    private long version;

    protected Patient() {}

    public Patient(UUID uuid, Hospital hospital, String uhid, String name, String gender, LocalDate dateOfBirth,
                   Integer ageYears, String phone, String alternatePhone, String email, String address,
                   String city, String state, String pincode, String bloodGroup, String emergencyContactName,
                   String emergencyContactPhone, long actorAccountId, Instant now) {

        this.uuid = uuid;
        this.legacyUuid = uuid.toString();
        this.hospital = hospital;
        this.hospitalId = hospital.getHospitalId();
        this.uhid = uhid;
        this.name = name;
        this.gender = gender;
        this.dateOfBirth = dateOfBirth;
        this.ageYears = ageYears;
        this.phone = phone;
        this.alternatePhone = alternatePhone;
        this.email = email;
        this.address = address;
        this.city = city;
        this.state = state;
        this.pincode = pincode;
        this.bloodGroup = bloodGroup;
        this.emergencyContactName = emergencyContactName;
        this.emergencyContactPhone = emergencyContactPhone;
        this.status = PatientStatus.ACTIVE;
        this.isDeleted = false;
        this.createdAt = now;
        this.updatedAt = now;
        this.createdByAccountId = actorAccountId;
        this.updatedByAccountId = actorAccountId;
    }

    public void update(String name, String gender, LocalDate dateOfBirth, Integer ageYears, String phone,
                       String alternatePhone, String email, String address, String city, String state,
                       String pincode, String bloodGroup, String emergencyContactName,
                       String emergencyContactPhone, long actorAccountId, Instant now) {

        this.name = name;
        this.gender = gender;
        this.dateOfBirth = dateOfBirth;
        this.ageYears = ageYears;
        this.phone = phone;
        this.alternatePhone = alternatePhone;
        this.email = email;
        this.address = address;
        this.city = city;
        this.state = state;
        this.pincode = pincode;
        this.bloodGroup = bloodGroup;
        this.emergencyContactName = emergencyContactName;
        this.emergencyContactPhone = emergencyContactPhone;
        this.updatedByAccountId = actorAccountId;
        this.updatedAt = now;
    }

    public void changeStatus(PatientStatus status, long actorAccountId, Instant now) {
        this.status = status;
        this.updatedByAccountId = actorAccountId;
        this.updatedAt = now;
    }

    public void archive(long actorAccountId, Instant now) {
        if (archivedAt == null) {
            archivedAt = now;
            updatedAt = now;
            updatedByAccountId = actorAccountId;
        }
    }

    public void assignServerUhid(String uhid) {
        if (this.uhid != null) {
            throw new IllegalStateException("Patient UHID is immutable after assignment");
        }
        this.uhid = uhid;
    }
    public String getLegacyUuid() {
    return legacyUuid;
}
    public Long getId() { return id; }
    public UUID getUuid() { return uuid; }
    public Hospital getHospital() { return hospital; }
    public Long getHospitalId() { return hospitalId; }
    public String getUhid() { return uhid; }
    public String getName() { return name; }
    public String getGender() { return gender; }
    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public Integer getAgeYears() { return ageYears; }
    public String getPhone() { return phone; }
    public String getAlternatePhone() { return alternatePhone; }
    public String getEmail() { return email; }
    public String getAddress() { return address; }
    public String getCity() { return city; }
    public String getState() { return state; }
    public String getPincode() { return pincode; }
    public String getBloodGroup() { return bloodGroup; }
    public String getEmergencyContactName() { return emergencyContactName; }
    public String getEmergencyContactPhone() { return emergencyContactPhone; }
    public PatientStatus getStatus() { return status; }
    public Instant getArchivedAt() { return archivedAt; }
    public boolean isDeleted() { return isDeleted; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public Long getCreatedByAccountId() { return createdByAccountId; }
    public Long getUpdatedByAccountId() { return updatedByAccountId; }
    public long getVersion() { return version; }
}
