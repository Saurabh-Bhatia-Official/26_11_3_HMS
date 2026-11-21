package com.caresync.backend.membership.controller;

import com.caresync.backend.membership.dto.MembershipCreateRequest;
import com.caresync.backend.membership.dto.MembershipResponse;
import com.caresync.backend.membership.dto.MembershipRoleChangeRequest;
import com.caresync.backend.membership.entity.MembershipStatus;
import com.caresync.backend.membership.service.MembershipService;
import com.caresync.backend.security.BearerTokenFilter;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/memberships")
public class MembershipController {
    private final MembershipService memberships;

    public MembershipController(MembershipService memberships) {
        this.memberships = memberships;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public MembershipResponse grant(@Valid @RequestBody MembershipCreateRequest request,
                                    @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return MembershipResponse.from(memberships.grant(actor.userId(), request.accountId(), request.role()));
    }

    @GetMapping
    public List<MembershipResponse> list(
            @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return memberships.listForHospitalSuperAdmin(actor.userId()).stream()
                .map(MembershipResponse::from).toList();
    }

    @GetMapping("/{membershipId}")
    public MembershipResponse get(@PathVariable UUID membershipId,
                                  @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return MembershipResponse.from(memberships.getForHospitalSuperAdmin(actor.userId(), membershipId));
    }

    @PatchMapping("/{membershipId}/role")
    public MembershipResponse changeRole(@PathVariable UUID membershipId,
                                         @Valid @RequestBody MembershipRoleChangeRequest request,
                                         @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return MembershipResponse.from(memberships.changeRole(actor.userId(), membershipId, request.role()));
    }

    @PatchMapping("/{membershipId}/activate")
    public MembershipResponse activate(@PathVariable UUID membershipId,
                                       @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return changeStatus(membershipId, MembershipStatus.ACTIVE, actor);
    }

    @PatchMapping("/{membershipId}/deactivate")
    public MembershipResponse deactivate(@PathVariable UUID membershipId,
                                         @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return changeStatus(membershipId, MembershipStatus.INACTIVE, actor);
    }

    @PatchMapping("/{membershipId}/revoke")
    public MembershipResponse revoke(@PathVariable UUID membershipId,
                                     @AuthenticationPrincipal BearerTokenFilter.AuthPrincipal actor) {
        return changeStatus(membershipId, MembershipStatus.REVOKED, actor);
    }

    private MembershipResponse changeStatus(UUID membershipId, MembershipStatus status,
                                            BearerTokenFilter.AuthPrincipal actor) {
        return MembershipResponse.from(memberships.changeStatus(actor.userId(), membershipId, status));
    }
}
