package com.caresync.backend.membership.dto;

import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.MembershipStatus;

import java.time.Instant;
import java.util.UUID;

public record MembershipResponse(
        UUID membershipId,
        Long accountId,
        MembershipRole role,
        MembershipStatus status,
        Instant createdAt,
        Instant updatedAt,
        Instant revokedAt) {

    public static MembershipResponse from(HospitalMembership membership) {
        return new MembershipResponse(membership.getId(), membership.getAccount().getId(), membership.getRole(),
                membership.getStatus(), membership.getCreatedAt(), membership.getUpdatedAt(), membership.getRevokedAt());
    }
}
