package com.caresync.backend.patient.controller;

import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.patient.dto.PatientCreateRequest;
import com.caresync.backend.patient.dto.PatientResponse;
import com.caresync.backend.patient.dto.PatientStatusRequest;
import com.caresync.backend.patient.dto.PatientUpdateRequest;
import com.caresync.backend.patient.entity.PatientStatus;
import com.caresync.backend.patient.service.PatientService;
import com.caresync.backend.security.BearerTokenFilter;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@Validated
@RequestMapping("/api/v1/patients")
public class PatientController {
    private final PatientService patients;

    public PatientController(PatientService patients) { this.patients = patients; }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PatientResponse create(@Valid @RequestBody PatientCreateRequest request,
                                  @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return patients.create(request, principal);
    }

    @GetMapping
    public PaginationResponse<PatientResponse> list(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) PatientStatus status,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return patients.list(query, status, new PaginationRequest(page, size), principal);
    }

    @GetMapping("/{patientUuid}")
    public PatientResponse get(@PathVariable UUID patientUuid,
                               @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return patients.get(patientUuid, principal);
    }

    @PutMapping("/{patientUuid}")
    public PatientResponse update(@PathVariable UUID patientUuid,
                                  @Valid @RequestBody PatientUpdateRequest request,
                                  @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return patients.update(patientUuid, request, principal);
    }

    @PatchMapping("/{patientUuid}/status")
    public PatientResponse changeStatus(@PathVariable UUID patientUuid,
                                        @Valid @RequestBody PatientStatusRequest request,
                                        @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        return patients.changeStatus(patientUuid, request, principal);
    }

    @DeleteMapping("/{patientUuid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void archive(@PathVariable UUID patientUuid,
                        @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal principal) {
        patients.archive(patientUuid, principal);
    }
}
