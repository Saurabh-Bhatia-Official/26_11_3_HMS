package com.caresync.backend.opd.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.caresync.backend.opd.dto.VitalsRequest;
import com.caresync.backend.opd.dto.VitalsResponse;
import com.caresync.backend.opd.service.VitalsService;
import com.caresync.backend.security.BearerTokenFilter.AuthPrincipal;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/opd/visits/{visitId}/vitals")
public class VitalsController {
    private final VitalsService vitalsService;

    public VitalsController(VitalsService vitalsService) {
        this.vitalsService = vitalsService;
    }

    @PostMapping
    public ResponseEntity<VitalsResponse> create(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long visitId,
            @Valid @RequestBody VitalsRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(vitalsService.create(visitId, request, principal));
    }

    @GetMapping
    public ResponseEntity<VitalsResponse> get(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long visitId) {
        return ResponseEntity.ok(vitalsService.get(visitId, principal));
    }

    @PutMapping
    public ResponseEntity<VitalsResponse> update(
            @AuthenticationPrincipal AuthPrincipal principal,
            @PathVariable Long visitId,
            @Valid @RequestBody VitalsRequest request) {
        return ResponseEntity.ok(vitalsService.update(visitId, request, principal));
    }
}
