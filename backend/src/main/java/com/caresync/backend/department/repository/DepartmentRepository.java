package com.caresync.backend.department.repository;

import com.caresync.backend.department.entity.Department;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface DepartmentRepository extends JpaRepository<Department, UUID> {
    boolean existsByHospital_IdAndCodeIgnoreCaseAndActiveTrue(UUID hospitalId, String code);

    Optional<Department> findByIdAndHospital_Id(UUID id, UUID hospitalId);

    Optional<Department> findByIdAndHospital_IdAndActiveTrue(UUID id, UUID hospitalId);

    @Query("""
            select d from Department d
            where d.hospital.id = :hospitalId
              and (:active is null or d.active = :active)
              and (:query = '' or lower(d.name) like lower(concat('%', :query, '%'))
                   or lower(d.code) like lower(concat('%', :query, '%')))
            """)
    Page<Department> searchHospitalDepartments(@Param("hospitalId") UUID hospitalId,
                                                @Param("query") String query,
                                                @Param("active") Boolean active,
                                                Pageable pageable);
}
