package com.caresync.backend.staff.repository;

import com.caresync.backend.staff.entity.Department;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DepartmentRepository extends JpaRepository<Department, Long> {
    List<Department> findAllByHospitalIdAndDeletedFalseOrderByNameAsc(Long hospitalId);
    Optional<Department> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
}
