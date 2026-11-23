
package com.caresync.backend.opd.service;

import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.caresync.backend.appointment.dto.AppointmentStatusRequest;
import com.caresync.backend.appointment.entity.Appointment;
import com.caresync.backend.appointment.entity.AppointmentStatus;
import com.caresync.backend.appointment.repository.AppointmentRepository;
import com.caresync.backend.appointment.service.AppointmentService;
import com.caresync.backend.department.entity.Department;
import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.MembershipStatus;
import com.caresync.backend.opd.dto.OpdVisitRequest;
import com.caresync.backend.opd.dto.OpdVisitResponse;
import com.caresync.backend.opd.entity.OpdVisit;
import com.caresync.backend.opd.entity.OpdVisitStatus;
import com.caresync.backend.opd.repository.OpdVisitRepository;
import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.patient.entity.PatientStatus;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.security.BearerTokenFilter;
import com.caresync.backend.tenant.TenantContext;
import com.caresync.backend.tenant.TenantContextHolder;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

@Service
@Transactional
public class OpdVisitService {

    private final OpdVisitRepository opdVisitRepository;
    private final AppointmentService appointmentService;
    private final AppointmentRepository appointmentRepository;
    private final PatientRepository patientRepository;
    private final DoctorProfileRepository doctorRepository;
    private final DepartmentRepository departmentRepository;
    private final TenantContextHolder tenantContextHolder;

    @PersistenceContext
    private EntityManager entityManager;

    public OpdVisitService(
            OpdVisitRepository opdVisitRepository,
            AppointmentService appointmentService,
            AppointmentRepository appointmentRepository,
            PatientRepository patientRepository,
            DoctorProfileRepository doctorRepository,
            DepartmentRepository departmentRepository,
            TenantContextHolder tenantContextHolder
    ) {
        this.opdVisitRepository = opdVisitRepository;
        this.appointmentService = appointmentService;
        this.appointmentRepository = appointmentRepository;
        this.patientRepository = patientRepository;
        this.doctorRepository = doctorRepository;
        this.departmentRepository = departmentRepository;
        this.tenantContextHolder = tenantContextHolder;
    }

    // ---------------------------------------------------------
    // CREATE OPD VISIT
    // ---------------------------------------------------------

    public OpdVisitResponse createVisit(
            OpdVisitRequest request,
            BearerTokenFilter.AuthPrincipal actor
    ) {
        TenantContext tenant = requireTenant(actor);

        if (request == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Visit request is required"
            );
        }

        Patient patient;
        DoctorProfile doctor;
        Department department = null;

        UUID appointmentUuid = request.appointmentUuid();

        // -----------------------------------------------------
        // APPOINTMENT-BASED CHECK-IN
        // -----------------------------------------------------

        if (appointmentUuid != null) {

            // Lock appointment before checking for an existing visit.
            // This prevents simultaneous check-in requests from
            // creating duplicate OPD visits for the same appointment.

            Appointment appointment = appointmentRepository
                    .findByIdAndHospital_IdForUpdate(
                            appointmentUuid,
                            tenant.hospitalUuid()
                    )
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Appointment not found"
                    ));

            // Duplicate check happens AFTER acquiring the appointment lock.
            OpdVisit existing = opdVisitRepository
                    .findByHospitalUuidAndAppointmentUuid(
                            tenant.hospitalUuid(),
                            appointmentUuid
                    )
                    .orElse(null);

            if (existing != null) {
                return toResponse(existing);
            }

            patient = appointment.getPatient();

            // Lock and reload the doctor inside the current hospital.
            doctor = doctorRepository
                    .findByIdAndHospital_IdForUpdate(
                            appointment.getDoctor().getId(),
                            tenant.hospitalUuid()
                    )
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Doctor not found"
                    ));

            department = appointment.getDepartment();

            // Validate doctor immediately after loading doctor and department.
            validateEligibleDoctor(doctor);

            if (patient.getArchivedAt() != null
                    || patient.getStatus() != PatientStatus.ACTIVE) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Patient is unavailable"
                );
            }

            if (request.patientId() != null
                    || request.doctorUuid() != null
                    || request.departmentUuid() != null) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Do not send separate patient, doctor or department IDs for appointment check-in"
                );
            }

            // Preserve the existing appointment lifecycle.
            AppointmentStatus currentStatus = appointment.getStatus();

            if (currentStatus == AppointmentStatus.SCHEDULED) {
                appointmentService.changeStatus(
                        appointmentUuid,
                        new AppointmentStatusRequest(
                                AppointmentStatus.CONFIRMED
                        ),
                        actor
                );

                currentStatus = AppointmentStatus.CONFIRMED;
            }

            if (currentStatus == AppointmentStatus.CONFIRMED) {
                appointmentService.changeStatus(
                        appointmentUuid,
                        new AppointmentStatusRequest(
                                AppointmentStatus.CHECKED_IN
                        ),
                        actor
                );

                currentStatus = AppointmentStatus.CHECKED_IN;
            }

            if (currentStatus != AppointmentStatus.CHECKED_IN) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Appointment cannot be checked in from its current status"
                );
            }

        } else {

            // -------------------------------------------------
            // WALK-IN PATIENT
            // -------------------------------------------------

            if (request.patientId() == null
                    || request.patientId() <= 0
                    || request.doctorUuid() == null) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Patient ID and doctor UUID are required for a walk-in"
                );
            }

            patient = patientRepository
                    .findByIdAndHospital_HospitalIdAndArchivedAtIsNull(
                            request.patientId(),
                            tenant.hospitalId()
                    )
                    .filter(p -> p.getStatus() == PatientStatus.ACTIVE)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Patient not found"
                    ));

            doctor = doctorRepository
                    .findByIdAndHospital_IdForUpdate(
                            request.doctorUuid(),
                            tenant.hospitalUuid()
                    )
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Doctor not found"
                    ));

            validateEligibleDoctor(doctor);

            if (request.departmentUuid() != null) {

                department = departmentRepository
                        .findByIdAndHospital_IdAndActiveTrue(
                                request.departmentUuid(),
                                tenant.hospitalUuid()
                        )
                        .orElseThrow(() -> new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Department not found"
                        ));

                if (doctor.getDepartment() == null
                        || !doctor.getDepartment().getId()
                                .equals(department.getId())) {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT,
                            "Department must match the doctor's department"
                    );
                }

            } else {
                department = doctor.getDepartment();
            }
        }

        // -----------------------------------------------------
        // HOSPITAL OWNERSHIP VALIDATION
        // -----------------------------------------------------

        if (!patient.getHospital().getId().equals(tenant.hospitalUuid())) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Patient not found"
            );
        }

        if (!doctor.getHospital().getId().equals(tenant.hospitalUuid())) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Doctor not found"
            );
        }

        if (department != null
                && !department.getHospital().getId()
                        .equals(tenant.hospitalUuid())) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Department not found"
            );
        }

        // -----------------------------------------------------
        // HOSPITAL TIMEZONE VALIDATION
        // -----------------------------------------------------

        String timeZone = doctor.getHospital().getTimeZone();

        if (timeZone == null || timeZone.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Hospital time zone is not configured"
            );
        }

        ZoneId zoneId;

        try {
            zoneId = ZoneId.of(timeZone);
        } catch (DateTimeException exception) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Hospital time zone configuration is invalid"
            );
        }

        LocalDate visitDate = request.visitDate() != null
                ? request.visitDate()
                : LocalDate.now(zoneId);

        // -----------------------------------------------------
        // ATOMIC TOKEN ALLOCATION
        // -----------------------------------------------------

        Integer tokenNo = allocateNextToken(
                tenant.hospitalUuid(),
                doctor.getId(),
                visitDate
        );

        // -----------------------------------------------------
        // CREATE VISIT
        // -----------------------------------------------------

        OpdVisit visit = new OpdVisit(
                tenant.hospitalId(),
                tenant.hospitalUuid(),
                patient.getId(),
                doctor.getId(),
                department != null ? department.getId() : null,
                appointmentUuid,
                "OPD",
                tokenNo,
                visitDate
        );

        return toResponse(opdVisitRepository.saveAndFlush(visit));
    }

    // ---------------------------------------------------------
    // DOCTOR ELIGIBILITY
    // ---------------------------------------------------------

    private void validateEligibleDoctor(DoctorProfile doctor) {

        if (!doctor.isActive()
                || doctor.getMembership().getStatus()
                        != MembershipStatus.ACTIVE
                || !doctor.getMembership().getAccount().isActive()
                || doctor.getMembership().getRole()
                        != MembershipRole.DOCTOR
                || !MembershipRole.DOCTOR.name().equals(
                        doctor.getMembership().getAccount().getRole())
                || doctor.getMembership().getHospital().getStatus()
                        != HospitalStatus.APPROVED) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Doctor is not eligible for OPD"
            );
        }
    }

    // ---------------------------------------------------------
    // ATOMIC TOKEN ALLOCATION
    // ---------------------------------------------------------

    private Integer allocateNextToken(
            UUID hospitalUuid,
            UUID doctorUuid,
            LocalDate visitDate
    ) {
        Object result = entityManager.createNativeQuery("""
                INSERT INTO opd_token_counters (
                    hospital_uuid,
                    doctor_uuid,
                    visit_date,
                    last_token,
                    updated_at
                )
                VALUES (
                    :hospitalUuid,
                    :doctorUuid,
                    :visitDate,
                    1,
                    CURRENT_TIMESTAMP
                )
                ON CONFLICT (hospital_uuid, doctor_uuid, visit_date)
                DO UPDATE SET
                    last_token = opd_token_counters.last_token + 1,
                    updated_at = CURRENT_TIMESTAMP
                RETURNING last_token
                """)
                .setParameter("hospitalUuid", hospitalUuid)
                .setParameter("doctorUuid", doctorUuid)
                .setParameter("visitDate", visitDate)
                .getSingleResult();

        return ((Number) result).intValue();
    }

    // ---------------------------------------------------------
    // TENANT VALIDATION
    // ---------------------------------------------------------

    private TenantContext requireTenant(
            BearerTokenFilter.AuthPrincipal actor
    ) {
        TenantContext tenant = tenantContextHolder.get();

        if (actor == null
                || tenant == null
                || actor.hospitalId() == null
                || tenant.accountId() != actor.userId()
                || tenant.hospitalId() != actor.hospitalId()) {

            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Active Hospital membership required"
            );
        }

        return tenant;
    }

    // ---------------------------------------------------------
    // DAILY OPD QUEUE
    // ---------------------------------------------------------

    @Transactional(readOnly = true)
    public List<OpdVisitResponse> getDailyQueue(
            Long hospitalId,
            LocalDate visitDate
    ) {
        validateHospitalId(hospitalId);

        LocalDate date = visitDate != null
                ? visitDate
                : LocalDate.now();

        return opdVisitRepository
                .findAllByHospitalIdAndVisitDateOrderByTokenNoAsc(
                        hospitalId,
                        date
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ---------------------------------------------------------
    // DOCTOR OPD QUEUE - LEGACY NUMERIC ID
    // ---------------------------------------------------------

    @Transactional(readOnly = true)
    public List<OpdVisitResponse> getDoctorQueue(
            Long hospitalId,
            Long doctorId,
            LocalDate visitDate
    ) {
        validateHospitalId(hospitalId);

        if (doctorId == null || doctorId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid doctor ID"
            );
        }

        LocalDate date = visitDate != null
                ? visitDate
                : LocalDate.now();

        return opdVisitRepository
                .findAllByHospitalIdAndVisitDateAndDoctorIdOrderByTokenNoAsc(
                        hospitalId,
                        date,
                        doctorId
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ---------------------------------------------------------
    // QUEUE BY STATUS
    // ---------------------------------------------------------

    @Transactional(readOnly = true)
    public List<OpdVisitResponse> getQueueByStatus(
            Long hospitalId,
            LocalDate visitDate,
            OpdVisitStatus status
    ) {
        validateHospitalId(hospitalId);

        LocalDate date = visitDate != null
                ? visitDate
                : LocalDate.now();

        if (status == null) {
            return getDailyQueue(hospitalId, date);
        }

        return opdVisitRepository
                .findAllByHospitalIdAndVisitDateAndStatusOrderByTokenNoAsc(
                        hospitalId,
                        date,
                        status
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ---------------------------------------------------------
    // GET VISIT BY ID
    // ---------------------------------------------------------

    @Transactional(readOnly = true)
    public OpdVisitResponse getVisitById(
            Long hospitalId,
            Long visitId
    ) {
        validateHospitalId(hospitalId);

        OpdVisit visit = opdVisitRepository
                .findByIdAndHospitalId(visitId, hospitalId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "OPD visit not found"
                ));

        return toResponse(visit);
    }

    // ---------------------------------------------------------
    // UPDATE VISIT STATUS
    // ---------------------------------------------------------
public OpdVisitResponse updateVisitStatus(
        Long visitId,
        OpdVisitStatus newStatus,
        BearerTokenFilter.AuthPrincipal actor
) {
    TenantContext tenant = requireTenant(actor);

    if (visitId == null || visitId <= 0 || newStatus == null) {
        throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Valid visit ID and status are required"
        );
    }

    OpdVisit visit = opdVisitRepository
            .findByIdAndHospitalUuid(
                    visitId,
                    tenant.hospitalUuid()
            )
            .orElseThrow(() -> new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "OPD visit not found"
            ));

    MembershipRole role = tenant.membershipRole();

    boolean admin =
            role == MembershipRole.HOSPITAL_SUPER_ADMIN
            || role == MembershipRole.ADMIN;

    boolean assignedDoctor = false;

    if (role == MembershipRole.DOCTOR
            && visit.getDoctorUuid() != null) {

        assignedDoctor = doctorRepository
                .findByIdAndHospital_Id(
                        visit.getDoctorUuid(),
                        tenant.hospitalUuid()
                )
                .map(doctor ->
                        doctor.getMembership()
                                .getAccount()
                                .getId() == tenant.accountId()
                )
                .orElse(false);
    }

    if (!admin && !assignedDoctor) {
        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "You are not permitted to update this OPD visit"
        );
    }

    OpdVisitStatus currentStatus = visit.getStatus();

    boolean validTransition =
            (currentStatus == OpdVisitStatus.WAITING_FOR_VITALS
                    && newStatus == OpdVisitStatus.IN_CONSULTATION)
            ||
            (currentStatus == OpdVisitStatus.IN_CONSULTATION
                    && newStatus == OpdVisitStatus.COMPLETED);

    if (!validTransition) {
        throw new ResponseStatusException(
                HttpStatus.CONFLICT,
                "Invalid OPD visit status transition"
        );
    }

    visit.setStatus(newStatus);

    return toResponse(opdVisitRepository.saveAndFlush(visit));
}
    // ---------------------------------------------------------
    // VALIDATE HOSPITAL ID
    // ---------------------------------------------------------

    private void validateHospitalId(Long hospitalId) {
        if (hospitalId == null || hospitalId <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "No hospital is associated with the authenticated user"
            );
        }
    }

    // ---------------------------------------------------------
    // RESPONSE MAPPER
    // ---------------------------------------------------------

    private OpdVisitResponse toResponse(OpdVisit visit) {
        return new OpdVisitResponse(
                visit.getId(),
                visit.getUuid(),
                visit.getPatientId(),
                visit.getDoctorId(),
                visit.getDepartmentId(),
                visit.getAppointmentId(),
                visit.getHospitalUuid(),
                visit.getDoctorUuid(),
                visit.getDepartmentUuid(),
                visit.getAppointmentUuid(),
                visit.getVisitType(),
                visit.getTokenNo(),
                visit.getVisitDate(),
                visit.getStatus(),
                visit.getCreatedAt(),
                visit.getUpdatedAt()
        );
    }@Transactional(readOnly = true)
public List<OpdVisitResponse> getDoctorQueueByUuid(
        Long hospitalId,
        UUID doctorUuid,
        LocalDate visitDate
) {
    validateHospitalId(hospitalId);

    TenantContext tenant = tenantContextHolder.get();

    if (tenant == null || tenant.hospitalId() != hospitalId) {
        throw new ResponseStatusException(
                HttpStatus.FORBIDDEN,
                "Active hospital membership required"
        );
    }

    if (doctorUuid == null) {
        throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Doctor UUID is required"
        );
    }

    LocalDate date = visitDate != null
            ? visitDate
            : LocalDate.now();

    return opdVisitRepository
            .findAllByHospitalUuidAndVisitDateAndDoctorUuidOrderByTokenNoAsc(
                    tenant.hospitalUuid(),
                    date,
                    doctorUuid
            )
            .stream()
            .map(this::toResponse)
            .toList();
}
}
