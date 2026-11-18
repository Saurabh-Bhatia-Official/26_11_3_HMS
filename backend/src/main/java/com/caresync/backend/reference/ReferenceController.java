package com.caresync.backend.reference;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ReferenceController {
    private final ReferenceService service;

    public ReferenceController(ReferenceService service) { this.service = service; }

    @PostMapping("/visits")
    @ResponseStatus(HttpStatus.CREATED)
    public ReferenceDtos.VisitResponse createVisit(@Valid @RequestBody ReferenceDtos.VisitRequest request) {
        return service.createVisit(request);
    }

    @PostMapping("/admissions")
    @ResponseStatus(HttpStatus.CREATED)
    public ReferenceDtos.AdmissionResponse createAdmission(
            @Valid @RequestBody ReferenceDtos.AdmissionRequest request) {
        return service.createAdmission(request);
    }

    @PostMapping("/prescriptions")
    @ResponseStatus(HttpStatus.CREATED)
    public ReferenceDtos.PrescriptionResponse createPrescription(
            @Valid @RequestBody ReferenceDtos.PrescriptionRequest request) {
        return service.createPrescription(request);
    }
}
