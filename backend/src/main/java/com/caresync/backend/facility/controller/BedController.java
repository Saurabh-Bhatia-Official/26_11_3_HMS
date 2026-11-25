package com.caresync.backend.facility.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.caresync.backend.facility.dto.BedRequest;
import com.caresync.backend.facility.dto.BedResponse;
import com.caresync.backend.facility.dto.BedStatusUpdateRequest;
import com.caresync.backend.facility.entity.BedStatus;
import com.caresync.backend.facility.service.BedService;
import com.caresync.backend.security.BearerTokenFilter.AuthPrincipal;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/facilities/beds")
public class BedController {

    private final BedService bedService;

    public BedController(BedService bedService) {
        this.bedService = bedService;
    }

    @PostMapping
    public ResponseEntity<BedResponse> createBed(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody BedRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(bedService.createBed(getHospitalId(principal), request));
    }

    @GetMapping
    public ResponseEntity<List<BedResponse>> getAllBeds(
            @AuthenticationPrincipal AuthPrincipal principal,
            @RequestParam(required = false) Long wardId,
            @RequestParam(required = false) Long roomId,
            @RequestParam(required = false) BedStatus status
    ) {
        return ResponseEntity.ok(
                bedService.getAllBeds(
                        getHospitalId(principal), wardId, roomId, status
                )
        );
    }

    @GetMapping("/{bedId}")
    public ResponseEntity<BedResponse> getBedById(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long bedId
    ) {
        return ResponseEntity.ok(
                bedService.getBedById(getHospitalId(principal), bedId)
        );
    }

    @PutMapping("/{bedId}")
    public ResponseEntity<BedResponse> updateBed(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long bedId,
            @Valid @RequestBody BedRequest request
    ) {
        return ResponseEntity.ok(
                bedService.updateBed(
                        getHospitalId(principal), bedId, request
                )
        );
    }

    @PatchMapping("/{bedId}/status")
    public ResponseEntity<BedResponse> updateBedStatus(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long bedId,
            @Valid @RequestBody BedStatusUpdateRequest request
    ) {
        return ResponseEntity.ok(
                bedService.updateBedStatus(
                        getHospitalId(principal), bedId, request.status()
                )
        );
    }

    private Long getHospitalId(AuthPrincipal principal) {
        if (principal == null || principal.hospitalId() == null) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No hospital is associated with the authenticated user"
            );
        }

        return principal.hospitalId();
    }
}