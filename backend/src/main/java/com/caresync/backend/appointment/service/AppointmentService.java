package com.caresync.backend.appointment.service;

import com.caresync.backend.appointment.dto.AppointmentCreateRequest;
import com.caresync.backend.appointment.dto.AppointmentEventResponse;
import com.caresync.backend.appointment.dto.AppointmentResponse;
import com.caresync.backend.appointment.dto.AppointmentRescheduleRequest;
import com.caresync.backend.appointment.entity.Appointment;
import com.caresync.backend.appointment.entity.AppointmentEvent;
import com.caresync.backend.appointment.entity.AppointmentStatus;
import com.caresync.backend.appointment.repository.AppointmentEventRepository;
import com.caresync.backend.appointment.repository.AppointmentRepository;
import com.caresync.backend.appointment.dto.AppointmentStatusRequest;
import com.caresync.backend.common.dto.PaginationRequest;
import com.caresync.backend.common.dto.PaginationResponse;
import com.caresync.backend.department.entity.Department;
import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.doctor.dto.DoctorAvailabilitySlotResponse;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.doctor.service.DoctorSchedulingService;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.MembershipStatus;
import com.caresync.backend.membership.repository.HospitalMembershipRepository;
import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.patient.entity.PatientStatus;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.security.BearerTokenFilter;
import com.caresync.backend.tenant.TenantContext;
import com.caresync.backend.tenant.TenantContextHolder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

@Service
public class AppointmentService {
    private static final UUID NO_UUID_FILTER = new UUID(0L, 0L);
    private static final OffsetDateTime EARLIEST_FILTER = OffsetDateTime.parse("0001-01-01T00:00:00Z");
    private static final OffsetDateTime LATEST_FILTER = OffsetDateTime.parse("9999-12-31T23:59:59Z");
    private final AppointmentRepository appointments;
    private final AppointmentEventRepository events;
    private final DoctorProfileRepository doctors;
    private final PatientRepository patients;
    private final DepartmentRepository departments;
    private final HospitalMembershipRepository memberships;
    private final TenantContextHolder tenantContext;
    private final DoctorSchedulingService scheduling;

    public AppointmentService(AppointmentRepository appointments, AppointmentEventRepository events,
            DoctorProfileRepository doctors, PatientRepository patients, DepartmentRepository departments,
            HospitalMembershipRepository memberships, TenantContextHolder tenantContext,
            DoctorSchedulingService scheduling) {
        this.appointments = appointments;
        this.events = events;
        this.doctors = doctors;
        this.patients = patients;
        this.departments = departments;
        this.memberships = memberships;
        this.tenantContext = tenantContext;
        this.scheduling = scheduling;
    }

    @Transactional
    public AppointmentResponse create(AppointmentCreateRequest request, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireCreatePermission(tenant.membershipRole());
        DoctorProfile doctor = doctors.findByIdAndHospital_IdForUpdate(request.doctorUuid(), tenant.hospitalUuid())
                .orElseThrow(this::notFound);
        requireEligibleDoctor(doctor);
        Patient patient = patients.findByUuidAndHospital_IdAndArchivedAtIsNull(request.patientUuid(), tenant.hospitalUuid())
                .filter(value -> value.getStatus() == PatientStatus.ACTIVE).orElseThrow(this::patientUnavailable);
        Department department = resolveDepartment(request.departmentUuid(), doctor, tenant.hospitalUuid());
        HospitalMembership creator = currentMembership(tenant);
        BookingSlot slot = resolveSlot(doctor, request.startsAt(), actor, tenant.hospitalUuid());
        ensureNoOverlap(doctor, slot.start(), slot.end(), null, tenant.hospitalUuid());
        Instant now = Instant.now();
        Appointment appointment = new Appointment(UUID.randomUUID(), doctor.getHospital(), patient, doctor, department,
                creator, slot.start(), slot.end(), request.appointmentType(), request.reason(), request.notes(), now);
        appointments.saveAndFlush(appointment);
        events.save(event(appointment, tenant, creator, "CREATED", null, AppointmentStatus.SCHEDULED,
                null, null, slot.start(), slot.end(), now));
        return AppointmentResponse.from(appointment);
    }

    @Transactional(readOnly = true)
    public PaginationResponse<AppointmentResponse> list(UUID doctorId, UUID patientUuid, AppointmentStatus status,
            OffsetDateTime fromTime, OffsetDateTime untilTime, PaginationRequest page,
            BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireReadPermission(tenant.membershipRole());
        if (fromTime != null && untilTime != null && !fromTime.isBefore(untilTime)) {
            throw new AppointmentApiException(HttpStatus.BAD_REQUEST, "Invalid appointment date range");
        }
        UUID scopedDoctor = tenant.membershipRole() == MembershipRole.DOCTOR
                ? ownDoctorId(tenant) : doctorId;
        Page<Appointment> result = appointments.searchHospitalAppointments(tenant.hospitalUuid(), scopedDoctor != null,
                scopedDoctor == null ? NO_UUID_FILTER : scopedDoctor, patientUuid != null,
                patientUuid == null ? NO_UUID_FILTER : patientUuid, status != null,
                status == null ? AppointmentStatus.SCHEDULED : status, fromTime != null,
                fromTime == null ? EARLIEST_FILTER : fromTime, untilTime != null,
                untilTime == null ? LATEST_FILTER : untilTime,
                PageRequest.of(page.page(), page.size(), Sort.by(Sort.Order.asc("startsAt"), Sort.Order.asc("id"))));
        List<AppointmentResponse> items = result.getContent().stream().map(AppointmentResponse::from).toList();
        return PaginationResponse.of(items, page, result.getTotalElements());
    }

    @Transactional(readOnly = true)
    public AppointmentResponse get(UUID id, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireReadPermission(tenant.membershipRole());
        Appointment appointment = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        requireOwnDoctorRecord(appointment, tenant);
        return AppointmentResponse.from(appointment);
    }

    @Transactional(readOnly = true)
    public List<AppointmentEventResponse> history(UUID id, BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireReadPermission(tenant.membershipRole());
        Appointment appointment = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        requireOwnDoctorRecord(appointment, tenant);
        return events.findAllByAppointment_IdAndHospitalUuidOrderByOccurredAtAsc(id, tenant.hospitalUuid())
                .stream().map(AppointmentEventResponse::from).toList();
    }

    @Transactional
    public AppointmentResponse reschedule(UUID id, AppointmentRescheduleRequest request,
                                           BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        requireCreatePermission(tenant.membershipRole());
        Appointment appointment = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        if (appointment.getStatus() != AppointmentStatus.SCHEDULED
                && appointment.getStatus() != AppointmentStatus.CONFIRMED) {
            throw invalidTransition();
        }
        DoctorProfile doctor = doctors.findByIdAndHospital_IdForUpdate(
                appointment.getDoctor().getId(), tenant.hospitalUuid()).orElseThrow(this::notFound);
        requireEligibleDoctor(doctor);
        BookingSlot slot = resolveSlot(doctor, request.startsAt(), actor, tenant.hospitalUuid());
        ensureNoOverlap(doctor, slot.start(), slot.end(), id, tenant.hospitalUuid());
        Instant now = Instant.now();
        OffsetDateTime oldStart = appointment.getStartsAt();
        OffsetDateTime oldEnd = appointment.getEndsAt();
        appointment.reschedule(slot.start(), slot.end(), now);
        appointments.flush();
        HospitalMembership current = currentMembership(tenant);
        events.save(event(appointment, tenant, current, "RESCHEDULED", appointment.getStatus(),
                appointment.getStatus(), oldStart, oldEnd, slot.start(), slot.end(), now));
        return AppointmentResponse.from(appointment);
    }

    @Transactional
    public AppointmentResponse changeStatus(UUID id, AppointmentStatusRequest request,
                                             BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = requireTenant(actor);
        Appointment appointment = findScoped(id, tenant.hospitalUuid()).orElseThrow(this::notFound);
        requireOwnDoctorRecord(appointment, tenant);
        AppointmentStatus previous = appointment.getStatus();
        AppointmentStatus next = request.status();
        authorizeTransition(appointment, tenant, previous, next);
        HospitalMembership current = currentMembership(tenant);
        Instant now = Instant.now();
        appointment.transition(next, now);
        appointments.flush();
        events.save(event(appointment, tenant, current, "STATUS_CHANGED", previous, next,
                appointment.getStartsAt(), appointment.getEndsAt(), appointment.getStartsAt(), appointment.getEndsAt(), now));
        return AppointmentResponse.from(appointment);
    }

    @Transactional
    public AppointmentResponse cancel(UUID id, BearerTokenFilter.AuthPrincipal actor) {
        return changeStatus(id, new AppointmentStatusRequest(AppointmentStatus.CANCELLED), actor);
    }

    private BookingSlot resolveSlot(DoctorProfile doctor, OffsetDateTime requestedStart,
                                    BearerTokenFilter.AuthPrincipal actor, UUID hospitalUuid) {
        if (doctor.getHospital().getTimeZone() == null || doctor.getHospital().getTimeZone().isBlank()) {
            throw new AppointmentApiException(HttpStatus.CONFLICT,
                    "Hospital time zone must be configured before scheduling");
        }
        ZoneId zone = ZoneId.of(doctor.getHospital().getTimeZone());
        if (!requestedStart.toInstant().isAfter(Instant.now())) {
            throw new AppointmentApiException(HttpStatus.BAD_REQUEST, "Appointments must be scheduled in the future");
        }
        List<DoctorAvailabilitySlotResponse> available = scheduling.availability(
                doctor.getId(), requestedStart.toInstant().atZone(zone).toLocalDate(), actor);
        DoctorAvailabilitySlotResponse selected = available.stream()
                .filter(slot -> slot.startsAt().toInstant().equals(requestedStart.toInstant()))
                .findFirst().orElseThrow(() -> new AppointmentApiException(HttpStatus.CONFLICT,
                        "Requested start time is not an available Doctor Schedule slot"));
        return new BookingSlot(selected.startsAt(), selected.endsAt());
    }

    private void ensureNoOverlap(DoctorProfile doctor, OffsetDateTime start, OffsetDateTime end,
                                 UUID excludedId, UUID hospitalUuid) {
        if (appointments.existsOverlappingDoctorAppointment(hospitalUuid, doctor.getId(), start, end,
                AppointmentStatus.CANCELLED, excludedId)) {
            throw new AppointmentApiException(HttpStatus.CONFLICT, "Doctor already has an appointment in this time slot");
        }
    }

    private Department resolveDepartment(UUID requestedId, DoctorProfile doctor, UUID hospitalUuid) {
        UUID selectedId = requestedId != null ? requestedId
                : doctor.getDepartment() == null ? null : doctor.getDepartment().getId();
        if (selectedId == null) return null;
        Department selected = departments.findByIdAndHospital_IdAndActiveTrue(selectedId, hospitalUuid)
                .orElseThrow(() -> new AppointmentApiException(HttpStatus.CONFLICT,
                        "Department is unavailable in this Hospital"));
        if (doctor.getDepartment() != null && !doctor.getDepartment().getId().equals(selected.getId())) {
            throw new AppointmentApiException(HttpStatus.CONFLICT,
                    "Appointment Department must match the Doctor Profile Department");
        }
        return selected;
    }

    private void authorizeTransition(Appointment appointment, TenantContext tenant,
                                     AppointmentStatus previous, AppointmentStatus next) {
        MembershipRole role = tenant.membershipRole();
        boolean admin = role == MembershipRole.HOSPITAL_SUPER_ADMIN || role == MembershipRole.ADMIN;
        boolean receptionist = role == MembershipRole.RECEPTIONIST;
        boolean assignedDoctor = role == MembershipRole.DOCTOR
                && appointment.getDoctor().getMembership().getAccount().getId() == tenant.accountId();
        boolean allowed = switch (previous) {
            case SCHEDULED -> (admin || receptionist) && (next == AppointmentStatus.CONFIRMED || next == AppointmentStatus.CANCELLED);
            case CONFIRMED -> (admin || receptionist) && (next == AppointmentStatus.CHECKED_IN
                    || next == AppointmentStatus.CANCELLED || next == AppointmentStatus.NO_SHOW);
            case CHECKED_IN -> (admin || assignedDoctor) && next == AppointmentStatus.IN_PROGRESS;
            case IN_PROGRESS -> (admin || assignedDoctor) && next == AppointmentStatus.COMPLETED;
            case COMPLETED, CANCELLED, NO_SHOW -> false;
        };
        if (!allowed) {
            if (!admin && !receptionist && !assignedDoctor) {
                throw new AppointmentApiException(HttpStatus.FORBIDDEN, "Appointment status change is not permitted");
            }
            throw invalidTransition();
        }
    }

    private void requireCreatePermission(MembershipRole role) {
        if (role != MembershipRole.HOSPITAL_SUPER_ADMIN && role != MembershipRole.ADMIN
                && role != MembershipRole.RECEPTIONIST) {
            throw new AppointmentApiException(HttpStatus.FORBIDDEN, "Appointment management is not permitted");
        }
    }

    private void requireReadPermission(MembershipRole role) {
        if (role != MembershipRole.HOSPITAL_SUPER_ADMIN && role != MembershipRole.ADMIN
                && role != MembershipRole.RECEPTIONIST && role != MembershipRole.DOCTOR && role != MembershipRole.NURSE) {
            throw new AppointmentApiException(HttpStatus.FORBIDDEN, "Appointment access is not permitted");
        }
    }

    private void requireOwnDoctorRecord(Appointment appointment, TenantContext tenant) {
        if (tenant.membershipRole() == MembershipRole.DOCTOR
                && appointment.getDoctor().getMembership().getAccount().getId() != tenant.accountId()) {
            throw new AppointmentApiException(HttpStatus.NOT_FOUND, "Appointment not found");
        }
    }

    private UUID ownDoctorId(TenantContext tenant) {
        return doctors.findByMembership_IdAndHospital_Id(tenant.membershipId(), tenant.hospitalUuid())
                .map(DoctorProfile::getId).orElseThrow(this::notFound);
    }

    private HospitalMembership currentMembership(TenantContext tenant) {
        return memberships.findByIdAndHospital_Id(tenant.membershipId(), tenant.hospitalUuid())
                .filter(membership -> membership.getStatus() == MembershipStatus.ACTIVE)
                .orElseThrow(() -> new AppointmentApiException(HttpStatus.FORBIDDEN, "Active Hospital membership required"));
    }

    private void requireEligibleDoctor(DoctorProfile doctor) {
        if (!doctor.isActive() || doctor.getMembership().getStatus() != MembershipStatus.ACTIVE
                || !doctor.getMembership().getAccount().isActive()
                || doctor.getMembership().getRole() != MembershipRole.DOCTOR
                || !MembershipRole.DOCTOR.name().equals(doctor.getMembership().getAccount().getRole())
                || doctor.getMembership().getHospital().getStatus() != HospitalStatus.APPROVED) {
            throw new AppointmentApiException(HttpStatus.CONFLICT, "Doctor is not eligible for appointments");
        }
    }

    private AppointmentApiException patientUnavailable() {
        return new AppointmentApiException(HttpStatus.NOT_FOUND, "Patient is unavailable in this Hospital");
    }

    private java.util.Optional<Appointment> findScoped(UUID id, UUID hospitalUuid) {
        return appointments.findByIdAndHospital_Id(id, hospitalUuid);
    }

    private AppointmentEvent event(Appointment appointment, TenantContext tenant, HospitalMembership actor,
            String type, AppointmentStatus previousStatus, AppointmentStatus newStatus,
            OffsetDateTime previousStart, OffsetDateTime previousEnd,
            OffsetDateTime newStart, OffsetDateTime newEnd, Instant at) {
        return new AppointmentEvent(UUID.randomUUID(), appointment, tenant.hospitalUuid(), actor, type,
                previousStatus, newStatus, previousStart, previousEnd, newStart, newEnd, at);
    }

    private TenantContext requireTenant(BearerTokenFilter.AuthPrincipal actor) {
        TenantContext tenant = tenantContext.get();
        if (actor == null || tenant == null || actor.hospitalId() == null
                || tenant.accountId() != actor.userId() || tenant.hospitalId() != actor.hospitalId()) {
            throw new AppointmentApiException(HttpStatus.FORBIDDEN, "Active Hospital membership required");
        }
        return tenant;
    }

    private AppointmentApiException notFound() {
        return new AppointmentApiException(HttpStatus.NOT_FOUND, "Appointment or Doctor Profile not found");
    }
    private AppointmentApiException invalidTransition() {
        return new AppointmentApiException(HttpStatus.CONFLICT, "Appointment status transition is not allowed");
    }

    private record BookingSlot(OffsetDateTime start, OffsetDateTime end) {}
}
