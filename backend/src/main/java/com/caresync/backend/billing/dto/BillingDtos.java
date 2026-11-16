package com.caresync.backend.billing.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Max;

import java.time.Instant;
import java.util.List;

public final class BillingDtos {
    private BillingDtos() {}

    public record ServiceRequest(@NotBlank @Size(max = 160) String name, @Size(max = 80) String category,
                                 @Min(0) @Max(1000000000000L) long pricePaise,
                                 @DecimalMin("0.0") @DecimalMax("100.0") double taxRatePct,
                                 Boolean active) {}
    public record ServiceResponse(long id, String uuid, String name, String category, long pricePaise,
                                  double taxRatePct, boolean active, Instant createdAt, Instant updatedAt) {}

    public record InvoiceItemRequest(
            @NotBlank @Pattern(regexp = "service|lab|medicine|room|procedure|other") String itemType,
            Long itemId,
            @NotBlank @Size(max = 240) String description,
            @Min(1) int qty,
            @Min(0) @Max(1000000000000L) long unitPricePaise,
            @Min(0) @Max(1000000000000L) long discountPaise,
            @DecimalMin("0.0") @DecimalMax("100.0") double taxRatePct) {}

    public record InvoiceRequest(
            @Min(1) long patientId,
            @NotBlank @Size(max = 200) String patientName,
            @Size(max = 32) String uhid,
            @NotBlank @Pattern(regexp = "opd|ipd|lab|pharmacy|counter|other") String invoiceType,
            Long visitId,
            Long admissionId,
            @Min(0) @Max(1000000000000L) long discountPaise,
            @Size(max = 300) String discountReason,
            @Size(max = 1000) String notes,
            @NotEmpty List<@Valid InvoiceItemRequest> items) {}

    public record PaymentRequest(
            @NotBlank @Pattern(regexp = "cash|card|upi|cheque|advance|insurance") String paymentMode,
            @Min(1) @Max(1000000000000L) long amountPaise,
            @Size(max = 100) String referenceNo) {}

    public record InvoiceItemResponse(long id, String itemType, Long itemId, String description, int qty,
                                      long unitPricePaise, long discountPaise, double taxRatePct, long totalPaise) {}
    public record PaymentResponse(long id, String paymentMode, long amountPaise, String referenceNo,
                                  long receivedBy, Instant paidAt) {}
    public record InvoiceResponse(long id, String uuid, String invoiceNo, long patientId, String patientName,
                                  String uhid, Long visitId, Long admissionId, String invoiceType,
                                  long subtotalPaise, long discountPaise, String discountReason, long taxPaise,
                                  long totalPaise, long paidPaise, long duePaise, String status, String notes,
                                  Instant createdAt, Instant updatedAt, List<InvoiceItemResponse> items,
                                  List<PaymentResponse> payments) {}
}
