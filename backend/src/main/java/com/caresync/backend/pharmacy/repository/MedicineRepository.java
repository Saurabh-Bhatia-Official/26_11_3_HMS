package com.caresync.backend.pharmacy.repository;

import com.caresync.backend.pharmacy.entity.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MedicineRepository extends JpaRepository<Medicine, Long> {
    List<Medicine> findAllByHospitalIdAndDeletedFalseOrderByNameAsc(Long hospitalId);
    Optional<Medicine> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
}
