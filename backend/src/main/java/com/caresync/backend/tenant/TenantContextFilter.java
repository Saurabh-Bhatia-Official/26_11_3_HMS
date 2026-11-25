package com.caresync.backend.tenant;

import com.caresync.backend.membership.service.MembershipService;
import com.caresync.backend.security.BearerTokenFilter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class TenantContextFilter extends OncePerRequestFilter {
    private final MembershipService memberships;
    private final TenantContextHolder contextHolder;

    public TenantContextFilter(MembershipService memberships, TenantContextHolder contextHolder) {
        this.memberships = memberships;
        this.contextHolder = contextHolder;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.getPrincipal() instanceof BearerTokenFilter.AuthPrincipal principal
                    && principal.hospitalId() != null) {
                memberships.resolveActiveContext(principal.userId(), principal.hospitalId()).ifPresent(contextHolder::bind);
            }
            chain.doFilter(request, response);
        } finally {
            contextHolder.bind(null);
        }
    }
}
