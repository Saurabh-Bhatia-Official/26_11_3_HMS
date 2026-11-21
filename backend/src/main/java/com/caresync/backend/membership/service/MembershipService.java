package com.caresync.backend.membership.service;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipAuditEvent;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.MembershipStatus;
import com.caresync.backend.membership.repository.HospitalMembershipRepository;
import com.caresync.backend.membership.repository.MembershipAuditEventRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.RefreshToken;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.tenant.TenantContext;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class MembershipService {
    private final HospitalMembershipRepository memberships;
    private final MembershipAuditEventRepository auditEvents;
    private final AuthAccountRepository accounts;
    private final HospitalRepository hospitals;
    private final RefreshTokenRepository refreshTokens;

    public MembershipService(HospitalMembershipRepository memberships,
                             MembershipAuditEventRepository auditEvents,
                             AuthAccountRepository accounts,
                             HospitalRepository hospitals,
                             RefreshTokenRepository refreshTokens) {
        this.memberships = memberships;
        this.auditEvents = auditEvents;
        this.accounts = accounts;
        this.hospitals = hospitals;
        this.refreshTokens = refreshTokens;
    }

    /** Called inside the Central Admin approval transaction; no legacy account backfill occurs. */
    @Transactional
    public HospitalMembership provisionHospitalSuperAdmin(AuthAccount account, Hospital hospital, long actorAccountId) {
        if (account.getId() == null || !"HOSPITAL_SUPER_ADMIN".equals(account.getRole())
                || hospital.getStatus() != HospitalStatus.APPROVED
                || !java.util.Objects.equals(account.getHospitalId(), hospital.getHospitalId())) {
            throw new IllegalArgumentException("Initial Hospital Super Admin membership is inconsistent");
        }
        if (memberships.findByAccount_Id(account.getId()).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Account already has a Hospital membership");
        }
        Instant now = Instant.now();
        HospitalMembership membership = memberships.save(new HospitalMembership(
                UUID.randomUUID(), account, hospital, MembershipRole.HOSPITAL_SUPER_ADMIN, now));
        auditEvents.save(new MembershipAuditEvent(membership, actorAccountId, "PROVISIONED", now));
        return membership;
    }

    /** Hospital Super Admin may grant only staff-level roles inside their own Hospital. */
    @Transactional
    public HospitalMembership grant(long actorAccountId, long targetAccountId, MembershipRole role) {
        if (!MembershipRole.isGrantableByHospitalAdmin(role)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Role cannot be granted by a Hospital administrator");
        }
        TenantContext actorContext = requireHospitalSuperAdmin(actorAccountId);
        AuthAccount target = accounts.findByIdForUpdate(targetAccountId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Account not found"));
        if (!target.isActive() || !java.util.Objects.equals(target.getHospitalId(), actorContext.hospitalId())
                || "SUPER_ADMIN".equals(target.getRole()) || "HOSPITAL_SUPER_ADMIN".equals(target.getRole())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Account is not eligible for this Hospital membership");
        }
        if (memberships.findByAccount_Id(targetAccountId).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Account already has a Hospital membership");
        }
        Hospital hospital = hospitals.findById(actorContext.hospitalUuid())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Hospital access unavailable"));
        Instant now = Instant.now();
        target.changeRole(role.name());
        HospitalMembership membership = memberships.save(new HospitalMembership(
                UUID.randomUUID(), target, hospital, role, now));
        auditEvents.save(new MembershipAuditEvent(membership, actorAccountId, "GRANTED", now));
        return membership;
    }

    @Transactional(readOnly = true)
    public List<HospitalMembership> listForHospitalSuperAdmin(long actorAccountId) {
        TenantContext actor = requireHospitalSuperAdmin(actorAccountId);
        return memberships.findAllByHospital_IdOrderByCreatedAtDesc(actor.hospitalUuid());
    }

    @Transactional(readOnly = true)
    public HospitalMembership getForHospitalSuperAdmin(long actorAccountId, UUID membershipId) {
        TenantContext actor = requireHospitalSuperAdmin(actorAccountId);
        return memberships.findByIdAndHospital_Id(membershipId, actor.hospitalUuid())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Membership not found"));
    }

    @Transactional
    public HospitalMembership changeRole(long actorAccountId, UUID membershipId, MembershipRole role) {
        if (!MembershipRole.isGrantableByHospitalAdmin(role)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Role cannot be granted by a Hospital administrator");
        }
        TenantContext actor = requireHospitalSuperAdmin(actorAccountId);
        HospitalMembership membership = memberships.findByIdAndHospitalIdForUpdate(membershipId, actor.hospitalUuid())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Membership not found"));
        if (membership.getRole() == MembershipRole.HOSPITAL_SUPER_ADMIN
                || membership.getStatus() == MembershipStatus.REVOKED) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Membership role cannot be changed by this actor");
        }
        AuthAccount target = accounts.findByIdForUpdate(membership.getAccount().getId()).orElseThrow();
        Instant now = Instant.now();
        membership.changeRole(role, now);
        target.changeRole(role.name());
        refreshTokens.findAllByAccount_Id(target.getId()).forEach(RefreshToken::revoke);
        auditEvents.save(new MembershipAuditEvent(membership, actorAccountId, "ROLE_CHANGED", now));
        return membership;
    }

    @Transactional
    public HospitalMembership changeStatus(long actorAccountId, UUID membershipId, MembershipStatus status) {
        TenantContext actor = requireHospitalSuperAdmin(actorAccountId);
        HospitalMembership membership = memberships.findByIdAndHospitalIdForUpdate(membershipId, actor.hospitalUuid())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Membership not found"));
        if (membership.getRole() == MembershipRole.HOSPITAL_SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Membership cannot be changed by this actor");
        }
        if (status == MembershipStatus.INACTIVE && membership.getStatus() == MembershipStatus.REVOKED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Revoked membership must be activated explicitly");
        }
        Instant now = Instant.now();
        switch (status) {
            case ACTIVE -> membership.activate(now);
            case INACTIVE -> membership.deactivate(now);
            case REVOKED -> membership.revoke(actorAccountId, now);
        }
        AuthAccount target = accounts.findByIdForUpdate(membership.getAccount().getId()).orElseThrow();
        if (status == MembershipStatus.REVOKED || status == MembershipStatus.INACTIVE) {
            target.invalidateTokens();
            refreshTokens.findAllByAccount_Id(target.getId()).forEach(RefreshToken::revoke);
        }
        auditEvents.save(new MembershipAuditEvent(membership, actorAccountId, status.name(), now));
        return membership;
    }

    @Transactional(readOnly = true)
    public Optional<TenantContext> resolveActiveContext(long accountId, long hospitalId) {
        return memberships.findByAccount_IdAndStatusAndHospital_HospitalId(accountId, MembershipStatus.ACTIVE, hospitalId)
                .filter(membership -> membership.getHospital().getStatus() == HospitalStatus.APPROVED)
                .filter(membership -> membership.getAccount().isActive())
                .filter(membership -> java.util.Objects.equals(membership.getAccount().getHospitalId(), hospitalId))
                .filter(membership -> membership.getAccount().getRole().equals(membership.getRole().name()))
                .map(membership -> new TenantContext(accountId, membership.getId(), membership.getHospital().getId(),
                        hospitalId, membership.getRole()));
    }

    /** Missing membership means a legacy account; an existing non-active/mismatched row is denied. */
    @Transactional(readOnly = true)
    public boolean allowsAuthenticationOrRefresh(AuthAccount account) {
        if (account.getHospitalId() == null) return "SUPER_ADMIN".equals(account.getRole());
        Optional<HospitalMembership> membership = memberships.findByAccount_Id(account.getId());
        return membership.isEmpty() || resolveActiveContext(account.getId(), account.getHospitalId()).isPresent();
    }

    private TenantContext requireHospitalSuperAdmin(long accountId) {
        Long hospitalId = accounts.findById(accountId).map(AuthAccount::getHospitalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Unauthorized"));
        if (hospitalId == null) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Hospital membership required");
        Optional<TenantContext> context = resolveActiveContext(accountId, hospitalId);
        if (context.isEmpty() || context.get().membershipRole() != MembershipRole.HOSPITAL_SUPER_ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Hospital Super Admin membership required");
        }
        return context.get();
    }
}
