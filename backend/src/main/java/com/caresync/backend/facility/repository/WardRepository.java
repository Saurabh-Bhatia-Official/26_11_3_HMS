
package com.caresync.backend.facility.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.caresync.backend.facility.entity.Ward;

public interface WardRepository extends JpaRepository<Ward, Long> {

    List<Ward> findAllByHospitalId(Long hospitalId);

    Optional<Ward> findByIdAndHospitalId(Long id, Long hospitalId);

    boolean existsByHospitalIdAndWardCode(Long hospitalId, String wardCode);

    boolean existsByHospitalIdAndWardCodeAndIdNot(
            Long hospitalId,
            String wardCode,
            Long id
    );

    boolean existsByHospitalIdAndName(Long hospitalId, String name);

boolean existsByHospitalIdAndNameAndIdNot(
        Long hospitalId,
        String name,
        Long id
);
}
