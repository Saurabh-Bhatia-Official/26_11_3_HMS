package com.caresync.backend.security;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Index;

import java.time.Instant;

@Entity
@Table(name = "auth_refresh_tokens", indexes = {
        @Index(name = "ix_auth_refresh_expires_at", columnList = "expires_at"),
        @Index(name = "ix_auth_refresh_family_id", columnList = "family_id")
})
public class RefreshToken {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id", nullable = false)
    private AuthAccount account;

    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "hospital_id")
    private Long hospitalId;

    @Column(name = "family_id", length = 36)
    private String familyId;

    @Column(name = "revoked", nullable = false)
    private boolean revoked;

    protected RefreshToken() {}

    public RefreshToken(AuthAccount account, String tokenHash, Instant expiresAt, Long hospitalId, String familyId) {
        this.account = account;
        this.tokenHash = tokenHash;
        this.expiresAt = expiresAt;
        this.hospitalId = hospitalId;
        this.familyId = familyId;
    }
    public AuthAccount getAccount() { return account; }
    public String getTokenHash() { return tokenHash; }
    public Instant getExpiresAt() { return expiresAt; }
    public Long getHospitalId() { return hospitalId; }
    public String getFamilyId() { return familyId; }
    public void setFamilyId(String familyId) { this.familyId = familyId; }
    public boolean isRevoked() { return revoked; }
    public void revoke() { revoked = true; }
}
