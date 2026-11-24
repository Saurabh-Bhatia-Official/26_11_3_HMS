
package com.caresync.backend.opd.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.caresync.backend.opd.entity.OpdVisit;
import com.caresync.backend.opd.entity.OpdVisitStatus;
@Repository
public interface OpdVisitRepository extends JpaRepository<OpdVisit, Long> {

    // --------------------------------------------------
    // LEGACY NUMERIC-ID METHODS
    // --------------------------------------------------

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

    // --------------------------------------------------
    // MODERN UUID-BASED METHODS
    // --------------------------------------------------

    Optional<OpdVisit> findByIdAndHospitalUuid(
            Long id,
            UUID hospitalUuid
    );

    Optional<OpdVisit> findByUuidAndHospitalUuid(
            UUID uuid,
            UUID hospitalUuid
    );

    Optional<OpdVisit> findByUuidAndHospitalId(
            UUID uuid,
            Long hospitalId
    );

    Optional<OpdVisit> findByHospitalUuidAndAppointmentUuid(
            UUID hospitalUuid,
            UUID appointmentUuid
    );

    List<OpdVisit> findAllByHospitalUuidAndVisitDateOrderByTokenNoAsc(
            UUID hospitalUuid,
            LocalDate visitDate
    );

    List<OpdVisit> findAllByHospitalUuidAndVisitDateAndDoctorUuidOrderByTokenNoAsc(
            UUID hospitalUuid,
            LocalDate visitDate,
            UUID doctorUuid
    );

    List<OpdVisit> findAllByHospitalUuidAndVisitDateAndStatusOrderByTokenNoAsc(
            UUID hospitalUuid,
            LocalDate visitDate,
            OpdVisitStatus status
    );

    boolean existsByHospitalUuidAndAppointmentUuid(
            UUID hospitalUuid,
            UUID appointmentUuid
    );

    // --------------------------------------------------
    // TOKEN LOOKUP — informational only
    // Do not use this to allocate the next token.
    // --------------------------------------------------

    @Query("""
        SELECT COALESCE(MAX(v.tokenNo), 0)
        FROM OpdVisit v
        WHERE v.hospitalUuid = :hospitalUuid
          AND v.doctorUuid = :doctorUuid
          AND v.visitDate = :visitDate
    """)
    Integer findMaximumTokenNumber(
            @Param("hospitalUuid") UUID hospitalUuid,
            @Param("doctorUuid") UUID doctorUuid,
            @Param("visitDate") LocalDate visitDate
    );
}
