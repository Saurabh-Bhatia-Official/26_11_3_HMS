package com.caresync.backend.doctor.service;

import com.caresync.backend.doctor.dto.DoctorAvailabilitySlotResponse;
import com.caresync.backend.doctor.dto.DoctorScheduleExceptionRequest;
import com.caresync.backend.doctor.dto.DoctorScheduleExceptionResponse;
import com.caresync.backend.doctor.dto.DoctorScheduleRequest;
import com.caresync.backend.doctor.dto.DoctorScheduleResponse;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.doctor.entity.DoctorSchedule;
import com.caresync.backend.doctor.entity.DoctorScheduleException;
import com.caresync.backend.doctor.entity.ScheduleExceptionType;
import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.doctor.repository.DoctorScheduleExceptionRepository;
import com.caresync.backend.doctor.repository.DoctorScheduleRepository;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.MembershipStatus;
import com.caresync.backend.security.BearerTokenFilter;
import com.caresync.backend.security.SecurityAuditEvent;
import com.caresync.backend.security.SecurityAuditEventRepository;
import com.caresync.backend.tenant.TenantContext;
import com.caresync.backend.tenant.TenantContextHolder;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DateTimeException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class DoctorSchedulingService {
    private final DoctorProfileRepository doctors;
    private final DoctorScheduleRepository schedules;
    private final DoctorScheduleExceptionRepository exceptions;
    private final TenantContextHolder tenantContext;
    private final SecurityAuditEventRepository auditEvents;

    public DoctorSchedulingService(DoctorProfileRepository doctors, DoctorScheduleRepository schedules,
                                   DoctorScheduleExceptionRepository exceptions, TenantContextHolder tenantContext,
                                   SecurityAuditEventRepository auditEvents) {
        this.doctors = doctors;
        this.schedules = schedules;
        this.exceptions = exceptions;
        this.tenantContext = tenantContext;
        this.auditEvents = auditEvents;
    }

    @Transactional
    public DoctorScheduleResponse createSchedule(UUID doctorId, DoctorScheduleRequest request,
                                                 BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdministrator(tenant);
        DoctorProfile doctor = lockDoctor(doctorId, tenant.hospitalUuid());
        requireEligibleDoctor(doctor);
        validateSchedule(request);
        ensureNoOverlappingSchedule(doctor, request, null);
        Instant now = Instant.now();
        DoctorSchedule schedule = new DoctorSchedule(UUID.randomUUID(), doctor.getHospital(), doctor,
                request.dayOfWeek(), request.startTime(), request.endTime(), request.slotMinutes(),
                request.effectiveFrom(), request.effectiveUntil(), now);
        try {
            schedules.saveAndFlush(schedule);
        } catch (DataIntegrityViolationException invalidSchedule) {
            throw new DoctorApiException(HttpStatus.CONFLICT, "Schedule conflicts with an existing interval");
        }
        auditEvents.save(new SecurityAuditEvent("DOCTOR_SCHEDULE_CREATED", tenant.accountId(), now));
        return DoctorScheduleResponse.from(schedule);
    }

    @Transactional(readOnly = true)
    public List<DoctorScheduleResponse> listSchedules(UUID doctorId,
                                                       BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        DoctorProfile doctor = findDoctor(doctorId, tenant.hospitalUuid());
        requireReadDoctor(doctor, tenant);
        return schedules.findAllByDoctor_IdAndHospital_IdOrderByDayOfWeekAscStartTimeAsc(doctorId, tenant.hospitalUuid())
                .stream().map(DoctorScheduleResponse::from).toList();
    }

    @Transactional
    public DoctorScheduleResponse updateSchedule(UUID doctorId, UUID scheduleId, DoctorScheduleRequest request,
                                                 BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdministrator(tenant);
        DoctorProfile doctor = lockDoctor(doctorId, tenant.hospitalUuid());
        requireEligibleDoctor(doctor);
        DoctorSchedule schedule = schedules.findByIdAndDoctor_IdAndHospital_Id(
                        scheduleId, doctorId, tenant.hospitalUuid())
                .orElseThrow(this::scheduleNotFound);
        validateSchedule(request);
        ensureNoOverlappingSchedule(doctor, request, scheduleId);
        schedule.update(request.dayOfWeek(), request.startTime(), request.endTime(), request.slotMinutes(),
                request.effectiveFrom(), request.effectiveUntil(), request.active(), Instant.now());
        try {
            schedules.flush();
        } catch (DataIntegrityViolationException invalidSchedule) {
            throw new DoctorApiException(HttpStatus.CONFLICT, "Schedule conflicts with an existing interval");
        }
        auditEvents.save(new SecurityAuditEvent("DOCTOR_SCHEDULE_UPDATED", tenant.accountId(), Instant.now()));
        return DoctorScheduleResponse.from(schedule);
    }

    @Transactional
    public DoctorScheduleExceptionResponse createException(UUID doctorId, DoctorScheduleExceptionRequest request,
                                                            BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdministrator(tenant);
        DoctorProfile doctor = lockDoctor(doctorId, tenant.hospitalUuid());
        requireEligibleDoctor(doctor);
        validateException(request);
        Instant now = Instant.now();
        DoctorScheduleException exception = new DoctorScheduleException(UUID.randomUUID(), doctor.getHospital(), doctor,
                request.date(), request.type(), request.startTime(), request.endTime(), request.reason(), now);
        exceptions.saveAndFlush(exception);
        auditEvents.save(new SecurityAuditEvent("DOCTOR_EXCEPTION_CREATED", tenant.accountId(), now));
        return DoctorScheduleExceptionResponse.from(exception);
    }

    @Transactional(readOnly = true)
    public List<DoctorScheduleExceptionResponse> listExceptions(UUID doctorId,
                                                                 BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        DoctorProfile doctor = findDoctor(doctorId, tenant.hospitalUuid());
        requireReadDoctor(doctor, tenant);
        return exceptions.findAllByDoctor_IdAndHospital_IdOrderByDateAscStartTimeAsc(doctorId, tenant.hospitalUuid())
                .stream().map(DoctorScheduleExceptionResponse::from).toList();
    }

    @Transactional
    public DoctorScheduleExceptionResponse updateException(UUID doctorId, UUID exceptionId,
            DoctorScheduleExceptionRequest request, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireAdministrator(tenant);
        DoctorProfile doctor = lockDoctor(doctorId, tenant.hospitalUuid());
        requireEligibleDoctor(doctor);
        DoctorScheduleException exception = exceptions.findByIdAndDoctor_IdAndHospital_Id(
                        exceptionId, doctorId, tenant.hospitalUuid())
                .orElseThrow(this::exceptionNotFound);
        validateException(request);
        exception.update(request.date(), request.type(), request.startTime(), request.endTime(),
                request.reason(), request.active(), Instant.now());
        exceptions.flush();
        auditEvents.save(new SecurityAuditEvent("DOCTOR_EXCEPTION_UPDATED", tenant.accountId(), Instant.now()));
        return DoctorScheduleExceptionResponse.from(exception);
    }

    @Transactional(readOnly = true)
    public List<DoctorAvailabilitySlotResponse> availability(UUID doctorId, LocalDate date,
            BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        DoctorProfile doctor = findDoctor(doctorId, tenant.hospitalUuid());
        requireReadDoctor(doctor, tenant);
        requireEligibleDoctor(doctor);
        ZoneId zone = hospitalZone(doctor.getHospital());
        if (date.isBefore(LocalDate.now(zone))) {
            throw new DoctorApiException(HttpStatus.BAD_REQUEST, "Availability date cannot be in the past");
        }
        int dayOfWeek = date.getDayOfWeek().getValue();
        List<DoctorSchedule> dailySchedules = schedules
                .findAllByDoctor_IdAndHospital_IdAndActiveTrueAndDayOfWeekAndEffectiveFromLessThanEqual(
                        doctorId, tenant.hospitalUuid(), dayOfWeek, date).stream()
                .filter(schedule -> schedule.getEffectiveUntil() == null || !schedule.getEffectiveUntil().isBefore(date))
                .toList();
        List<DoctorScheduleException> activeExceptions = exceptions
                .findAllByDoctor_IdAndHospital_IdAndDateAndActiveTrueOrderByStartTimeAsc(
                        doctorId, tenant.hospitalUuid(), date);
        if (activeExceptions.stream().anyMatch(exception -> exception.getType() == ScheduleExceptionType.LEAVE
                && exception.getStartTime() == null)) {
            return List.of();
        }
        List<DoctorAvailabilitySlotResponse> slots = new ArrayList<>();
        for (DoctorSchedule schedule : dailySchedules) {
            LocalTime start = schedule.getStartTime();
            while (!start.plusMinutes(schedule.getSlotMinutes()).isAfter(schedule.getEndTime())) {
                LocalTime end = start.plusMinutes(schedule.getSlotMinutes());
                if (!isExceptionBlocked(activeExceptions, start, end)) {
                    OffsetDateTime startsAt = resolveHospitalLocalTime(date, start, zone);
                    OffsetDateTime endsAt = resolveHospitalLocalTime(date, end, zone);
                    if (startsAt != null && endsAt != null) {
                        slots.add(new DoctorAvailabilitySlotResponse(start, end, startsAt, endsAt,
                                schedule.getSlotMinutes()));
                    }
                }
                start = end;
            }
        }
        return slots.stream().sorted(Comparator.comparing(DoctorAvailabilitySlotResponse::startsAt)).toList();
    }

    private DoctorProfile lockDoctor(UUID id, UUID hospitalId) {
        return doctors.findByIdAndHospital_IdForUpdate(id, hospitalId).orElseThrow(this::doctorNotFound);
    }

    private DoctorProfile findDoctor(UUID id, UUID hospitalId) {
        return doctors.findByIdAndHospital_Id(id, hospitalId).orElseThrow(this::doctorNotFound);
    }

    private void ensureNoOverlappingSchedule(DoctorProfile doctor, DoctorScheduleRequest request, UUID excludedId) {
        LocalDate newUntil = request.effectiveUntil() == null ? LocalDate.MAX : request.effectiveUntil();
        boolean overlap = schedules.findAllByDoctor_IdAndHospital_IdOrderByDayOfWeekAscStartTimeAsc(
                        doctor.getId(), doctor.getHospital().getId()).stream()
                .filter(DoctorSchedule::isActive)
                .filter(existing -> !existing.getId().equals(excludedId))
                .filter(existing -> existing.getDayOfWeek() == request.dayOfWeek())
                .filter(existing -> !existing.getEffectiveFrom().isAfter(newUntil)
                        && !request.effectiveFrom().isAfter(existing.getEffectiveUntil() == null
                                ? LocalDate.MAX : existing.getEffectiveUntil()))
                .anyMatch(existing -> request.startTime().isBefore(existing.getEndTime())
                        && existing.getStartTime().isBefore(request.endTime()));
        if (overlap) throw new DoctorApiException(HttpStatus.CONFLICT, "Schedule interval overlaps an active interval");
    }

    private static void validateSchedule(DoctorScheduleRequest request) {
        if (request.dayOfWeek() < 1 || request.dayOfWeek() > 7 || request.slotMinutes() <= 0
                || !request.startTime().isBefore(request.endTime())
                || (request.effectiveUntil() != null && request.effectiveUntil().isBefore(request.effectiveFrom()))
                || Duration.between(request.startTime(), request.endTime()).toMinutes() < request.slotMinutes()) {
            throw new DoctorApiException(HttpStatus.BAD_REQUEST, "Invalid Doctor Schedule interval");
        }
    }

    private static void validateException(DoctorScheduleExceptionRequest request) {
        boolean noTimes = request.startTime() == null && request.endTime() == null;
        boolean validInterval = request.startTime() != null && request.endTime() != null
                && request.startTime().isBefore(request.endTime());
        if (request.date() == null || request.type() == null
                || !(request.type() == ScheduleExceptionType.LEAVE && (noTimes || validInterval)
                    || request.type() == ScheduleExceptionType.BLOCKED && validInterval)) {
            throw new DoctorApiException(HttpStatus.BAD_REQUEST,
                    "A Schedule Exception must define a valid full-day leave or a time interval");
        }
    }

    private static boolean isExceptionBlocked(List<DoctorScheduleException> exceptions,
                                              LocalTime slotStart, LocalTime slotEnd) {
        return exceptions.stream().anyMatch(exception -> exception.getStartTime() == null
                || (slotStart.isBefore(exception.getEndTime()) && exception.getStartTime().isBefore(slotEnd)));
    }

    private static OffsetDateTime resolveHospitalLocalTime(LocalDate date, LocalTime time, ZoneId zone) {
        LocalDateTime local = LocalDateTime.of(date, time);
        List<ZoneOffset> offsets = zone.getRules().getValidOffsets(local);
        // Skip DST gaps and duplicated wall-clock times rather than silently changing their meaning.
        if (offsets.size() != 1) return null;
        return OffsetDateTime.of(local, offsets.getFirst());
    }

    private static ZoneId hospitalZone(Hospital hospital) {
        if (hospital.getTimeZone() == null || hospital.getTimeZone().isBlank()) {
            throw new DoctorApiException(HttpStatus.CONFLICT, "Hospital time zone must be configured before scheduling");
        }
        try {
            return ZoneId.of(hospital.getTimeZone());
        } catch (DateTimeException invalidZone) {
            throw new DoctorApiException(HttpStatus.CONFLICT, "Hospital time zone configuration is invalid");
        }
    }

    private static void requireEligibleDoctor(DoctorProfile doctor) {
        if (!doctor.isActive() || doctor.getMembership().getStatus() != MembershipStatus.ACTIVE
                || !doctor.getMembership().getAccount().isActive()
                || doctor.getMembership().getRole() != MembershipRole.DOCTOR
                || !MembershipRole.DOCTOR.name().equals(doctor.getMembership().getAccount().getRole())) {
            throw new DoctorApiException(HttpStatus.CONFLICT, "Doctor is not eligible for scheduling");
        }
    }

    private TenantContext requireTenant(BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = tenantContext.get();
        if (actor == null || tenant == null || actor.hospitalId() == null
                || tenant.accountId() != actor.userId() || tenant.hospitalId() != actor.hospitalId()) {
            throw new DoctorApiException(HttpStatus.FORBIDDEN, "Active Hospital membership required");
        }
        return tenant;
    }

    private static void requireAdministrator(TenantContext tenant) {
        if (tenant.membershipRole() != MembershipRole.HOSPITAL_SUPER_ADMIN
                && tenant.membershipRole() != MembershipRole.ADMIN) {
            throw new DoctorApiException(HttpStatus.FORBIDDEN, "Schedule management is not permitted");
        }
    }

    private static void requireReadDoctor(DoctorProfile doctor, TenantContext tenant) {
        MembershipRole role = tenant.membershipRole();
        if (role == MembershipRole.DOCTOR && doctor.getMembership().getAccount().getId() != tenant.accountId()) {
            throw new DoctorApiException(HttpStatus.NOT_FOUND, "Doctor profile not found");
        }
        if (role != MembershipRole.DOCTOR && role != MembershipRole.HOSPITAL_SUPER_ADMIN
                && role != MembershipRole.ADMIN && role != MembershipRole.RECEPTIONIST
                && role != MembershipRole.NURSE) {
            throw new DoctorApiException(HttpStatus.FORBIDDEN, "Schedule access is not permitted");
        }
    }

    private DoctorApiException doctorNotFound() { return new DoctorApiException(HttpStatus.NOT_FOUND, "Doctor profile not found"); }
    private DoctorApiException scheduleNotFound() { return new DoctorApiException(HttpStatus.NOT_FOUND, "Doctor Schedule not found"); }
    private DoctorApiException exceptionNotFound() { return new DoctorApiException(HttpStatus.NOT_FOUND, "Schedule Exception not found"); }
}
