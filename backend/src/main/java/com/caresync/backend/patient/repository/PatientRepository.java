package com.caresync.backend.patient.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.patient.entity.PatientStatus;

public interface PatientRepository extends JpaRepository<Patient, Long> {
    boolean existsByHospital_IdAndUhid(UUID hospitalId, String uhid);
    @Query("select p from Patient p join fetch p.hospital where p.uuid = :uuid")
    Optional<Patient> findByUuid(@Param("uuid") UUID uuid);

    Optional<Patient> findByUuidAndHospital_IdAndArchivedAtIsNull(UUID uuid, UUID hospitalId);

    Optional<Patient> findByIdAndHospital_HospitalIdAndArchivedAtIsNull(Long id, Long hospitalId);

    Optional<Patient> findByUuidAndHospital_HospitalIdAndArchivedAtIsNull(UUID uuid, Long hospitalId);

    @Query("""
        select p from Patient p
        where p.hospital.id = :hospitalId
          and p.archivedAt is null
          and (:status is null or p.status = :status)
          and (
              lower(p.name) like lower(concat('%', :query, '%'))
              or lower(p.uhid) like lower(concat('%', :query, '%'))
              or lower(coalesce(p.phone, '')) like lower(concat('%', :query, '%'))
              or (:uuidQuery is not null and p.uuid = :uuidQuery)
          )
        """)
Page<Patient> searchHospitalPatients(
        @Param("hospitalId") UUID hospitalId,
        @Param("query") String query,
        @Param("uuidQuery") UUID uuidQuery,
        @Param("status") PatientStatus status,
        Pageable pageable);
}