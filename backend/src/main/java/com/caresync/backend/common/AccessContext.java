package com.caresync.backend.common;

import com.caresync.backend.security.BearerTokenFilter;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class AccessContext {
    public long hospitalId() {
        BearerTokenFilter.AuthPrincipal principal = principal();
        if (principal.hospitalId() == null || principal.hospitalId() <= 0) {
            throw new AccessDeniedException("A hospital-scoped account is required");
        }
        return principal.hospitalId();
    }

    public long userId() {
        return principal().userId();
    }

    private BearerTokenFilter.AuthPrincipal principal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof BearerTokenFilter.AuthPrincipal principal)) {
            throw new AccessDeniedException("Authentication is required");
        }
        return principal;
    }
}
