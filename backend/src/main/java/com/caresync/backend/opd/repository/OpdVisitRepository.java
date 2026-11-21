package com.caresync.backend.opd.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.caresync.backend.opd.entity.OpdVisit;
import com.caresync.backend.opd.entity.OpdVisitStatus;

@Repository
public interface OpdVisitRepository extends JpaRepository<OpdVisit, Long> {

    Optional<OpdVisit> findByIdAndHospitalId(
            Long id,
            Long hospitalId
    );

    List<OpdVisit> findAllByHospitalIdAndVisitDateOrderByTokenNoAsc(
            Long hospitalId,
            LocalDate visitDate
    );

    List<OpdVisit> findAllByHospitalIdAndVisitDateAndDoctorIdOrderByTokenNoAsc(
            Long hospitalId,
            LocalDate visitDate,
            Long doctorId
    );

    List<OpdVisit> findAllByHospitalIdAndVisitDateAndStatusOrderByTokenNoAsc(
            Long hospitalId,
            LocalDate visitDate,
            OpdVisitStatus status
    );

    boolean existsByHospitalIdAndAppointmentId(
            Long hospitalId,
            Long appointmentId
    );
}
