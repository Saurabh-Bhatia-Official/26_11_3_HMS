package com.caresync.backend.department.controller;

import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.department.dto.DepartmentCreateRequest;
import com.caresync.backend.department.dto.DepartmentResponse;
import com.caresync.backend.department.dto.DepartmentStatusRequest;
import com.caresync.backend.department.dto.DepartmentUpdateRequest;
import com.caresync.backend.department.service.DepartmentService;
import com.caresync.backend.security.BearerTokenFilter;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@Validated
@RequestMapping("/api/v1/departments")
public class DepartmentController {
    private final DepartmentService departments;

    public DepartmentController(DepartmentService departments) { this.departments = departments; }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DepartmentResponse create(@Valid @RequestBody DepartmentCreateRequest request,
                                     @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return departments.create(request, actor);
    }

    @GetMapping
    public PaginationResponse<DepartmentResponse> list(@RequestParam(required = false) String query,
                                                        @RequestParam(required = false) Boolean active,
                                                        @RequestParam(defaultValue = "0") @Min(0) int page,
                                                        @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
                                                        @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return departments.list(query, active, new PaginationRequest(page, size), actor);
    }

    @GetMapping("/{departmentUuid}")
    public DepartmentResponse get(@PathVariable UUID departmentUuid,
                                  @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return departments.get(departmentUuid, actor);
    }

    @PutMapping("/{departmentUuid}")
    public DepartmentResponse update(@PathVariable UUID departmentUuid,
                                     @Valid @RequestBody DepartmentUpdateRequest request,
                                     @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return departments.update(departmentUuid, request, actor);
    }

    @PatchMapping("/{departmentUuid}/status")
    public DepartmentResponse changeStatus(@PathVariable UUID departmentUuid,
                                           @Valid @RequestBody DepartmentStatusRequest request,
                                           @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return departments.changeStatus(departmentUuid, request, actor);
    }
}
