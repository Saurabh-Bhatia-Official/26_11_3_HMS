package com.caresync.backend.hospital.controller;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration(proxyBeanMethods = false)
public class HospitalWebConfiguration implements WebMvcConfigurer {
    private final PublicHospitalRegistrationRateLimitInterceptor registrationRateLimit;

    public HospitalWebConfiguration(PublicHospitalRegistrationRateLimitInterceptor registrationRateLimit) {
        this.registrationRateLimit = registrationRateLimit;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(registrationRateLimit).addPathPatterns("/api/v1/hospital-registrations");
    }
}
