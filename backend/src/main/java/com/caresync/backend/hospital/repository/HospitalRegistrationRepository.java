package com.caresync.backend.hospital.repository;

import com.caresync.backend.hospital.entity.HospitalRegistration;
import com.caresync.backend.hospital.entity.HospitalStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HospitalRegistrationRepository extends JpaRepository<HospitalRegistration, UUID> {
    boolean existsByAdminUsernameIgnoreCaseAndStatus(String adminUsername, HospitalStatus status);
    List<HospitalRegistration> findAllByStatusOrderBySubmittedAtAsc(HospitalStatus status);
    List<HospitalRegistration> findAllByStatusAndSubmittedAtAfterOrderBySubmittedAtAsc(
            HospitalStatus status, Instant submittedAt);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from HospitalRegistration r join fetch r.hospital " +
            "where r.status = :status and r.submittedAt <= :cutoff order by r.submittedAt asc")
    List<HospitalRegistration> lockExpiredRegistrations(@Param("status") HospitalStatus status,
                                                         @Param("cutoff") Instant cutoff);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from HospitalRegistration r join fetch r.hospital where r.id = :id")
    Optional<HospitalRegistration> findByIdForUpdate(@Param("id") UUID id);
}
