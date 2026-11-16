package com.caresync.backend.patient.repository;

import com.caresync.backend.patient.entity.PatientRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PatientRepository extends JpaRepository<PatientRecord, Long> {
    Optional<PatientRecord> findByUuidAndHospitalIdAndDeletedFalse(String uuid, long hospitalId);
    boolean existsByHospitalIdAndUhidAndDeletedFalse(long hospitalId, String uhid);
}
