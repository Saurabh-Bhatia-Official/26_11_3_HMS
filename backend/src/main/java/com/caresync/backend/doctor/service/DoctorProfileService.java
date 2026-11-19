package com.caresync.backend.doctor.service;

import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.department.entity.Department;
import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.doctor.dto.DoctorProfileCreateRequest;
import com.caresync.backend.doctor.dto.DoctorProfileResponse;
import com.caresync.backend.doctor.dto.DoctorProfileStatusRequest;
import com.caresync.backend.doctor.dto.DoctorProfileUpdateRequest;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.MembershipStatus;
import com.caresync.backend.membership.repository.HospitalMembershipRepository;
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
public class DoctorProfileService {
    private final DoctorProfileRepository doctors;
    private final HospitalMembershipRepository memberships;
    private final DepartmentRepository departments;
    private final HospitalRepository hospitals;
    private final TenantContextHolder tenantContext;
    private final SecurityAuditEventRepository auditEvents;

    public DoctorProfileService(DoctorProfileRepository doctors, HospitalMembershipRepository memberships,
                                DepartmentRepository departments, HospitalRepository hospitals,
                                TenantContextHolder tenantContext, SecurityAuditEventRepository auditEvents) {
        this.doctors = doctors;
        this.memberships = memberships;
        this.departments = departments;
        this.hospitals = hospitals;
        this.tenantContext = tenantContext;
        this.auditEvents = auditEvents;
    }

    @Transactional
    public DoctorProfileResponse create(DoctorProfileCreateRequest request,
                                        BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdministrator(tenant);
        HospitalMembership membership = memberships.findByIdAndHospital_Id(request.membershipId(), tenant.hospitalUuid())
                .filter(candidate -> candidate.getStatus() == MembershipStatus.ACTIVE)
                .filter(candidate -> candidate.getRole() == MembershipRole.DOCTOR)
                .filter(candidate -> candidate.getAccount().isActive())
                .filter(candidate -> candidate.getAccount().getRole().equals(MembershipRole.DOCTOR.name()))
                .orElseThrow(this::ineligibleMembership);
        if (doctors.existsByMembership_Id(membership.getId())) throw duplicateProfile();
        Department department = resolveDepartment(request.departmentId(), tenant.hospitalUuid());
        Hospital hospital = hospitals.findById(tenant.hospitalUuid())
                .filter(value -> value.getStatus() == HospitalStatus.APPROVED)
                .orElseThrow(this::unavailable);
        Instant now = Instant.now();
        DoctorProfile doctor = new DoctorProfile(UUID.randomUUID(), hospital, membership, department,
                request.specialization(), request.qualification(), request.registrationReference(), now);
        try {
            doctors.saveAndFlush(doctor);
        } catch (DataIntegrityViolationException duplicate) {
            throw duplicateProfile();
        }
        auditEvents.save(new SecurityAuditEvent("DOCTOR_PROFILE_CREATED", tenant.accountId(), now));
        return DoctorProfileResponse.from(doctor);
    }

    @Transactional(readOnly = true)
    public PaginationResponse<DoctorProfileResponse> list(String query, Boolean active,
                                                           PaginationRequest page,
                                                           BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireRead(tenant);
        PageRequest pageable = PageRequest.of(page.page(), page.size(),
                Sort.by(Sort.Order.asc("id")));
        Page<DoctorProfile> result;
        if (tenant.membershipRole() == MembershipRole.DOCTOR) {
            result = doctors.findAllByHospital_IdAndMembership_Account_Id(tenant.hospitalUuid(), tenant.accountId(), pageable);
        } else {
            String normalizedQuery = query == null || query.isBlank() ? "" : query.trim();
            result = doctors.searchHospitalDoctors(tenant.hospitalUuid(), normalizedQuery, active, pageable);
        }
        List<DoctorProfileResponse> items = result.getContent().stream().map(DoctorProfileResponse::from).toList();
        return PaginationResponse.of(items, page, result.getTotalElements());
    }

    @Transactional(readOnly = true)
    public DoctorProfileResponse get(UUID id, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireRead(tenant);
        DoctorProfile doctor = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        requireSelfOrAdministrator(doctor, tenant);
        return DoctorProfileResponse.from(doctor);
    }

    @Transactional
    public DoctorProfileResponse update(UUID id, DoctorProfileUpdateRequest request,
                                        BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdministrator(tenant);
        DoctorProfile doctor = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        Department department = resolveDepartment(request.departmentId(), tenant.hospitalUuid());
        doctor.update(department, request.specialization(), request.qualification(),
                request.registrationReference(), Instant.now());
        doctors.flush();
        auditEvents.save(new SecurityAuditEvent("DOCTOR_PROFILE_UPDATED", tenant.accountId(), Instant.now()));
        return DoctorProfileResponse.from(doctor);
    }

    @Transactional
    public DoctorProfileResponse changeStatus(UUID id, DoctorProfileStatusRequest request,
                                               BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdministrator(tenant);
        DoctorProfile doctor = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        doctor.setActive(request.active(), Instant.now());
        doctors.flush();
        auditEvents.save(new SecurityAuditEvent(request.active() ? "DOCTOR_PROFILE_ACTIVATED" : "DOCTOR_PROFILE_DEACTIVATED",
                tenant.accountId(), Instant.now()));
        return DoctorProfileResponse.from(doctor);
    }

    private Department resolveDepartment(UUID id, UUID hospitalId) {
        if (id == null) return null;
        return departments.findByIdAndHospital_IdAndActiveTrue(id, hospitalId)
                .orElseThrow(() -> new DoctorApiException(HttpStatus.CONFLICT,
                        "Department is unavailable in this Hospital"));
    }

    private java.util.Optional<DoctorProfile> findScoped(UUID id, UUID hospitalId) {
        return doctors.findByIdAndHospital_Id(id, hospitalId);
    }

    private TenantContext requireTenant(BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = tenantContext.get();
        if (actor == null || tenant == null || actor.hospitalId() == null
                || tenant.accountId() != actor.userId() || tenant.hospitalId() != actor.hospitalId()) {
            throw new DoctorApiException(HttpStatus.FORBIDDEN, "Active Hospital membership required");
        }
        return tenant;
    }

    private static void requireAdministrator(TenantContext tenant) {
        if (tenant.membershipRole() != MembershipRole.HOSPITAL_SUPER_ADMIN
                && tenant.membershipRole() != MembershipRole.ADMIN) {
            throw new DoctorApiException(HttpStatus.FORBIDDEN, "Doctor profile management is not permitted");
        }
    }

    private static void requireRead(TenantContext tenant) {
        MembershipRole role = tenant.membershipRole();
        if (role != MembershipRole.HOSPITAL_SUPER_ADMIN && role != MembershipRole.ADMIN
                && role != MembershipRole.RECEPTIONIST && role != MembershipRole.DOCTOR
                && role != MembershipRole.NURSE) {
            throw new DoctorApiException(HttpStatus.FORBIDDEN, "Doctor profile access is not permitted");
        }
    }

    private static void requireSelfOrAdministrator(DoctorProfile doctor, TenantContext tenant) {
        if (tenant.membershipRole() == MembershipRole.DOCTOR
                && doctor.getMembership().getAccount().getId() != tenant.accountId()) {
            throw new DoctorApiException(HttpStatus.NOT_FOUND, "Doctor profile not found");
        }
    }

    private DoctorApiException notFound() {
        return new DoctorApiException(HttpStatus.NOT_FOUND, "Doctor profile not found");
    }
    private DoctorApiException ineligibleMembership() {
        return new DoctorApiException(HttpStatus.CONFLICT, "An active DOCTOR membership is required");
    }
    private DoctorApiException duplicateProfile() {
        return new DoctorApiException(HttpStatus.CONFLICT, "A Doctor Profile already exists for this membership");
    }
    private DoctorApiException unavailable() {
        return new DoctorApiException(HttpStatus.FORBIDDEN, "Hospital access is unavailable");
    }
}
