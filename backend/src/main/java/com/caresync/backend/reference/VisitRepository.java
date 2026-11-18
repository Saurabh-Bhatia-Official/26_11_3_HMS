package com.caresync.backend.reference;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface VisitRepository extends JpaRepository<VisitRecord, Long> {
    Optional<VisitRecord> findByIdAndHospitalIdAndDeletedFalse(long id, long hospitalId);
    Optional<VisitRecord> findByUuidAndHospitalIdAndDeletedFalse(String uuid, long hospitalId);
}
