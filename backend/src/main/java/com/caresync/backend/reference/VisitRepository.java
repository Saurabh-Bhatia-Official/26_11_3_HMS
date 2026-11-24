package com.caresync.backend.reference;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Optional;

public interface VisitRepository extends JpaRepository<VisitRecord, Long> {
    Optional<VisitRecord> findByIdAndHospitalIdAndDeletedFalse(long id, long hospitalId);
    Optional<VisitRecord> findByUuidAndHospitalIdAndDeletedFalse(String uuid, long hospitalId);

    @Query("select count(distinct v.patient.id) from VisitRecord v where v.hospitalId = :hospitalId " +
            "and v.deleted = false and lower(v.visitType) = lower(:visitType) and v.visitDate = :visitDate and lower(v.status) <> 'cancelled'")
    long countDistinctPatientsByVisitTypeAndDate(@Param("hospitalId") long hospitalId,
                                                @Param("visitType") String visitType,
                                                @Param("visitDate") LocalDate visitDate);

    @Query("select count(v.id) from VisitRecord v where v.hospitalId = :hospitalId " +
            "and v.deleted = false and lower(v.visitType) = lower(:visitType) and v.visitDate = :visitDate and lower(v.status) <> 'cancelled'")
    long countVisitsByVisitTypeAndDate(@Param("hospitalId") long hospitalId,
                                       @Param("visitType") String visitType,
                                       @Param("visitDate") LocalDate visitDate);
}
