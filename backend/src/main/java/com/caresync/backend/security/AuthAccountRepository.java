package com.caresync.backend.security;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.util.Optional;

public interface AuthAccountRepository extends JpaRepository<AuthAccount, Long> {
    Optional<AuthAccount> findByUsername(String username);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from AuthAccount a where a.username = :username")
    Optional<AuthAccount> findByUsernameForUpdate(@Param("username") String username);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from AuthAccount a where a.id = :id")
    Optional<AuthAccount> findByIdForUpdate(@Param("id") Long id);
    boolean existsByUsername(String username);
}
