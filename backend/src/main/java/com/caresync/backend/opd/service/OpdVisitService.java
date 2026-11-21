package com.caresync.backend.opd.service;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.caresync.backend.opd.dto.OpdVisitResponse;
import com.caresync.backend.opd.entity.OpdVisit;
import com.caresync.backend.opd.entity.OpdVisitStatus;
import com.caresync.backend.opd.repository.OpdVisitRepository;

@Service
@Transactional
public class OpdVisitService {

    private final OpdVisitRepository opdVisitRepository;

    public OpdVisitService(OpdVisitRepository opdVisitRepository) {
        this.opdVisitRepository = opdVisitRepository;
    }

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
                        hospitalId, date
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

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
                        hospitalId, date, doctorId
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

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
                        hospitalId, date, status
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public OpdVisitResponse getVisitById(
            Long hospitalId,
            Long visitId
    ) {
        validateHospitalId(hospitalId);

        OpdVisit visit = opdVisitRepository
                .findByIdAndHospitalId(visitId, hospitalId)
                .orElseThrow(() ->
        new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "OPD visit not found"
        ));

        return toResponse(visit);
    }

    public OpdVisitResponse updateVisitStatus(
            Long hospitalId,
            Long visitId,
            OpdVisitStatus newStatus
    ) {
        validateHospitalId(hospitalId);

        if (newStatus == null) {
            throw new IllegalArgumentException("Visit status is required");
        }

        OpdVisit visit = opdVisitRepository
                .findByIdAndHospitalId(visitId, hospitalId)
                .orElseThrow(() ->
                        new IllegalArgumentException("OPD visit not found"));

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

        return toResponse(opdVisitRepository.save(visit));
    }

    private void validateHospitalId(Long hospitalId) {
        if (hospitalId == null || hospitalId <= 0) {
            throw new ResponseStatusException(
        HttpStatus.FORBIDDEN,
        "No hospital is associated with the authenticated user"
);
        }
    }

    private OpdVisitResponse toResponse(OpdVisit visit) {
        return new OpdVisitResponse(
                visit.getId(),
                visit.getUuid(),
                visit.getPatientId(),
                visit.getDoctorId(),
                visit.getDepartmentId(),
                visit.getAppointmentId(),
                visit.getVisitType(),
                visit.getTokenNo(),
                visit.getVisitDate(),
                visit.getStatus(),
                visit.getCreatedAt(),
                visit.getUpdatedAt()
        );
    }
}