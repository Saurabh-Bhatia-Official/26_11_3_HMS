package com.caresync.backend.staff.controller;

import com.caresync.backend.staff.dto.StaffDtos;
import com.caresync.backend.staff.service.StaffService;
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
@RequestMapping("/api/staff")
public class StaffController {
    private final StaffService service;

    public StaffController(StaffService service) { this.service = service; }

    @GetMapping("/departments")
    public List<StaffDtos.DepartmentResponse> departments() { return service.departments(); }

    @PostMapping("/departments")
    @ResponseStatus(HttpStatus.CREATED)
    public StaffDtos.DepartmentResponse createDepartment(@Valid @RequestBody StaffDtos.DepartmentRequest request) {
        return service.createDepartment(request);
    }

    @PutMapping("/departments/{id}")
    public StaffDtos.DepartmentResponse updateDepartment(@PathVariable long id,
                                                           @Valid @RequestBody StaffDtos.DepartmentRequest request) {
        return service.updateDepartment(id, request);
    }

    @DeleteMapping("/departments/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteDepartment(@PathVariable long id) { service.deleteDepartment(id); }

    @GetMapping
    public List<StaffDtos.StaffResponse> list(@RequestParam(required = false) String role) {
        return service.list(role);
    }

    @GetMapping("/{id}")
    public StaffDtos.StaffResponse get(@PathVariable long id) { return service.get(id); }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StaffDtos.StaffResponse create(@Valid @RequestBody StaffDtos.StaffRequest request) {
        return service.create(request);
    }

    @PutMapping("/{id}")
    public StaffDtos.StaffResponse update(@PathVariable long id, @Valid @RequestBody StaffDtos.StaffRequest request) {
        return service.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable long id) { service.delete(id); }
}
