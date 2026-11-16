package com.caresync.backend.lab.service;

import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.lab.dto.LabDtos;
import com.caresync.backend.lab.entity.LabOrder;
import com.caresync.backend.lab.entity.LabResult;
import com.caresync.backend.lab.entity.LabTest;
import com.caresync.backend.lab.entity.LabTestParameter;
import com.caresync.backend.lab.repository.LabOrderRepository;
import com.caresync.backend.lab.repository.LabTestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@Transactional
public class LabService {
    private final AccessContext access;
    private final LabTestRepository tests;
    private final LabOrderRepository orders;

    public LabService(AccessContext access, LabTestRepository tests, LabOrderRepository orders) {
        this.access = access;
        this.tests = tests;
        this.orders = orders;
    }

    @Transactional(readOnly = true)
    public List<LabDtos.TestResponse> tests() {
        return tests.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(access.hospitalId())
                .stream().map(LabService::testResponse).toList();
    }

    public LabDtos.TestResponse createTest(LabDtos.TestRequest request) {
        LabTest test = new LabTest(access.hospitalId(), request.name().trim(), request.category(),
                request.sampleType(), request.pricePaise(), request.turnaroundHours(),
                Boolean.TRUE.equals(request.outsourced()));
        test.replaceParameters(parameters(request.parameters()));
        return testResponse(tests.save(test));
    }

    public LabDtos.TestResponse updateTest(long id, LabDtos.TestRequest request) {
        LabTest test = findTest(id);
        test.update(request.name().trim(), request.category(), request.sampleType(), request.pricePaise(),
                request.turnaroundHours(), Boolean.TRUE.equals(request.outsourced()));
        test.replaceParameters(parameters(request.parameters()));
        return testResponse(test);
    }

    public void deleteTest(long id) { findTest(id).markDeleted(); }

    @Transactional(readOnly = true)
    public List<LabDtos.OrderResponse> orders(String status) {
        return orders.findAllByHospitalIdAndDeletedFalseOrderByOrderedAtDesc(access.hospitalId()).stream()
                .filter(order -> status == null || status.isBlank() || order.getStatus().equals(status))
                .map(LabService::orderResponse).toList();
    }

    public LabDtos.OrderResponse createOrder(LabDtos.OrderRequest request) {
        LabTest test = findTest(request.testId());
        String number = "LAB-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
        LabOrder order = new LabOrder(access.hospitalId(), number, request.patientId(), request.patientName().trim(),
                request.uhid(), request.visitId(), request.doctorId(), request.doctorName(), test,
                request.priority() == null ? "routine" : request.priority(), request.notes());
        return orderResponse(orders.save(order));
    }

    public LabDtos.OrderResponse collect(long id) {
        LabOrder order = findOrderForUpdate(id);
        order.collect();
        return orderResponse(order);
    }

    public LabDtos.OrderResponse startProcessing(long id) {
        LabOrder order = findOrderForUpdate(id);
        order.startProcessing();
        return orderResponse(order);
    }

    public LabDtos.OrderResponse enterResults(long id, LabDtos.ResultRequest request) {
        LabOrder order = findOrderForUpdate(id);
        Set<String> names = new HashSet<>();
        for (LabDtos.ResultValueRequest result : request.results()) {
            if (!names.add(result.parameterName().trim().toLowerCase())) {
                throw BusinessException.invalid("Result parameter names must be unique");
            }
        }
        Set<String> required = order.getTest().getParameters().stream()
                .map(parameter -> parameter.getParameterName().trim().toLowerCase()).collect(java.util.stream.Collectors.toSet());
        if (!required.isEmpty() && !required.equals(names)) {
            throw BusinessException.invalid("Results must include each configured test parameter exactly once");
        }
        List<LabResult> results = request.results().stream()
                .map(result -> new LabResult(result.parameterName().trim(), result.value().trim(), result.unit(),
                        result.referenceRange(), result.abnormalFlag())).toList();
        order.enterResults(results, access.userId());
        orders.flush();
        return orderResponse(order);
    }

    public LabDtos.OrderResponse verify(long id) {
        LabOrder order = findOrderForUpdate(id);
        order.verify(access.userId());
        return orderResponse(order);
    }

    public LabDtos.OrderResponse deliver(long id) {
        LabOrder order = findOrderForUpdate(id);
        order.deliver();
        return orderResponse(order);
    }

    private List<LabTestParameter> parameters(List<LabDtos.ParameterRequest> requests) {
        if (requests == null) return List.of();
        Set<String> names = new HashSet<>();
        return requests.stream().map(parameter -> {
            String name = parameter.parameterName().trim();
            if (!names.add(name.toLowerCase())) throw BusinessException.invalid("Test parameter names must be unique");
            if (parameter.rangeLow() != null && parameter.rangeHigh() != null
                    && parameter.rangeLow() > parameter.rangeHigh()) {
                throw BusinessException.invalid("Parameter lower range cannot exceed its upper range");
            }
            return new LabTestParameter(name, parameter.unit(), parameter.rangeLow(), parameter.rangeHigh(),
                    parameter.referenceText());
        }).toList();
    }

    private LabTest findTest(long id) {
        return tests.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Lab test"));
    }

    private LabOrder findOrderForUpdate(long id) {
        return orders.findForUpdate(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Lab order"));
    }

    private static LabDtos.TestResponse testResponse(LabTest test) {
        List<LabDtos.ParameterResponse> parameters = test.getParameters().stream()
                .map(parameter -> new LabDtos.ParameterResponse(parameter.getId(), parameter.getParameterName(),
                        parameter.getUnit(), parameter.getRangeLow(), parameter.getRangeHigh(),
                        parameter.getReferenceText())).toList();
        return new LabDtos.TestResponse(test.getId(), test.getUuid(), test.getName(), test.getCategory(),
                test.getSampleType(), test.getPricePaise(), test.getTurnaroundHours(), test.isOutsourced(),
                test.getCreatedAt(), test.getUpdatedAt(), parameters);
    }

    private static LabDtos.OrderResponse orderResponse(LabOrder order) {
        List<LabDtos.ResultResponse> results = order.getResults().stream()
                .map(result -> new LabDtos.ResultResponse(result.getId(), result.getParameterName(),
                        result.getResultValue(), result.getUnit(), result.getReferenceRange(),
                        result.getAbnormalFlag())).toList();
        return new LabDtos.OrderResponse(order.getId(), order.getUuid(), order.getOrderNo(), order.getPatientId(),
                order.getPatientName(), order.getUhid(), order.getVisitId(), order.getDoctorId(),
                order.getDoctorName(), order.getTest().getId(), order.getTest().getName(),
                order.getTest().getSampleType(), order.getPriority(), order.getStatus(), order.getNotes(),
                order.getOrderedAt(), order.getSampleCollectedAt(), order.getResultedAt(), order.getVerifiedAt(),
                order.getEnteredBy(), order.getVerifiedBy(), results);
    }
}
