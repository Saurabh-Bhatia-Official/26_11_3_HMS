package com.caresync.backend.hospital.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "hospital_registrations",
        uniqueConstraints = @jakarta.persistence.UniqueConstraint(
                name = "uk_hospital_registration_pending_admin_username", columnNames = "admin_username_reservation"),
        indexes = @Index(name = "ix_hospital_registration_status_date", columnList = "status, submitted_at"))
public class HospitalRegistration {
    @Id
    @Column(name = "registration_uuid", nullable = false, updatable = false)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", nullable = false, unique = true)
    private Hospital hospital;

    @Column(name = "admin_username", nullable = false, length = 64)
    private String adminUsername;

    /** Unique while pending; released at decision so rejected applications can be resubmitted. */
    @Column(name = "admin_username_reservation", length = 64)
    private String adminUsernameReservation;

    @Column(name = "admin_full_name", nullable = false, length = 160)
    private String adminFullName;

    /** BCrypt hash only; never store the submitted password. Cleared after review. */
    @Column(name = "admin_password_hash", length = 100)
    private String adminPasswordHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private HospitalStatus status;

    @Column(name = "submitted_at", nullable = false, updatable = false)
    private Instant submittedAt;

    @Column(name = "reviewed_at")
    private Instant reviewedAt;

    @Column(name = "reviewed_by_account_id")
    private Long reviewedByAccountId;

    protected HospitalRegistration() {}

    public HospitalRegistration(UUID id, Hospital hospital, String adminUsername, String adminFullName,
                                String adminPasswordHash, Instant submittedAt) {
        this.id = id;
        this.hospital = hospital;
        this.adminUsername = adminUsername;
        this.adminUsernameReservation = adminUsername;
        this.adminFullName = adminFullName;
        this.adminPasswordHash = adminPasswordHash;
        this.status = HospitalStatus.PENDING;
        this.submittedAt = submittedAt;
    }

    public UUID getId() { return id; }
    public Hospital getHospital() { return hospital; }
    public String getAdminUsername() { return adminUsername; }
    public String getAdminFullName() { return adminFullName; }
    public String getAdminPasswordHash() { return adminPasswordHash; }
    public HospitalStatus getStatus() { return status; }
    public Instant getSubmittedAt() { return submittedAt; }
    public Instant getReviewedAt() { return reviewedAt; }
    public Long getReviewedByAccountId() { return reviewedByAccountId; }

    public void approve(long reviewerAccountId, Instant now) {
        if (status != HospitalStatus.PENDING) throw new IllegalStateException("Only pending registrations can be approved");
        status = HospitalStatus.APPROVED;
        reviewedByAccountId = reviewerAccountId;
        reviewedAt = now;
        adminPasswordHash = null;
        adminUsernameReservation = null;
    }

    public void reject(long reviewerAccountId, Instant now) {
        if (status != HospitalStatus.PENDING) throw new IllegalStateException("Only pending registrations can be rejected");
        status = HospitalStatus.REJECTED;
        reviewedByAccountId = reviewerAccountId;
        reviewedAt = now;
        adminPasswordHash = null;
        adminUsernameReservation = null;
    }

    /** Expires a pending registration without adding a new public status or schema column. */
    public void expire(Instant now) {
        if (status != HospitalStatus.PENDING) throw new IllegalStateException("Only pending registrations can expire");
        status = HospitalStatus.REJECTED;
        reviewedByAccountId = null;
        reviewedAt = now;
        adminPasswordHash = null;
        adminUsernameReservation = null;
        hospital.reject();
    }
}
