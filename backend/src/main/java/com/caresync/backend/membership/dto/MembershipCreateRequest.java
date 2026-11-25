package com.caresync.backend.membership.dto;

import com.caresync.backend.membership.entity.MembershipRole;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record MembershipCreateRequest(
        @NotNull @Positive Long accountId,
        @NotNull MembershipRole role) {}
