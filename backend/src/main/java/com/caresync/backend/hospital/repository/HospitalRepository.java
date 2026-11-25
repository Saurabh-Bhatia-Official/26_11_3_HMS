package com.caresync.backend.hospital.repository;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HospitalRepository extends JpaRepository<Hospital, UUID> {
    List<Hospital> findAllByStatusOrderByNameAsc(HospitalStatus status);
    Optional<Hospital> findByHospitalIdAndStatus(Long hospitalId, HospitalStatus status);
    boolean existsByHospitalId(Long hospitalId);
}
