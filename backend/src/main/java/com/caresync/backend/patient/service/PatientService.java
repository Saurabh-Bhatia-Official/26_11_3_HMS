package com.caresync.backend.patient.service;

import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.patient.dto.PatientCreateRequest;
import com.caresync.backend.patient.dto.PatientResponse;
import com.caresync.backend.patient.dto.PatientStatusRequest;
import com.caresync.backend.patient.dto.PatientUpdateRequest;
import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.patient.entity.PatientStatus;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.security.BearerTokenFilter;
import com.caresync.backend.security.SecurityAuditEvent;
import com.caresync.backend.security.SecurityAuditEventRepository;
import com.caresync.backend.tenant.TenantContext;
import com.caresync.backend.tenant.TenantContextHolder;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class PatientService {
    private final PatientRepository patients;
    private final PatientCreationTransaction creation;
    private final TenantContextHolder tenantContext;
    private final SecurityAuditEventRepository auditEvents;

    public PatientService(PatientRepository patients, PatientCreationTransaction creation,
                          TenantContextHolder tenantContext, SecurityAuditEventRepository auditEvents) {
        this.patients = patients;
        this.creation = creation;
        this.tenantContext = tenantContext;
        this.auditEvents = auditEvents;
    }

    public PatientResponse create(PatientCreateRequest request, BearerTokenFilter.AuthPrincipal principal) {
        TenantContext context = requireContext(principal);
        requirePermission(PatientPermissionPolicy.canCreate(context.membershipRole()));
        for (int attempt = 0; attempt < 5; attempt++) {
            try {
                return creation.create(context.hospitalUuid(), context.accountId(), request);
            } catch (DataIntegrityViolationException uniqueRace) {
                Patient existing = patients.findByUuid(request.uuid()).orElse(null);
                if (existing != null) {
                    if (existing.getHospital().getId().equals(context.hospitalUuid())
                            && existing.getArchivedAt() == null && samePayload(existing, request)) {
                        return PatientResponse.from(existing);
                    }
                    throw new PatientApiException(HttpStatus.CONFLICT, "Patient synchronization conflict");
                }
                if (attempt == 4) {
                    throw new PatientApiException(HttpStatus.SERVICE_UNAVAILABLE,
                            "Could not allocate a Patient identifier; please retry");
                }
            }
        }
        throw new PatientApiException(HttpStatus.SERVICE_UNAVAILABLE, "Could not allocate a Patient identifier; please retry");
    }

    @Transactional(readOnly = true)
    public PaginationResponse<PatientResponse> list(String query, PatientStatus status,
                                                     PaginationRequest page,
                                                     BearerTokenFilter.AuthPrincipal principal) {
        TenantContext context = requireContext(principal);
        requirePermission(PatientPermissionPolicy.canView(context.membershipRole()));
        String normalizedQuery = query == null || query.isBlank() ? null : query.trim();
        UUID uuidQuery = parseUuid(normalizedQuery);
        Page<Patient> result = patients.searchHospitalPatients(context.hospitalUuid(), normalizedQuery,
                uuidQuery, status, PageRequest.of(page.page(), page.size(),
                        Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"))));
        List<PatientResponse> items = result.getContent().stream().map(PatientResponse::from).toList();
        return PaginationResponse.of(items, page, result.getTotalElements());
    }

    @Transactional(readOnly = true)
    public PatientResponse get(UUID patientUuid, BearerTokenFilter.AuthPrincipal principal) {
        TenantContext context = requireContext(principal);
        requirePermission(PatientPermissionPolicy.canView(context.membershipRole()));
        return findScoped(patientUuid, context.hospitalUuid()).map(PatientResponse::from)
                .orElseThrow(() -> notFound());
    }

    @Transactional
    public PatientResponse update(UUID patientUuid, PatientUpdateRequest request,
                                  BearerTokenFilter.AuthPrincipal principal) {
        TenantContext context = requireContext(principal);
        requirePermission(PatientPermissionPolicy.canEditDemographics(context.membershipRole()));
        Patient patient = findScoped(patientUuid, context.hospitalUuid()).orElseThrow(this::notFound);
        if (patient.getVersion() != request.version()) {
            throw new PatientApiException(HttpStatus.CONFLICT, "Patient was changed by another update");
        }
        patient.update(request.name(), request.gender(), request.dateOfBirth(), request.ageYears(),
                request.phone(), request.alternatePhone(), request.email(), request.address(), request.city(),
                request.state(), request.pincode(), request.bloodGroup(), request.emergencyContactName(),
                request.emergencyContactPhone(), context.accountId(), Instant.now());
        patients.flush();
        auditEvents.save(new SecurityAuditEvent("PATIENT_UPDATED", context.accountId(), Instant.now()));
        return PatientResponse.from(patient);
    }

    @Transactional
    public PatientResponse changeStatus(UUID patientUuid, PatientStatusRequest request,
                                        BearerTokenFilter.AuthPrincipal principal) {
        TenantContext context = requireContext(principal);
        requirePermission(PatientPermissionPolicy.canManageStatusOrArchive(context.membershipRole()));
        Patient patient = findScoped(patientUuid, context.hospitalUuid()).orElseThrow(this::notFound);
        if (patient.getVersion() != request.version()) {
            throw new PatientApiException(HttpStatus.CONFLICT, "Patient was changed by another update");
        }
        patient.changeStatus(request.status(), context.accountId(), Instant.now());
        patients.flush();
        auditEvents.save(new SecurityAuditEvent("PATIENT_STATUS_CHANGED", context.accountId(), Instant.now()));
        return PatientResponse.from(patient);
    }

    @Transactional
    public void archive(UUID patientUuid, BearerTokenFilter.AuthPrincipal principal) {
        TenantContext context = requireContext(principal);
        requirePermission(PatientPermissionPolicy.canManageStatusOrArchive(context.membershipRole()));
        Patient patient = findScoped(patientUuid, context.hospitalUuid()).orElseThrow(this::notFound);
        patient.archive(context.accountId(), Instant.now());
        patients.flush();
        auditEvents.save(new SecurityAuditEvent("PATIENT_ARCHIVED", context.accountId(), Instant.now()));
    }

    private TenantContext requireContext(BearerTokenFilter.AuthPrincipal principal) {
        TenantContext context = tenantContext.get();
        if (principal == null || context == null || principal.hospitalId() == null
                || context.accountId() != principal.userId()
                || context.hospitalId() != principal.hospitalId()) {
            throw new PatientApiException(HttpStatus.FORBIDDEN, "Active Hospital membership required");
        }
        return context;
    }

    private static void requirePermission(boolean allowed) {
        if (!allowed) throw new PatientApiException(HttpStatus.FORBIDDEN, "Patient operation is not permitted");
    }

    private java.util.Optional<Patient> findScoped(UUID uuid, UUID hospitalUuid) {
        return patients.findByUuidAndHospital_IdAndArchivedAtIsNull(uuid, hospitalUuid);
    }

    private PatientApiException notFound() {
        return new PatientApiException(HttpStatus.NOT_FOUND, "Patient not found");
    }

    private static UUID parseUuid(String query) {
        if (query == null) return null;
        try { return UUID.fromString(query); } catch (IllegalArgumentException invalid) { return null; }
    }

    private static boolean samePayload(Patient patient, PatientCreateRequest request) {
        return patient.getName().equals(request.name())
                && java.util.Objects.equals(patient.getGender(), request.gender())
                && java.util.Objects.equals(patient.getDateOfBirth(), request.dateOfBirth())
                && java.util.Objects.equals(patient.getAgeYears(), request.ageYears())
                && java.util.Objects.equals(patient.getPhone(), request.phone())
                && java.util.Objects.equals(patient.getAlternatePhone(), request.alternatePhone())
                && java.util.Objects.equals(patient.getEmail(), request.email())
                && java.util.Objects.equals(patient.getAddress(), request.address())
                && java.util.Objects.equals(patient.getCity(), request.city())
                && java.util.Objects.equals(patient.getState(), request.state())
                && java.util.Objects.equals(patient.getPincode(), request.pincode())
                && java.util.Objects.equals(patient.getBloodGroup(), request.bloodGroup())
                && java.util.Objects.equals(patient.getEmergencyContactName(), request.emergencyContactName())
                && java.util.Objects.equals(patient.getEmergencyContactPhone(), request.emergencyContactPhone());
    }
}
