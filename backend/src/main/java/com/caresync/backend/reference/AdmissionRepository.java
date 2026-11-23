package com.caresync.backend.reference;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AdmissionRepository extends JpaRepository<AdmissionRecord, Long> {
    Optional<AdmissionRecord> findByUuidAndHospitalIdAndDeletedFalse(String uuid, long hospitalId);
    Optional<AdmissionRecord> findByIdAndHospitalIdAndDeletedFalse(long id, long hospitalId);

    long countByHospitalIdAndDeletedFalseAndStatusIgnoreCase(Long hospitalId, String status);
}
