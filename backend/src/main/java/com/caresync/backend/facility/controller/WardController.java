
package com.caresync.backend.facility.controller;

import com.caresync.backend.facility.dto.WardRequest;
import com.caresync.backend.facility.dto.WardResponse;
import com.caresync.backend.facility.dto.WardStatusUpdateRequest;
import com.caresync.backend.facility.service.WardService;
import com.caresync.backend.security.BearerTokenFilter.AuthPrincipal;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/facilities/wards")
public class WardController {

    private final WardService wardService;

    public WardController(WardService wardService) {
        this.wardService = wardService;
    }

    @PostMapping
    public ResponseEntity<WardResponse> createWard(
            @AuthenticationPrincipal AuthPrincipal principal,
            @Valid @RequestBody WardRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(wardService.createWard(
                        getHospitalId(principal), request
                ));
    }

    @GetMapping
    public ResponseEntity<List<WardResponse>> getAllWards(
            @AuthenticationPrincipal AuthPrincipal principal
    ) {
        return ResponseEntity.ok(
                wardService.getAllWards(getHospitalId(principal))
        );
    }

    @GetMapping("/{wardId}")
    public ResponseEntity<WardResponse> getWardById(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long wardId
    ) {
        return ResponseEntity.ok(
                wardService.getWardById(
                        getHospitalId(principal), wardId
                )
        );
    }

    @PutMapping("/{wardId}")
    public ResponseEntity<WardResponse> updateWard(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long wardId,
            @Valid @RequestBody WardRequest request
    ) {
        return ResponseEntity.ok(
                wardService.updateWard(
                        getHospitalId(principal), wardId, request
                )
        );
    }

    @PatchMapping("/{wardId}/status")
    public ResponseEntity<WardResponse> updateWardStatus(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long wardId,
            @Valid @RequestBody WardStatusUpdateRequest request
    ) {
        return ResponseEntity.ok(
                wardService.updateWardStatus(
                        getHospitalId(principal),
                        wardId,
                        request.active()
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
