package com.caresync.backend.pharmacy.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Max;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class PharmacyDtos {
    private PharmacyDtos() {}

    public record SupplierRequest(@NotBlank @Size(max = 160) String name, @Size(max = 160) String contactPerson,
                                  @Size(max = 32) String phone, @Email @Size(max = 254) String email,
                                  @Size(max = 500) String address, @Size(max = 32) String gstNo) {}
    public record SupplierResponse(long id, String uuid, String name, String contactPerson, String phone,
                                   String email, String address, String gstNo, Instant createdAt, Instant updatedAt) {}

    public record MedicineRequest(@NotBlank @Size(max = 180) String name, @Size(max = 180) String genericName,
                                  @NotBlank @Pattern(regexp = "tablet|capsule|syrup|injection|cream|other")
                                  String form, @Size(max = 64) String strength, @Size(max = 160) String manufacturer,
                                  @Size(max = 100) String category, @Size(max = 32) String unit,
                                  @DecimalMin("0.0") @DecimalMax("100.0") double taxRatePct,
                                  @Min(0) @Max(10000000) int reorderLevel, @Size(max = 32) String hsnCode) {}
    public record MedicineResponse(long id, String uuid, String name, String genericName, String form,
                                   String strength, String manufacturer, String category, String unit,
                                   double taxRatePct, int reorderLevel, String hsnCode, int stockQty,
                                   Instant createdAt, Instant updatedAt) {}

    public record ReceiveStockRequest(@Min(1) long medicineId, @NotBlank @Size(max = 80) String batchNo,
                                      @NotNull LocalDate expiryDate, LocalDate manufactureDate,
                                      @Min(1) @Max(1000000) int quantity,
                                      @Min(0) @Max(1000000000000L) long purchasePricePaise,
                                      @Min(0) @Max(1000000000000L) long mrpPaise, Long supplierId) {}
    public record BatchResponse(long id, long medicineId, String medicineName, String batchNo,
                                LocalDate expiryDate, LocalDate manufactureDate, int quantityOnHand,
                                long purchasePricePaise, long mrpPaise, Long supplierId, Instant updatedAt) {}

    public record AdjustmentRequest(@Min(1) long batchId, @NotNull Integer adjustmentQuantity,
                                     @NotBlank @Size(max = 300) String reason) {}
    public record AdjustmentResponse(long id, long batchId, String medicineName, String batchNo,
                                     int adjustmentQuantity, String reason, long adjustedBy, Instant createdAt) {}

    public record DispensingItemRequest(@Min(1) long medicineId, @Min(1) @Max(1000000) int quantity) {}
    public record DispenseRequest(@Min(1) long patientId, Long prescriptionId, Long visitId,
                                  Boolean counterSale, @NotEmpty List<@Valid DispensingItemRequest> items) {}
    public record DispensingItemResponse(long medicineId, String medicineName, long batchId, String batchNo,
                                         int quantity, long unitPricePaise, double taxRatePct, long totalPaise) {}
    public record DispensingResponse(long id, long patientId, Long prescriptionId, Long visitId,
                                     long dispensedBy, boolean counterSale, long totalAmountPaise,
                                     Instant createdAt, List<DispensingItemResponse> items) {}
}
