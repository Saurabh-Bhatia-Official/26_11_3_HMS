package com.caresync.backend.membership.repository;

import com.caresync.backend.membership.entity.MembershipAuditEvent;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MembershipAuditEventRepository extends JpaRepository<MembershipAuditEvent, Long> {}
