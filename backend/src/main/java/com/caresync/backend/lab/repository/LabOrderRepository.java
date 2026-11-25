package com.caresync.backend.lab.repository;

import com.caresync.backend.lab.entity.LabOrder;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface LabOrderRepository extends JpaRepository<LabOrder, Long> {
    List<LabOrder> findAllByHospitalIdAndDeletedFalseOrderByOrderedAtDesc(Long hospitalId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from LabOrder o where o.id = :id and o.hospitalId = :hospitalId and o.deleted = false")
    Optional<LabOrder> findForUpdate(@Param("id") long id, @Param("hospitalId") long hospitalId);

    long countByHospitalIdAndDeletedFalseAndStatusIn(Long hospitalId, List<String> statuses);
}
