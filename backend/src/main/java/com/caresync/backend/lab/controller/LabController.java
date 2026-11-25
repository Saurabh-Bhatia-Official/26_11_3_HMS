package com.caresync.backend.lab.controller;

import com.caresync.backend.lab.dto.LabDtos;
import com.caresync.backend.lab.service.LabService;
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

import java.util.List;

@RestController
@RequestMapping("/api/lab")
public class LabController {
    private final LabService service;

    public LabController(LabService service) { this.service = service; }

    @GetMapping("/tests")
    public List<LabDtos.TestResponse> tests() { return service.tests(); }

    @PostMapping("/tests")
    @ResponseStatus(HttpStatus.CREATED)
    public LabDtos.TestResponse createTest(@Valid @RequestBody LabDtos.TestRequest request) {
        return service.createTest(request);
    }

    @PutMapping("/tests/{id}")
    public LabDtos.TestResponse updateTest(@PathVariable long id, @Valid @RequestBody LabDtos.TestRequest request) {
        return service.updateTest(id, request);
    }

    @DeleteMapping("/tests/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteTest(@PathVariable long id) { service.deleteTest(id); }

    @GetMapping("/orders")
    public List<LabDtos.OrderResponse> orders(@RequestParam(required = false) String status) {
        return service.orders(status);
    }

    @PostMapping("/orders")
    @ResponseStatus(HttpStatus.CREATED)
    public LabDtos.OrderResponse createOrder(@Valid @RequestBody LabDtos.OrderRequest request) {
        return service.createOrder(request);
    }

    @PostMapping("/orders/{id}/collect")
    public LabDtos.OrderResponse collect(@PathVariable long id) { return service.collect(id); }

    @PostMapping("/orders/{id}/start")
    public LabDtos.OrderResponse startProcessing(@PathVariable long id) { return service.startProcessing(id); }

    @PostMapping("/orders/{id}/results")
    public LabDtos.OrderResponse enterResults(@PathVariable long id,
                                               @Valid @RequestBody LabDtos.ResultRequest request) {
        return service.enterResults(id, request);
    }

    @PostMapping("/orders/{id}/verify")
    public LabDtos.OrderResponse verify(@PathVariable long id) { return service.verify(id); }

    @PostMapping("/orders/{id}/deliver")
    public LabDtos.OrderResponse deliver(@PathVariable long id) { return service.deliver(id); }
}
