
package com.caresync.backend.opd.controller;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.caresync.backend.opd.dto.OpdVisitRequest;
import com.caresync.backend.opd.dto.OpdVisitResponse;
import com.caresync.backend.opd.entity.OpdVisitStatus;
import com.caresync.backend.opd.service.OpdVisitService;
import com.caresync.backend.security.BearerTokenFilter.AuthPrincipal;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/opd/visits")
public class OpdVisitController {

    private final OpdVisitService opdVisitService;

    public OpdVisitController(OpdVisitService opdVisitService) {
        this.opdVisitService = opdVisitService;
    }

    // Create an OPD visit (appointment check-in or walk-in)
    @PostMapping
    public ResponseEntity<OpdVisitResponse> createVisit(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody OpdVisitRequest request
    ) {
        OpdVisitResponse response =
                opdVisitService.createVisit(request, principal);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    // Get the complete daily OPD queue
    @GetMapping("/queue")
    public ResponseEntity<List<OpdVisitResponse>> getDailyQueue(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(required = false) LocalDate date
    ) {
        return ResponseEntity.ok(
                opdVisitService.getDailyQueue(
                        getHospitalId(principal), date
                )
        );
    }

    // Get a doctor's daily OPD queue
    @GetMapping("/queue/doctor/{doctorId}")
    public ResponseEntity<List<OpdVisitResponse>> getDoctorQueue(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long doctorId,
            @RequestParam(required = false) LocalDate date
    ) {
        return ResponseEntity.ok(
                opdVisitService.getDoctorQueue(
                        getHospitalId(principal), doctorId, date
                )
        );
    }

    // Get OPD queue filtered by status
    @GetMapping("/queue/status")
    public ResponseEntity<List<OpdVisitResponse>> getQueueByStatus(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(required = false) LocalDate date,
            @RequestParam OpdVisitStatus status
    ) {
        return ResponseEntity.ok(
                opdVisitService.getQueueByStatus(
                        getHospitalId(principal), date, status
                )
        );
    }

    // Get a specific OPD visit
    @GetMapping("/{visitId}")
    public ResponseEntity<OpdVisitResponse> getVisitById(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long visitId
    ) {
        return ResponseEntity.ok(
                opdVisitService.getVisitById(
                        getHospitalId(principal), visitId
                )
        );
    }

    // Update OPD visit status
    @PatchMapping("/{visitId}/status")
public ResponseEntity<OpdVisitResponse> updateVisitStatus(
        @AuthenticationPrincipal AuthPrincipal principal,
        @PathVariable Long visitId,
        @RequestParam OpdVisitStatus status
) {
    return ResponseEntity.ok(
            opdVisitService.updateVisitStatus(
                    visitId,
                    status,
                    principal
            )
    );
}

    @GetMapping("/queue/doctor/by-uuid/{doctorUuid}")
public ResponseEntity<List<OpdVisitResponse>> getDoctorQueueByUuid(
        @AuthenticationPrincipal AuthPrincipal principal,
        @PathVariable UUID doctorUuid,
        @RequestParam(required = false) LocalDate date
) {
    return ResponseEntity.ok(
            opdVisitService.getDoctorQueueByUuid(
                    getHospitalId(principal),
                    doctorUuid,
                    date
            )
    );
}

    private Long getHospitalId(AuthPrincipal principal) {
        if (principal == null || principal.hospitalId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No hospital is associated with the authenticated user"
            );
        }

        return principal.hospitalId();
    }
}
