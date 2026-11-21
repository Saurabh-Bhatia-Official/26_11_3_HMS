package com.caresync.backend.membership.repository;

import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HospitalMembershipRepository extends JpaRepository<HospitalMembership, UUID> {
    Optional<HospitalMembership> findByAccount_Id(long accountId);

    Optional<HospitalMembership> findByAccount_IdAndStatusAndHospital_HospitalId(
            long accountId, MembershipStatus status, Long hospitalId);

    List<HospitalMembership> findAllByHospital_IdOrderByCreatedAtDesc(UUID hospitalId);

    Optional<HospitalMembership> findByIdAndHospital_Id(UUID membershipId, UUID hospitalId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from HospitalMembership m where m.id = :membershipId and m.hospital.id = :hospitalId")
    Optional<HospitalMembership> findByIdAndHospitalIdForUpdate(
            @Param("membershipId") UUID membershipId, @Param("hospitalId") UUID hospitalId);
}
