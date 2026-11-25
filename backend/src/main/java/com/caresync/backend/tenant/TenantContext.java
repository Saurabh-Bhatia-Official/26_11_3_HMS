package com.caresync.backend.tenant;

import com.caresync.backend.membership.entity.MembershipRole;

import java.util.UUID;

/** Immutable hospital scope resolved from the authenticated account and an active database membership. */
public record TenantContext(long accountId, UUID membershipId, UUID hospitalUuid,
                            long hospitalId, MembershipRole membershipRole) {}
