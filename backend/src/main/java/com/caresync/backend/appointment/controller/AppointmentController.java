package com.caresync.backend.appointment.controller;

import com.caresync.backend.appointment.dto.AppointmentCreateRequest;
import com.caresync.backend.appointment.dto.AppointmentEventResponse;
import com.caresync.backend.appointment.dto.AppointmentResponse;
import com.caresync.backend.appointment.dto.AppointmentRescheduleRequest;
import com.caresync.backend.appointment.dto.AppointmentStatusRequest;
import com.caresync.backend.appointment.entity.AppointmentStatus;
import com.caresync.backend.appointment.service.AppointmentService;
import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.security.BearerTokenFilter;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.format.annotation.DateTimeFormat;
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

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@Validated
@RequestMapping("/api/v1/appointments")
public class AppointmentController {
    private final AppointmentService appointments;

    public AppointmentController(AppointmentService appointments) {
        this.appointments = appointments;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public AppointmentResponse create(@Valid @RequestBody AppointmentCreateRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return appointments.create(request, actor);
    }

    @GetMapping
    public PaginationResponse<AppointmentResponse> list(
            @RequestParam(required = false) UUID doctorUuid,
            @RequestParam(required = false) UUID patientUuid,
            @RequestParam(required = false) AppointmentStatus status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime until,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "20") @Min(1) @Max(100) int size,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return appointments.list(doctorUuid, patientUuid, status, from, until,
                new PaginationRequest(page, size), actor);
    }

    @GetMapping("/{appointmentUuid}")
    public AppointmentResponse get(@PathVariable UUID appointmentUuid,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return appointments.get(appointmentUuid, actor);
    }

    @GetMapping("/{appointmentUuid}/events")
    public List<AppointmentEventResponse> history(@PathVariable UUID appointmentUuid,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return appointments.history(appointmentUuid, actor);
    }

    @PostMapping("/{appointmentUuid}/reschedule")
    public AppointmentResponse reschedule(@PathVariable UUID appointmentUuid,
            @Valid @RequestBody AppointmentRescheduleRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return appointments.reschedule(appointmentUuid, request, actor);
    }

    @PatchMapping("/{appointmentUuid}/status")
    public AppointmentResponse changeStatus(@PathVariable UUID appointmentUuid,
            @Valid @RequestBody AppointmentStatusRequest request,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return appointments.changeStatus(appointmentUuid, request, actor);
    }

    @PostMapping("/{appointmentUuid}/cancel")
    public AppointmentResponse cancel(@PathVariable UUID appointmentUuid,
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return appointments.cancel(appointmentUuid, actor);
    }
}
