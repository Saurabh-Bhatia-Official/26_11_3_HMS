package com.caresync.backend.lab.dto;

import jakarta.validation.Valid;
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

public final class LabDtos {
    private LabDtos() {}

    public record ParameterRequest(@NotBlank @Size(max = 160) String parameterName, @Size(max = 32) String unit,
                                   Double rangeLow, Double rangeHigh, @Size(max = 200) String referenceText) {}
    public record ParameterResponse(long id, String parameterName, String unit, Double rangeLow, Double rangeHigh,
                                    String referenceText) {}
    public record TestRequest(@NotBlank @Size(max = 180) String name, @Size(max = 100) String category,
                              @Size(max = 80) String sampleType, @Min(0) @Max(1000000000000L) long pricePaise,
                              @Min(1) @Max(8760) int turnaroundHours, Boolean outsourced,
                              List<@Valid ParameterRequest> parameters) {}
    public record TestResponse(long id, String uuid, String name, String category, String sampleType,
                               long pricePaise, int turnaroundHours, boolean outsourced, Instant createdAt,
                               Instant updatedAt, List<ParameterResponse> parameters) {}

    public record OrderRequest(@Min(1) long patientId, @NotBlank @Size(max = 200) String patientName,
                               @Size(max = 32) String uhid, Long visitId, Long doctorId,
                               @Size(max = 160) String doctorName, @Min(1) long testId,
                               @Pattern(regexp = "routine|urgent|stat") String priority,
                               @Size(max = 1000) String notes) {}
    public record ResultRequest(@NotEmpty List<@Valid ResultValueRequest> results) {}
    public record ResultValueRequest(@NotBlank @Size(max = 160) String parameterName,
                                     @NotBlank @Size(max = 500) String value, @Size(max = 32) String unit,
                                     @Size(max = 200) String referenceRange,
                                     @Pattern(regexp = "normal|low|high|critical_low|critical_high")
                                     String abnormalFlag) {}
    public record ResultResponse(long id, String parameterName, String value, String unit,
                                 String referenceRange, String abnormalFlag) {}
    public record OrderResponse(long id, String uuid, String orderNo, long patientId, String patientName,
                                String uhid, Long visitId, Long doctorId, String doctorName, long testId,
                                String testName, String sampleType, String priority, String status, String notes,
                                Instant orderedAt, Instant sampleCollectedAt, Instant resultedAt, Instant verifiedAt,
                                Long enteredBy, Long verifiedBy, List<ResultResponse> results) {}
}
