package com.caresync.backend.reference;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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

    @GetMapping("/admissions")
    public java.util.List<ReferenceDtos.AdmissionResponse> listAdmissions() {
        return service.listAdmissions();
    }

    @GetMapping("/admissions/{id}")
    public ReferenceDtos.AdmissionResponse getAdmission(@PathVariable long id) {
        return service.getAdmission(id);
    }

    @PostMapping("/admissions/{id}/discharge")
    public ReferenceDtos.AdmissionResponse dischargeAdmission(@PathVariable long id) {
        return service.dischargeAdmission(id);
    }

    @GetMapping("/admissions/beds")
    public java.util.List<ReferenceDtos.BedResponse> listBeds() {
        return service.listBeds();
    }

    @PostMapping("/admissions/beds")
    @ResponseStatus(HttpStatus.CREATED)
    public ReferenceDtos.BedResponse createBed(@Valid @RequestBody ReferenceDtos.BedRequest request) {
        return service.createBed(request);
    }

    @GetMapping("/admissions/beds/{id}")
    public ReferenceDtos.BedResponse getBed(@PathVariable long id) {
        return service.getBed(id);
    }

    @PutMapping("/admissions/beds/{id}")
    public ReferenceDtos.BedResponse updateBed(@PathVariable long id,
                                               @Valid @RequestBody ReferenceDtos.BedRequest request) {
        return service.updateBed(id, request);
    }

    @PostMapping("/admissions/beds/{id}/allocate")
    public ReferenceDtos.BedResponse allocateBed(@PathVariable long id,
                                                 @RequestBody ReferenceDtos.BedAllocationRequest request) {
        return service.allocateBed(id, request);
    }

    @PostMapping("/admissions/beds/{id}/release")
    public ReferenceDtos.BedResponse releaseBed(@PathVariable long id,
                                               @RequestParam(required = false, defaultValue = "available") String status) {
        return service.releaseBed(id, status);
    }

    @DeleteMapping("/admissions/beds/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteBed(@PathVariable long id) {
        service.deleteBed(id);
    }

    @PostMapping("/prescriptions")
    @ResponseStatus(HttpStatus.CREATED)
    public ReferenceDtos.PrescriptionResponse createPrescription(
            @Valid @RequestBody ReferenceDtos.PrescriptionRequest request) {
        return service.createPrescription(request);
    }
}
