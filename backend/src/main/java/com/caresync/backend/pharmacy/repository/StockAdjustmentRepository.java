package com.caresync.backend.pharmacy.repository;

import com.caresync.backend.pharmacy.entity.StockAdjustment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StockAdjustmentRepository extends JpaRepository<StockAdjustment, Long> {
    List<StockAdjustment> findAllByHospitalIdAndDeletedFalseOrderByCreatedAtDesc(Long hospitalId);
}
