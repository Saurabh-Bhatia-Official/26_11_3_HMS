package com.caresync.backend.security;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;

@Entity
@Table(name = "auth_accounts", uniqueConstraints = @UniqueConstraint(name = "uk_auth_account_username", columnNames = "username"),
        indexes = @Index(name = "ix_auth_account_hospital", columnList = "hospital_id"))
public class AuthAccount {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Column(name = "full_name", nullable = false, length = 160)
    private String fullName;

    @Column(nullable = false, length = 32)
    private String role;

    @Column(name = "hospital_id")
    private Long hospitalId;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @Column(name = "failed_login_attempts", nullable = false)
    private int failedLoginAttempts;

    @Column(name = "locked_until")
    private Instant lockedUntil;

    @Column(name = "token_version", nullable = false, columnDefinition = "bigint default 0")
    private long tokenVersion;

    protected AuthAccount() {}

    public AuthAccount(String username, String passwordHash, String fullName, String role, Long hospitalId) {
        this.username = username.trim().toLowerCase();
        this.passwordHash = passwordHash;
        this.fullName = fullName;
        if (!SecurityRole.supports(role)) throw new IllegalArgumentException("Unsupported account role");
        this.role = role;
        this.hospitalId = hospitalId;
        if (!"SUPER_ADMIN".equals(role) && hospitalId == null) {
            throw new IllegalArgumentException("Hospital users must belong to a hospital");
        }
    }

    public Long getId() { return id; }
    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public String getFullName() { return fullName; }
    public String getRole() { return role; }
    public Long getHospitalId() { return hospitalId; }
    public boolean isActive() { return active; }
    public int getFailedLoginAttempts() { return failedLoginAttempts; }
    public Instant getLockedUntil() { return lockedUntil; }
    public long getTokenVersion() { return tokenVersion; }
    public boolean hasValidHospitalScope() {
        return ("SUPER_ADMIN".equals(role) && (hospitalId == null || hospitalId > 0))
                || (SecurityRole.supports(role) && !"SUPER_ADMIN".equals(role) && hospitalId != null && hospitalId > 0);
    }
    public void resetExpiredLockout(Instant now) {
        if (lockedUntil != null && !lockedUntil.isAfter(now)) {
            failedLoginAttempts = 0;
            lockedUntil = null;
        }
    }
    public void recordFailure(Instant now) {
        failedLoginAttempts++;
        if (failedLoginAttempts >= 5) lockedUntil = now.plusSeconds(900);
    }
    public void recordSuccess() { failedLoginAttempts = 0; lockedUntil = null; }
    public void invalidateTokens() { tokenVersion++; }
    public void deactivate() { active = false; tokenVersion++; }
}
