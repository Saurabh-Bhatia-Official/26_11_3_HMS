package com.caresync.backend.hospital.controller;

import com.caresync.backend.hospital.dto.HospitalApprovalResponse;
import com.caresync.backend.hospital.dto.HospitalLoginOption;
import com.caresync.backend.hospital.dto.HospitalRegistrationRequest;
import com.caresync.backend.hospital.dto.HospitalRegistrationReviewResponse;
import com.caresync.backend.hospital.dto.HospitalRegistrationSubmitted;
import com.caresync.backend.hospital.dto.HospitalProfileResponse;
import com.caresync.backend.hospital.dto.HospitalTimeZoneRequest;
import com.caresync.backend.hospital.service.HospitalManagementService;
import com.caresync.backend.security.BearerTokenFilter;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class HospitalController {
    private final HospitalManagementService hospitals;

    public HospitalController(HospitalManagementService hospitals) {
        this.hospitals = hospitals;
    }

    @PostMapping("/hospital-registrations")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public HospitalRegistrationSubmitted register(@Valid @RequestBody HospitalRegistrationRequest request) {
        return hospitals.submit(request);
    }

    @GetMapping("/platform/hospital-registrations")
    public List<HospitalRegistrationReviewResponse> pendingRegistrations(
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return hospitals.pendingRegistrations(principal);
    }

    @PostMapping("/platform/hospital-registrations/{registrationId}/approve")
    public HospitalApprovalResponse approve(@PathVariable UUID registrationId,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return hospitals.approve(registrationId, principal);
    }

    @PostMapping("/platform/hospital-registrations/{registrationId}/reject")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reject(@PathVariable UUID registrationId,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        hospitals.reject(registrationId, principal);
    }

    @GetMapping("/hospitals")
    public List<HospitalLoginOption> approvedHospitals() {
        return hospitals.approvedHospitals();
    }

    @GetMapping("/hospitals/me")
    public HospitalProfileResponse currentHospital(
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return hospitals.currentHospital(principal);
    }

    @PatchMapping("/hospitals/me/time-zone")
    public HospitalProfileResponse configureTimeZone(@Valid @RequestBody HospitalTimeZoneRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return hospitals.configureCurrentHospitalTimeZone(request, principal);
    }

    @GetMapping("/hospitals/lookup/{hospitalId}")
    public HospitalLoginOption lookup(@PathVariable String hospitalId) {
        if (hospitalId == null || !hospitalId.matches("[0-9]{12}")) {
            throw new com.caresync.backend.hospital.service.HospitalApiException(HttpStatus.NOT_FOUND, "Hospital not found");
        }
        return hospitals.findApprovedHospital(Long.parseLong(hospitalId));
    }
}
