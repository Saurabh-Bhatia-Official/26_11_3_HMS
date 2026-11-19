package com.caresync.backend.doctor.repository;

import com.caresync.backend.doctor.entity.DoctorProfile;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface DoctorProfileRepository extends JpaRepository<DoctorProfile, UUID> {
    boolean existsByMembership_Id(UUID membershipId);

    Optional<DoctorProfile> findByIdAndHospital_Id(UUID doctorId, UUID hospitalId);

    Optional<DoctorProfile> findByMembership_IdAndHospital_Id(UUID membershipId, UUID hospitalId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select d from DoctorProfile d where d.id = :doctorId and d.hospital.id = :hospitalId")
    Optional<DoctorProfile> findByIdAndHospital_IdForUpdate(@Param("doctorId") UUID doctorId,
                                                             @Param("hospitalId") UUID hospitalId);

    @Query("""
            select d from DoctorProfile d
            where d.hospital.id = :hospitalId
              and (:active is null or d.active = :active)
              and (:query = '' or lower(d.specialization) like lower(concat('%', :query, '%'))
                   or lower(d.qualification) like lower(concat('%', :query, '%'))
                   or lower(d.membership.account.fullName) like lower(concat('%', :query, '%')))
            """)
    Page<DoctorProfile> searchHospitalDoctors(@Param("hospitalId") UUID hospitalId,
                                               @Param("query") String query,
                                               @Param("active") Boolean active,
                                               Pageable pageable);

    Page<DoctorProfile> findAllByHospital_IdAndMembership_Account_Id(UUID hospitalId,
                                                                       long accountId,
                                                                       Pageable pageable);
}
