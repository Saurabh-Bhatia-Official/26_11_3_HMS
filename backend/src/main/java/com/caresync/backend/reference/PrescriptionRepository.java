package com.caresync.backend.reference;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PrescriptionRepository extends JpaRepository<PrescriptionRecord, Long> {
    Optional<PrescriptionRecord> findByUuidAndHospitalIdAndDeletedFalse(String uuid, long hospitalId);
    Optional<PrescriptionRecord> findByIdAndHospitalIdAndDeletedFalse(long id, long hospitalId);
}
