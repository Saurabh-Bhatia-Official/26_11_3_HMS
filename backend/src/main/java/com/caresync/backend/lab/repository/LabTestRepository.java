package com.caresync.backend.lab.repository;

import com.caresync.backend.lab.entity.LabTest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LabTestRepository extends JpaRepository<LabTest, Long> {
    List<LabTest> findAllByHospitalIdAndDeletedFalseOrderByNameAsc(Long hospitalId);
    Optional<LabTest> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
}
