package com.caresync.backend.hospital.service;

import com.caresync.backend.hospital.dto.HospitalApprovalResponse;
import com.caresync.backend.hospital.dto.HospitalLoginOption;
import com.caresync.backend.hospital.dto.HospitalRegistrationRequest;
import com.caresync.backend.hospital.dto.HospitalRegistrationReviewResponse;
import com.caresync.backend.hospital.dto.HospitalRegistrationSubmitted;
import com.caresync.backend.hospital.dto.HospitalProfileResponse;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalRegistration;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.hospital.repository.HospitalRegistrationRepository;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.BearerTokenFilter;
import com.caresync.backend.security.SecurityAuditEvent;
import com.caresync.backend.security.SecurityAuditEventRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class HospitalManagementService {
    private final HospitalRepository hospitals;
    private final HospitalIdGenerator hospitalIds;
    private final HospitalRegistrationRepository registrations;
    private final AuthAccountRepository accounts;
    private final SecurityAuditEventRepository auditEvents;
    private final PasswordEncoder passwordEncoder;

    public HospitalManagementService(HospitalRepository hospitals,
                                     HospitalRegistrationRepository registrations,
                                     AuthAccountRepository accounts,
                                     SecurityAuditEventRepository auditEvents,
                                     PasswordEncoder passwordEncoder,
                                     HospitalIdGenerator hospitalIds) {
        this.hospitals = hospitals;
        this.registrations = registrations;
        this.accounts = accounts;
        this.auditEvents = auditEvents;
        this.passwordEncoder = passwordEncoder;
        this.hospitalIds = hospitalIds;
    }

    @Transactional
    public HospitalRegistrationSubmitted submit(HospitalRegistrationRequest request) {
        String username = request.adminUsername().trim().toLowerCase(java.util.Locale.ROOT);
        if (accounts.existsByUsername(username)
                || registrations.existsByAdminUsernameIgnoreCaseAndStatus(username, HospitalStatus.PENDING)) {
            throw new HospitalApiException(HttpStatus.CONFLICT, "The requested administrator username is unavailable");
        }

        Instant now = Instant.now();
        Hospital hospital = new Hospital(UUID.randomUUID(), request.name().trim(), request.code().trim().toUpperCase(Locale.ROOT),
                request.type().trim(), request.address(), request.phone(), request.email(), request.taxId(), now);
        hospitals.save(hospital);

        HospitalRegistration registration = new HospitalRegistration(UUID.randomUUID(), hospital, username,
                request.adminFullName().trim(), passwordEncoder.encode(request.adminPassword()), now);
        try {
            registrations.saveAndFlush(registration);
        } catch (org.springframework.dao.DataIntegrityViolationException duplicatePendingUsername) {
            throw new HospitalApiException(HttpStatus.CONFLICT, "The requested administrator username is unavailable");
        }
        auditEvents.save(new SecurityAuditEvent("HOSPITAL_REGISTERED", null, now));
        return new HospitalRegistrationSubmitted(registration.getId(), registration.getStatus().name(), now);
    }

    @Transactional(readOnly = true)
    public List<HospitalRegistrationReviewResponse> pendingRegistrations(BearerTokenFilter.AuthPrincipal actor) {
        requirePlatformAdministrator(actor);
        return registrations.findAllByStatusOrderBySubmittedAtAsc(HospitalStatus.PENDING).stream()
                .map(this::toReviewResponse).toList();
    }

    @Transactional
    public HospitalApprovalResponse approve(UUID registrationId, BearerTokenFilter.AuthPrincipal actor) {
        requirePlatformAdministrator(actor);
        HospitalRegistration registration = registrations.findByIdForUpdate(registrationId)
                .orElseThrow(() -> new HospitalApiException(HttpStatus.NOT_FOUND, "Registration not found"));
        if (registration.getStatus() != HospitalStatus.PENDING || registration.getAdminPasswordHash() == null) {
            throw new HospitalApiException(HttpStatus.CONFLICT, "Registration is no longer pending");
        }
        if (accounts.existsByUsername(registration.getAdminUsername())) {
            throw new HospitalApiException(HttpStatus.CONFLICT, "The requested administrator username is unavailable");
        }

        long hospitalId = nextUniqueHospitalId();
        Hospital hospital = registration.getHospital();
        hospital.approve(hospitalId);
        hospitals.saveAndFlush(hospital);
        accounts.save(new AuthAccount(registration.getAdminUsername(), registration.getAdminPasswordHash(),
                registration.getAdminFullName(), "HOSPITAL_SUPER_ADMIN", hospitalId));
        registration.approve(actor.userId(), Instant.now());
        registrations.save(registration);
        auditEvents.save(new SecurityAuditEvent("HOSPITAL_APPROVED", actor.userId(), Instant.now()));
        return new HospitalApprovalResponse(hospital.getId(), Long.toString(hospitalId), hospital.getName(), hospital.getStatus().name());
    }

    @Transactional
    public void reject(UUID registrationId, BearerTokenFilter.AuthPrincipal actor) {
        requirePlatformAdministrator(actor);
        HospitalRegistration registration = registrations.findByIdForUpdate(registrationId)
                .orElseThrow(() -> new HospitalApiException(HttpStatus.NOT_FOUND, "Registration not found"));
        if (registration.getStatus() != HospitalStatus.PENDING) {
            throw new HospitalApiException(HttpStatus.CONFLICT, "Registration is no longer pending");
        }
        registration.getHospital().reject();
        registration.reject(actor.userId(), Instant.now());
        hospitals.save(registration.getHospital());
        registrations.save(registration);
        auditEvents.save(new SecurityAuditEvent("HOSPITAL_REJECTED", actor.userId(), Instant.now()));
    }

    @Transactional(readOnly = true)
    public List<HospitalLoginOption> approvedHospitals() {
        return hospitals.findAllByStatusOrderByNameAsc(HospitalStatus.APPROVED).stream()
                .map(hospital -> new HospitalLoginOption(Long.toString(hospital.getHospitalId()),
                        hospital.getName(), hospital.getType())).toList();
    }

    @Transactional(readOnly = true)
    public HospitalLoginOption findApprovedHospital(long hospitalId) {
        if (!isTwelveDigitHospitalId(hospitalId)) {
            throw new HospitalApiException(HttpStatus.NOT_FOUND, "Hospital not found");
        }
        Hospital hospital = hospitals.findByHospitalIdAndStatus(hospitalId, HospitalStatus.APPROVED)
                .orElseThrow(() -> new HospitalApiException(HttpStatus.NOT_FOUND, "Hospital not found"));
        return new HospitalLoginOption(Long.toString(hospitalId), hospital.getName(), hospital.getType());
    }

    @Transactional(readOnly = true)
    public HospitalProfileResponse currentHospital(BearerTokenFilter.AuthPrincipal actor) {
        if (actor == null || actor.hospitalId() == null || "SUPER_ADMIN".equals(actor.role())) {
            throw new HospitalApiException(HttpStatus.FORBIDDEN, "Forbidden");
        }
        Hospital hospital = hospitals.findByHospitalIdAndStatus(actor.hospitalId(), HospitalStatus.APPROVED)
                .orElseThrow(() -> new HospitalApiException(HttpStatus.FORBIDDEN, "Hospital access is unavailable"));
        return new HospitalProfileResponse(Long.toString(hospital.getHospitalId()), hospital.getName(),
                hospital.getCode(), hospital.getType(), hospital.getAddress(), hospital.getPhone(), hospital.getEmail());
    }

    private long nextUniqueHospitalId() {
        for (int attempt = 0; attempt < 32; attempt++) {
            final long candidate;
            try {
                candidate = hospitalIds.nextCandidate();
            } catch (org.springframework.dao.DataAccessException allocationFailure) {
                throw new HospitalApiException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Hospital ID allocation is temporarily unavailable");
            }
            if (candidate > 999_999_999_999L) {
                throw new HospitalApiException(HttpStatus.SERVICE_UNAVAILABLE,
                        "Hospital ID allocation is temporarily unavailable");
            }
            if (isTwelveDigitHospitalId(candidate) && !hospitals.existsByHospitalId(candidate)) return candidate;
        }
        throw new HospitalApiException(HttpStatus.SERVICE_UNAVAILABLE, "Hospital ID allocation is temporarily unavailable");
    }

    private static boolean isTwelveDigitHospitalId(long id) {
        return id >= 100_000_000_000L && id <= 999_999_999_999L;
    }

    private HospitalRegistrationReviewResponse toReviewResponse(HospitalRegistration registration) {
        Hospital hospital = registration.getHospital();
        return new HospitalRegistrationReviewResponse(registration.getId(), registration.getStatus().name(), hospital.getName(),
                hospital.getCode(), hospital.getType(), hospital.getAddress(), hospital.getPhone(), hospital.getEmail(),
                hospital.getTaxId(), registration.getAdminUsername(), registration.getAdminFullName(), registration.getSubmittedAt());
    }

    private static void requirePlatformAdministrator(BearerTokenFilter.AuthPrincipal actor) {
        if (actor == null || !"SUPER_ADMIN".equals(actor.role()) || actor.hospitalId() != null) {
            throw new HospitalApiException(HttpStatus.FORBIDDEN, "Forbidden");
        }
    }
}
