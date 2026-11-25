package com.caresync.backend.hospital.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

/** Bounded per-process protection for the public hospital registration endpoint. */
@Component
public final class PublicHospitalRegistrationRateLimiter {
    private static final int DEFAULT_MAX_TRACKED_CLIENTS = 10_000;

    private final int maxRequests;
    private final Duration window;
    private final Clock clock;
    private final int maxTrackedClients;
    private final LinkedHashMap<String, WindowCounter> counters = new LinkedHashMap<>(16, 0.75f, true);

    @Autowired
    public PublicHospitalRegistrationRateLimiter(
            @Value("${caresync.hospital.registration.rate-limit.max-attempts:5}") int maxRequests,
            @Value("${caresync.hospital.registration.rate-limit.window:PT15M}") Duration window) {
        this(maxRequests, window, Clock.systemUTC(), DEFAULT_MAX_TRACKED_CLIENTS);
    }

    public PublicHospitalRegistrationRateLimiter(int maxRequests, Duration window, Clock clock,
                                                  int maxTrackedClients) {
        if (maxRequests < 1 || window.isZero() || window.isNegative() || maxTrackedClients < 1) {
            throw new IllegalArgumentException("Rate limiter settings must be positive");
        }
        this.maxRequests = maxRequests;
        this.window = window;
        this.clock = clock;
        this.maxTrackedClients = maxTrackedClients;
    }

    public synchronized boolean tryAcquire(String clientKey) {
        Instant now = clock.instant();
        String key = clientKey == null || clientKey.isBlank() ? "unknown" : clientKey;
        WindowCounter counter = counters.get(key);
        if (counter == null || !now.isBefore(counter.startedAt().plus(window))) {
            if (counter == null && counters.size() >= maxTrackedClients) {
                Iterator<Map.Entry<String, WindowCounter>> iterator = counters.entrySet().iterator();
                if (iterator.hasNext()) {
                    iterator.next();
                    iterator.remove();
                }
            }
            counters.put(key, new WindowCounter(now, 1));
            return true;
        }
        if (counter.requests() >= maxRequests) return false;
        counters.put(key, new WindowCounter(counter.startedAt(), counter.requests() + 1));
        return true;
    }

    private record WindowCounter(Instant startedAt, int requests) {}
}
