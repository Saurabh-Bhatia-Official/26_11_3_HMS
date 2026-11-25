package com.caresync.backend.membership.entity;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.security.AuthAccount;
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
import java.util.UUID;

@Entity
@Table(name = "hospital_memberships",
        uniqueConstraints = @UniqueConstraint(name = "uk_membership_account_single_hospital", columnNames = "account_id"),
        indexes = @Index(name = "ix_membership_hospital_status", columnList = "hospital_uuid, status"))
public class HospitalMembership {
    @Id
    @Column(name = "membership_id", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id", nullable = false)
    private AuthAccount account;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "hospital_uuid", referencedColumnName = "hospital_uuid", nullable = false)
    private Hospital hospital;

    @Enumerated(EnumType.STRING)
    @Column(name = "membership_role", nullable = false, length = 32)
    private MembershipRole role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private MembershipStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "revoked_at")
    private Instant revokedAt;

    @Column(name = "revoked_by_account_id")
    private Long revokedByAccountId;

    protected HospitalMembership() {}

    public HospitalMembership(UUID id, AuthAccount account, Hospital hospital, MembershipRole role, Instant now) {
        this.id = id;
        this.account = account;
        this.hospital = hospital;
        this.role = role;
        this.status = MembershipStatus.ACTIVE;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public UUID getId() { return id; }
    public AuthAccount getAccount() { return account; }
    public Hospital getHospital() { return hospital; }
    public MembershipRole getRole() { return role; }
    public MembershipStatus getStatus() { return status; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public Instant getRevokedAt() { return revokedAt; }
    public Long getRevokedByAccountId() { return revokedByAccountId; }

    public void changeRole(MembershipRole role, Instant now) {
        this.role = role;
        this.updatedAt = now;
    }

    public void activate(Instant now) {
        status = MembershipStatus.ACTIVE;
        revokedAt = null;
        revokedByAccountId = null;
        updatedAt = now;
    }

    public void deactivate(Instant now) {
        if (status == MembershipStatus.REVOKED) throw new IllegalStateException("Revoked membership cannot be deactivated");
        status = MembershipStatus.INACTIVE;
        updatedAt = now;
    }

    public void revoke(long actorId, Instant now) {
        status = MembershipStatus.REVOKED;
        revokedAt = now;
        revokedByAccountId = actorId;
        updatedAt = now;
    }
}
