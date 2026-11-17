package com.caresync.backend.hospital;

import com.caresync.backend.hospital.controller.PublicHospitalRegistrationRateLimitInterceptor;
import com.caresync.backend.hospital.service.PublicHospitalRegistrationRateLimiter;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PublicHospitalRegistrationRateLimiterTests {
    @Test
    void limitsRequestsPerClientAndResetsAfterTheWindow() {
        MutableClock clock = new MutableClock(Instant.parse("2026-01-01T00:00:00Z"));
        PublicHospitalRegistrationRateLimiter limiter = new PublicHospitalRegistrationRateLimiter(
                2, Duration.ofMinutes(15), clock, 20);

        assertTrue(limiter.tryAcquire("192.0.2.10"));
        assertTrue(limiter.tryAcquire("192.0.2.10"));
        assertFalse(limiter.tryAcquire("192.0.2.10"));
        assertTrue(limiter.tryAcquire("192.0.2.11"));

        clock.advance(Duration.ofMinutes(15));
        assertTrue(limiter.tryAcquire("192.0.2.10"));
    }

    @Test
    void concurrentRequestsCannotExceedTheConfiguredAllowance() throws Exception {
        int allowance = 7;
        PublicHospitalRegistrationRateLimiter limiter = new PublicHospitalRegistrationRateLimiter(
                allowance, Duration.ofMinutes(15), Clock.systemUTC(), 20);
        int totalRequests = 40;
        CountDownLatch start = new CountDownLatch(1);
        AtomicInteger allowed = new AtomicInteger();
        ExecutorService executor = Executors.newFixedThreadPool(8);
        try {
            List<Future<?>> futures = new ArrayList<>();
            for (int i = 0; i < totalRequests; i++) {
                futures.add(executor.submit(() -> {
                    if (!start.await(10, java.util.concurrent.TimeUnit.SECONDS)) {
                        throw new IllegalStateException("Rate limit test did not start");
                    }
                    if (limiter.tryAcquire("198.51.100.7")) allowed.incrementAndGet();
                    return null;
                }));
            }
            start.countDown();
            for (Future<?> future : futures) future.get();
            assertEquals(allowance, allowed.get());
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void interceptorReturnsSafe429BeforeControllerValidationRuns() throws Exception {
        PublicHospitalRegistrationRateLimiter limiter = new PublicHospitalRegistrationRateLimiter(
                1, Duration.ofMinutes(15), Clock.systemUTC(), 10);
        PublicHospitalRegistrationRateLimitInterceptor interceptor =
                new PublicHospitalRegistrationRateLimitInterceptor(limiter);
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/hospital-registrations");
        request.setServletPath("/api/v1/hospital-registrations");
        request.setRemoteAddr("203.0.113.4");
        MockHttpServletResponse firstResponse = new MockHttpServletResponse();
        MockHttpServletResponse limitedResponse = new MockHttpServletResponse();

        assertTrue(interceptor.preHandle(request, firstResponse, new Object()));
        assertFalse(interceptor.preHandle(request, limitedResponse, new Object()));
        assertEquals(429, limitedResponse.getStatus());
        assertTrue(limitedResponse.getContentType().startsWith("application/json"));
        assertEquals("{\"error\":\"Too many registration requests. Try again later.\"}",
                limitedResponse.getContentAsString());
    }

    private static final class MutableClock extends Clock {
        private final AtomicReference<Instant> instant;

        private MutableClock(Instant instant) { this.instant = new AtomicReference<>(instant); }
        private void advance(Duration duration) { instant.updateAndGet(value -> value.plus(duration)); }
        @Override public ZoneId getZone() { return ZoneId.of("UTC"); }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return instant.get(); }
    }
}
