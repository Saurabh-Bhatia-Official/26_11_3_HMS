package com.caresync.backend.billing.repository;

import com.caresync.backend.billing.entity.BillableService;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BillableServiceRepository extends JpaRepository<BillableService, Long> {
    List<BillableService> findAllByHospitalIdAndDeletedFalseOrderByNameAsc(Long hospitalId);
    Optional<BillableService> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
}
