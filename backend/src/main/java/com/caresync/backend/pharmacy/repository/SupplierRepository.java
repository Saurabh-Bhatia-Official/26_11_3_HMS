package com.caresync.backend.pharmacy.repository;

import com.caresync.backend.pharmacy.entity.Supplier;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SupplierRepository extends JpaRepository<Supplier, Long> {
    List<Supplier> findAllByHospitalIdAndDeletedFalseOrderByNameAsc(Long hospitalId);
    Optional<Supplier> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
}
