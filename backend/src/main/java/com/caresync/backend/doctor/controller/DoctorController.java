package com.caresync.backend.doctor.controller;

import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.doctor.dto.DoctorProfileCreateRequest;
import com.caresync.backend.doctor.dto.DoctorProfileResponse;
import com.caresync.backend.doctor.dto.DoctorProfileStatusRequest;
import com.caresync.backend.doctor.dto.DoctorProfileUpdateRequest;
import com.caresync.backend.doctor.dto.DoctorAvailabilitySlotResponse;
import com.caresync.backend.doctor.dto.DoctorScheduleExceptionRequest;
import com.caresync.backend.doctor.dto.DoctorScheduleExceptionResponse;
import com.caresync.backend.doctor.dto.DoctorScheduleRequest;
import com.caresync.backend.doctor.dto.DoctorScheduleResponse;
import com.caresync.backend.doctor.service.DoctorSchedulingService;
import com.caresync.backend.doctor.service.DoctorProfileService;
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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.format.annotation.DateTimeFormat;

import java.util.UUID;
import java.time.LocalDate;
import java.util.List;

@RestController
@Validated
@RequestMapping("/api/v1/doctors")
public class DoctorController {
    private final DoctorProfileService doctors;
    private final DoctorSchedulingService schedules;

    public DoctorController(DoctorProfileService doctors, DoctorSchedulingService schedules) {
        this.doctors = doctors;
        this.schedules = schedules;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public DoctorProfileResponse create(@Valid @RequestBody DoctorProfileCreateRequest request,
                                        @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return doctors.create(request, actor);
    }

    @GetMapping
    public PaginationResponse<DoctorProfileResponse> list(@RequestParam(required = false) String query,
                                                           @RequestParam(required = false) Boolean active,
                                                           @RequestParam(defaultValue = "0") @Min(0) int page,
                                                           @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
                                                           @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return doctors.list(query, active, new PaginationRequest(page, size), actor);
    }

    @GetMapping("/{doctorUuid}")
    public DoctorProfileResponse get(@PathVariable UUID doctorUuid,
                                     @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return doctors.get(doctorUuid, actor);
    }

    @PatchMapping("/{doctorUuid}")
    public DoctorProfileResponse update(@PathVariable UUID doctorUuid,
                                        @Valid @RequestBody DoctorProfileUpdateRequest request,
                                        @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return doctors.update(doctorUuid, request, actor);
    }

    @PatchMapping("/{doctorUuid}/status")
    public DoctorProfileResponse changeStatus(@PathVariable UUID doctorUuid,
                                              @Valid @RequestBody DoctorProfileStatusRequest request,
                                              @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return doctors.changeStatus(doctorUuid, request, actor);
    }

    @PostMapping("/{doctorUuid}/schedules")
    @ResponseStatus(HttpStatus.CREATED)
    public DoctorScheduleResponse createSchedule(@PathVariable UUID doctorUuid,
            @Valid @RequestBody DoctorScheduleRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return schedules.createSchedule(doctorUuid, request, actor);
    }

    @GetMapping("/{doctorUuid}/schedules")
    public List<DoctorScheduleResponse> listSchedules(@PathVariable UUID doctorUuid,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return schedules.listSchedules(doctorUuid, actor);
    }

    @PatchMapping("/{doctorUuid}/schedules/{scheduleId}")
    public DoctorScheduleResponse updateSchedule(@PathVariable UUID doctorUuid, @PathVariable UUID scheduleId,
            @Valid @RequestBody DoctorScheduleRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return schedules.updateSchedule(doctorUuid, scheduleId, request, actor);
    }

    @PostMapping("/{doctorUuid}/schedule-exceptions")
    @ResponseStatus(HttpStatus.CREATED)
    public DoctorScheduleExceptionResponse createException(@PathVariable UUID doctorUuid,
            @Valid @RequestBody DoctorScheduleExceptionRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return schedules.createException(doctorUuid, request, actor);
    }

    @GetMapping("/{doctorUuid}/schedule-exceptions")
    public List<DoctorScheduleExceptionResponse> listExceptions(@PathVariable UUID doctorUuid,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return schedules.listExceptions(doctorUuid, actor);
    }

    @PatchMapping("/{doctorUuid}/schedule-exceptions/{exceptionId}")
    public DoctorScheduleExceptionResponse updateException(@PathVariable UUID doctorUuid,
            @PathVariable UUID exceptionId, @Valid @RequestBody DoctorScheduleExceptionRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return schedules.updateException(doctorUuid, exceptionId, request, actor);
    }

    @GetMapping("/{doctorUuid}/availability")
    public List<DoctorAvailabilitySlotResponse> availability(@PathVariable UUID doctorUuid,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return schedules.availability(doctorUuid, date, actor);
    }
}
