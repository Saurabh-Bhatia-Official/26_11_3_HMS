package com.caresync.backend.opd.repository;

import com.caresync.backend.opd.entity.Vitals;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface VitalsRepository extends JpaRepository<Vitals, Long> {
    Optional<Vitals> findByVisitIdAndHospitalUuidAndDeletedFalse(Long visitId, UUID hospitalUuid);
    boolean existsByVisitIdAndHospitalUuidAndDeletedFalse(Long visitId, UUID hospitalUuid);
}
