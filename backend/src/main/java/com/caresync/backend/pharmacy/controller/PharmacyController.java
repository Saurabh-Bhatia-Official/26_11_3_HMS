package com.caresync.backend.pharmacy.controller;

import com.caresync.backend.pharmacy.dto.PharmacyDtos;
import com.caresync.backend.pharmacy.service.PharmacyService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/pharmacy")
public class PharmacyController {
    private final PharmacyService service;

    public PharmacyController(PharmacyService service) { this.service = service; }

    @GetMapping("/suppliers")
    public List<PharmacyDtos.SupplierResponse> suppliers() { return service.suppliers(); }

    @PostMapping("/suppliers")
    @ResponseStatus(HttpStatus.CREATED)
    public PharmacyDtos.SupplierResponse createSupplier(@Valid @RequestBody PharmacyDtos.SupplierRequest request) {
        return service.createSupplier(request);
    }

    @PutMapping("/suppliers/{id}")
    public PharmacyDtos.SupplierResponse updateSupplier(@PathVariable long id,
                                                         @Valid @RequestBody PharmacyDtos.SupplierRequest request) {
        return service.updateSupplier(id, request);
    }

    @GetMapping("/medicines")
    public List<PharmacyDtos.MedicineResponse> medicines() { return service.medicines(); }

    @PostMapping("/medicines")
    @ResponseStatus(HttpStatus.CREATED)
    public PharmacyDtos.MedicineResponse createMedicine(@Valid @RequestBody PharmacyDtos.MedicineRequest request) {
        return service.createMedicine(request);
    }

    @PutMapping("/medicines/{id}")
    public PharmacyDtos.MedicineResponse updateMedicine(@PathVariable long id,
                                                         @Valid @RequestBody PharmacyDtos.MedicineRequest request) {
        return service.updateMedicine(id, request);
    }

    @DeleteMapping("/medicines/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteMedicine(@PathVariable long id) { service.deleteMedicine(id); }

    @GetMapping("/medicines/{id}/batches")
    public List<PharmacyDtos.BatchResponse> batches(@PathVariable long id) { return service.batches(id); }

    @PostMapping("/stock/receive")
    @ResponseStatus(HttpStatus.CREATED)
    public PharmacyDtos.BatchResponse receive(@Valid @RequestBody PharmacyDtos.ReceiveStockRequest request) {
        return service.receive(request);
    }

    @PostMapping("/stock/adjustments")
    @ResponseStatus(HttpStatus.CREATED)
    public PharmacyDtos.AdjustmentResponse adjust(@Valid @RequestBody PharmacyDtos.AdjustmentRequest request) {
        return service.adjust(request);
    }

    @GetMapping("/stock/adjustments")
    public List<PharmacyDtos.AdjustmentResponse> adjustments() { return service.adjustments(); }

    @PostMapping("/dispensings")
    @ResponseStatus(HttpStatus.CREATED)
    public PharmacyDtos.DispensingResponse dispense(@Valid @RequestBody PharmacyDtos.DispenseRequest request) {
        return service.dispense(request);
    }

    @GetMapping("/dispensings")
    public List<PharmacyDtos.DispensingResponse> dispensings() { return service.dispensings(); }
}
