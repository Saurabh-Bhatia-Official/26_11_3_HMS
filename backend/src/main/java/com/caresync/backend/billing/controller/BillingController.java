package com.caresync.backend.billing.controller;

import com.caresync.backend.billing.dto.BillingDtos;
import com.caresync.backend.billing.service.BillingService;
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
@RequestMapping("/api/billing")
public class BillingController {
    private final BillingService service;

    public BillingController(BillingService service) { this.service = service; }

    @GetMapping("/services")
    public List<BillingDtos.ServiceResponse> services() { return service.services(); }

    @PostMapping("/services")
    @ResponseStatus(HttpStatus.CREATED)
    public BillingDtos.ServiceResponse createService(@Valid @RequestBody BillingDtos.ServiceRequest request) {
        return service.createService(request);
    }

    @PutMapping("/services/{id}")
    public BillingDtos.ServiceResponse updateService(@PathVariable long id,
                                                       @Valid @RequestBody BillingDtos.ServiceRequest request) {
        return service.updateService(id, request);
    }

    @GetMapping("/invoices")
    public List<BillingDtos.InvoiceResponse> invoices() { return service.invoices(); }

    @GetMapping("/invoices/{id}")
    public BillingDtos.InvoiceResponse invoice(@PathVariable long id) { return service.invoice(id); }

    @PostMapping("/invoices")
    @ResponseStatus(HttpStatus.CREATED)
    public BillingDtos.InvoiceResponse createInvoice(@Valid @RequestBody BillingDtos.InvoiceRequest request) {
        return service.createInvoice(request);
    }

    @PostMapping("/invoices/{id}/payments")
    public BillingDtos.InvoiceResponse addPayment(@PathVariable long id,
                                                   @Valid @RequestBody BillingDtos.PaymentRequest request) {
        return service.addPayment(id, request);
    }

    @DeleteMapping("/invoices/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cancelInvoice(@PathVariable long id) { service.cancelInvoice(id); }
}
