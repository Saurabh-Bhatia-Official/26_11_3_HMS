package com.caresync.backend.security;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.List;
import java.time.Instant;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByTokenHash(String tokenHash);

    @Query("select t.account.id from RefreshToken t where t.tokenHash = :tokenHash")
    Optional<Long> findAccountIdByTokenHash(@Param("tokenHash") String tokenHash);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from RefreshToken t where t.tokenHash = :tokenHash")
    Optional<RefreshToken> findByTokenHashForUpdate(@Param("tokenHash") String tokenHash);

    List<RefreshToken> findAllByFamilyId(String familyId);

    @Modifying
    @Query("delete from RefreshToken t where t.expiresAt < :cutoff and " +
            "(t.familyId is null or not exists (select activeToken from RefreshToken activeToken " +
            "where activeToken.familyId = t.familyId and activeToken.expiresAt >= :cutoff))")
    int deleteExpired(@Param("cutoff") Instant cutoff);
}
