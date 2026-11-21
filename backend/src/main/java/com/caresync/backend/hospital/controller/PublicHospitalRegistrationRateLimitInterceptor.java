package com.caresync.backend.hospital.controller;

import com.caresync.backend.hospital.service.PublicHospitalRegistrationRateLimiter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.io.IOException;

@Component
public class PublicHospitalRegistrationRateLimitInterceptor implements HandlerInterceptor {
    private static final String ERROR_BODY = "{\"error\":\"Too many registration requests. Try again later.\"}";
    private static final String REGISTRATION_PATH = "/api/v1/hospital-registrations";

    private final PublicHospitalRegistrationRateLimiter limiter;

    public PublicHospitalRegistrationRateLimitInterceptor(PublicHospitalRegistrationRateLimiter limiter) {
        this.limiter = limiter;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws IOException {
        if (!"POST".equalsIgnoreCase(request.getMethod())
                || !REGISTRATION_PATH.equals(request.getServletPath())) return true;
        if (limiter.tryAcquire(request.getRemoteAddr())) return true;

        response.setStatus(429);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(ERROR_BODY);
        return false;
    }
}
