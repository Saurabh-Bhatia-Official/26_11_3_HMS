package com.caresync.backend.tenant;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.context.annotation.RequestScope;
import org.springframework.web.server.ResponseStatusException;

@Component
@RequestScope
public class TenantContextHolder {
    private TenantContext context;

    public TenantContext get() { return context; }

    public void bind(TenantContext context) { this.context = context; }

    public TenantContext require() {
        if (context == null) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Active Hospital membership required");
        return context;
    }
}
