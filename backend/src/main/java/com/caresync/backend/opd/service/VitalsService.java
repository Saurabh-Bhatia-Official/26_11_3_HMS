package com.caresync.backend.opd.service;

import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.opd.dto.VitalsRequest;
import com.caresync.backend.opd.dto.VitalsResponse;
import com.caresync.backend.opd.entity.OpdVisit;
import com.caresync.backend.opd.entity.Vitals;
import com.caresync.backend.opd.repository.OpdVisitRepository;
import com.caresync.backend.opd.repository.VitalsRepository;
import com.caresync.backend.security.BearerTokenFilter;
import com.caresync.backend.tenant.TenantContext;
import com.caresync.backend.tenant.TenantContextHolder;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Service
public class VitalsService {
    private final VitalsRepository vitalsRepository;
    private final OpdVisitRepository opdVisitRepository;
    private final DoctorProfileRepository doctorRepository;
    private final TenantContextHolder tenantContextHolder;

    public VitalsService(VitalsRepository vitalsRepository,
                         OpdVisitRepository opdVisitRepository,
                         DoctorProfileRepository doctorRepository,
                         TenantContextHolder tenantContextHolder) {
        this.vitalsRepository = vitalsRepository;
        this.opdVisitRepository = opdVisitRepository;
        this.doctorRepository = doctorRepository;
        this.tenantContextHolder = tenantContextHolder;
    }

    @Transactional
    public VitalsResponse create(Long visitId, VitalsRequest request,
                                 BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireClinicalAccess(actor);
        validateRequest(request);
        OpdVisit visit = findVisit(visitId, tenant.hospitalUuid());
        authorizeAssignedDoctor(visit, tenant);
        if (vitalsRepository.existsByVisitIdAndHospitalUuidAndDeletedFalse(
                visitId, tenant.hospitalUuid())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Vitals have already been recorded for this OPD visit");
        }
        Vitals vitals = new Vitals(visitId, tenant.hospitalUuid(), actor.userId(),
                request.bpSystolic(), request.bpDiastolic(), request.pulse(),
                request.temperatureC(), request.spo2(), request.weightKg(),
                request.heightCm(), request.notes());
        return toResponse(vitalsRepository.saveAndFlush(vitals));
    }

    @Transactional(readOnly = true)
    public VitalsResponse get(Long visitId, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireClinicalAccess(actor);
        findVisit(visitId, tenant.hospitalUuid());
        Vitals vitals = vitalsRepository
                .findByVisitIdAndHospitalUuidAndDeletedFalse(visitId, tenant.hospitalUuid())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Vitals not found for this OPD visit"));
        return toResponse(vitals);
    }

    @Transactional
    public VitalsResponse update(Long visitId, VitalsRequest request,
                                 BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireClinicalAccess(actor);
        validateRequest(request);
        OpdVisit visit = findVisit(visitId, tenant.hospitalUuid());
        authorizeAssignedDoctor(visit, tenant);
        Vitals vitals = vitalsRepository
                .findByVisitIdAndHospitalUuidAndDeletedFalse(visitId, tenant.hospitalUuid())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Vitals not found for this OPD visit"));
        vitals.update(request.bpSystolic(), request.bpDiastolic(), request.pulse(),
                request.temperatureC(), request.spo2(), request.weightKg(),
                request.heightCm(), request.notes());
        return toResponse(vitalsRepository.saveAndFlush(vitals));
    }

    private TenantContext requireClinicalAccess(BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = tenantContextHolder.get();
        if (actor == null || tenant == null || actor.hospitalId() == null
                || tenant.accountId() != actor.userId()
                || tenant.hospitalId() != actor.hospitalId()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Active Hospital membership required");
        }
        MembershipRole role = tenant.membershipRole();
        if (role != MembershipRole.HOSPITAL_SUPER_ADMIN
                && role != MembershipRole.ADMIN
                && role != MembershipRole.DOCTOR
                && role != MembershipRole.NURSE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Your Hospital role cannot access clinical vitals");
        }
        return tenant;
    }

    private OpdVisit findVisit(Long visitId, UUID hospitalUuid) {
        if (visitId == null || visitId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Valid visit ID is required");
        }
        return opdVisitRepository.findByIdAndHospitalUuid(visitId, hospitalUuid)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "OPD visit not found"));
    }

    private void authorizeAssignedDoctor(OpdVisit visit, TenantContext tenant) {
        if (tenant.membershipRole() != MembershipRole.DOCTOR) return;
        if (visit.getDoctorUuid() == null || !doctorRepository
                .findByIdAndHospital_Id(visit.getDoctorUuid(), tenant.hospitalUuid())
                .map(doctor -> doctor.getMembership().getAccount().getId() == tenant.accountId())
                .orElse(false)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "You are not assigned to this OPD visit");
        }
    }

    private void validateRequest(VitalsRequest request) {
        if (request == null || request.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "At least one vital measurement or note is required");
        }
        if ((request.bpSystolic() == null) != (request.bpDiastolic() == null)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Both systolic and diastolic blood pressure are required together");
        }
        if (request.bpSystolic() != null
                && request.bpSystolic() <= request.bpDiastolic()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Systolic blood pressure must be greater than diastolic pressure");
        }
    }

    private VitalsResponse toResponse(Vitals v) {
        return new VitalsResponse(v.getId(), v.getUuid(), v.getVisitId(),
                v.getBpSystolic(), v.getBpDiastolic(), v.getPulse(),
                v.getTemperatureC(), v.getSpo2(), v.getWeightKg(), v.getHeightCm(),
                v.getBmi(), v.getRecordedAt(), v.getRecordedBy(), v.getNotes());
    }
}
