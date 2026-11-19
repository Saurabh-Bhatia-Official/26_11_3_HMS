package com.caresync.backend.department.service;

import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.department.dto.DepartmentCreateRequest;
import com.caresync.backend.department.dto.DepartmentResponse;
import com.caresync.backend.department.dto.DepartmentStatusRequest;
import com.caresync.backend.department.dto.DepartmentUpdateRequest;
import com.caresync.backend.department.entity.Department;
import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.MembershipRole;
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
import java.util.Locale;
import java.util.UUID;

@Service
public class DepartmentService {
    private final DepartmentRepository departments;
    private final HospitalRepository hospitals;
    private final TenantContextHolder tenantContext;
    private final SecurityAuditEventRepository auditEvents;

    public DepartmentService(DepartmentRepository departments, HospitalRepository hospitals,
                             TenantContextHolder tenantContext, SecurityAuditEventRepository auditEvents) {
        this.departments = departments;
        this.hospitals = hospitals;
        this.tenantContext = tenantContext;
        this.auditEvents = auditEvents;
    }

    @Transactional
    public DepartmentResponse create(DepartmentCreateRequest request, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdmin(tenant);
        String code = normalizeCode(request.code());
        if (departments.existsByHospital_IdAndCodeIgnoreCaseAndActiveTrue(tenant.hospitalUuid(), code)) {
            throw conflict();
        }
        Hospital hospital = hospitals.findById(tenant.hospitalUuid()).orElseThrow(this::unavailable);
        Instant now = Instant.now();
        Department department = new Department(UUID.randomUUID(), hospital, code, request.name(), request.description(), now);
        try {
            departments.saveAndFlush(department);
        } catch (DataIntegrityViolationException duplicate) {
            throw conflict();
        }
        auditEvents.save(new SecurityAuditEvent("DEPARTMENT_CREATED", tenant.accountId(), now));
        return DepartmentResponse.from(department);
    }

    @Transactional(readOnly = true)
    public PaginationResponse<DepartmentResponse> list(String query, Boolean active, PaginationRequest page,
                                                        BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireRead(tenant);
        String normalizedQuery = query == null || query.isBlank() ? "" : query.trim();
        Page<Department> result = departments.searchHospitalDepartments(tenant.hospitalUuid(), normalizedQuery,
                active, PageRequest.of(page.page(), page.size(), Sort.by(Sort.Order.asc("name"), Sort.Order.asc("id"))));
        List<DepartmentResponse> items = result.getContent().stream().map(DepartmentResponse::from).toList();
        return PaginationResponse.of(items, page, result.getTotalElements());
    }

    @Transactional(readOnly = true)
    public DepartmentResponse get(UUID id, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireRead(tenant);
        return findScoped(id, tenant.hospitalUuid()).map(DepartmentResponse::from)
                .orElseThrow(this::notFound);
    }

    @Transactional
    public DepartmentResponse update(UUID id, DepartmentUpdateRequest request,
                                     BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdmin(tenant);
        Department department = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        String code = normalizeCode(request.code());
        if (!department.getCode().equalsIgnoreCase(code)
                && departments.existsByHospital_IdAndCodeIgnoreCaseAndActiveTrue(tenant.hospitalUuid(), code)) {
            throw conflict();
        }
        department.update(code, request.name(), request.description(), Instant.now());
        try {
            departments.flush();
        } catch (DataIntegrityViolationException duplicate) {
            throw conflict();
        }
        auditEvents.save(new SecurityAuditEvent("DEPARTMENT_UPDATED", tenant.accountId(), Instant.now()));
        return DepartmentResponse.from(department);
    }

    @Transactional
    public DepartmentResponse changeStatus(UUID id, DepartmentStatusRequest request,
                                           BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdmin(tenant);
        Department department = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        department.setActive(request.active(), Instant.now());
        try {
            departments.flush();
        } catch (DataIntegrityViolationException duplicateOnActivation) {
            throw conflict();
        }
        auditEvents.save(new SecurityAuditEvent(request.active() ? "DEPARTMENT_ACTIVATED" : "DEPARTMENT_DEACTIVATED",
                tenant.accountId(), Instant.now()));
        return DepartmentResponse.from(department);
    }

    private java.util.Optional<Department> findScoped(UUID id, UUID hospitalId) {
        return departments.findByIdAndHospital_Id(id, hospitalId);
    }

    private TenantContext requireTenant(BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = tenantContext.get();
        if (actor == null || tenant == null || actor.hospitalId() == null
                || tenant.accountId() != actor.userId() || tenant.hospitalId() != actor.hospitalId()) {
            throw new DepartmentApiException(HttpStatus.FORBIDDEN, "Active Hospital membership required");
        }
        return tenant;
    }

    private static void requireAdmin(TenantContext tenant) {
        if (tenant.membershipRole() != MembershipRole.HOSPITAL_SUPER_ADMIN
                && tenant.membershipRole() != MembershipRole.ADMIN) {
            throw new DepartmentApiException(HttpStatus.FORBIDDEN, "Department management is not permitted");
        }
    }

    private static void requireRead(TenantContext tenant) {
        MembershipRole role = tenant.membershipRole();
        if (role != MembershipRole.HOSPITAL_SUPER_ADMIN && role != MembershipRole.ADMIN
                && role != MembershipRole.RECEPTIONIST && role != MembershipRole.DOCTOR
                && role != MembershipRole.NURSE) {
            throw new DepartmentApiException(HttpStatus.FORBIDDEN, "Department access is not permitted");
        }
    }

    private static String normalizeCode(String code) { return code.trim().toUpperCase(Locale.ROOT); }
    private DepartmentApiException notFound() { return new DepartmentApiException(HttpStatus.NOT_FOUND, "Department not found"); }
    private DepartmentApiException unavailable() { return new DepartmentApiException(HttpStatus.FORBIDDEN, "Hospital access is unavailable"); }
    private DepartmentApiException conflict() { return new DepartmentApiException(HttpStatus.CONFLICT, "An active Department already uses this code"); }
}
