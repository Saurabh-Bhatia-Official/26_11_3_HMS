package com.caresync.backend.membership.dto;

import com.caresync.backend.membership.entity.MembershipRole;
import jakarta.validation.constraints.NotNull;

public record MembershipRoleChangeRequest(@NotNull MembershipRole role) {}
