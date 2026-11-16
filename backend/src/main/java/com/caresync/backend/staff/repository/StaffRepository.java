package com.caresync.backend.staff.repository;

import com.caresync.backend.staff.entity.StaffMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StaffRepository extends JpaRepository<StaffMember, Long> {
    List<StaffMember> findAllByHospitalIdAndDeletedFalseOrderByNameAsc(Long hospitalId);
    List<StaffMember> findAllByHospitalIdAndRoleAndDeletedFalseOrderByNameAsc(Long hospitalId, String role);
    Optional<StaffMember> findByIdAndHospitalIdAndDeletedFalse(Long id, Long hospitalId);
    long countByHospitalIdAndActiveTrueAndDeletedFalse(Long hospitalId);
}
