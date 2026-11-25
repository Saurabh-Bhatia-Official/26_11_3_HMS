package com.caresync.backend.pharmacy.repository;

import com.caresync.backend.pharmacy.entity.Dispensing;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DispensingRepository extends JpaRepository<Dispensing, Long> {
    List<Dispensing> findAllByHospitalIdAndDeletedFalseOrderByCreatedAtDesc(Long hospitalId);
}
