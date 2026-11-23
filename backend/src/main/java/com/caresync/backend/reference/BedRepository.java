package com.caresync.backend.reference;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface BedRepository extends JpaRepository<BedRecord, Long> {
    List<BedRecord> findAllByHospitalIdAndDeletedFalseOrderByBedNumberAsc(Long hospitalId);
    Optional<BedRecord> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
    Optional<BedRecord> findByUuidAndHospitalIdAndDeletedFalse(String uuid, Long hospitalId);
    Optional<BedRecord> findByBedNumberAndHospitalIdAndDeletedFalse(String bedNumber, Long hospitalId);
    Optional<BedRecord> findByAdmissionIdAndHospitalIdAndDeletedFalse(Long admissionId, Long hospitalId);

    long countByHospitalIdAndDeletedFalse(Long hospitalId);
    long countByHospitalIdAndDeletedFalseAndStatusIgnoreCase(Long hospitalId, String status);

    @Query("select count(b) from BedRecord b where b.hospitalId = :hospitalId and b.deleted = false and lower(b.status) = 'occupied'")
    long countOccupiedBeds(@Param("hospitalId") Long hospitalId);

    @Query("select count(b) from BedRecord b where b.hospitalId = :hospitalId and b.deleted = false and lower(b.status) = 'available'")
    long countAvailableBeds(@Param("hospitalId") Long hospitalId);
}
