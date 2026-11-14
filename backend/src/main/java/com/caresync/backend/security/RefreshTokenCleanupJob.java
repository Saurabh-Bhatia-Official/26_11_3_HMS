package com.caresync.backend.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;

@Component
public class RefreshTokenCleanupJob {
    private static final Logger log = LoggerFactory.getLogger(RefreshTokenCleanupJob.class);
    private final RefreshTokenRepository tokens;
    public RefreshTokenCleanupJob(RefreshTokenRepository tokens) { this.tokens = tokens; }

    @Scheduled(fixedDelayString = "PT6H")
    @Transactional
    public void deleteExpired() {
        int removed = deleteExpiredNow();
        if (removed > 0) log.info("Removed {} expired authentication refresh-token records", removed);
    }

    @Transactional
    public int deleteExpiredNow() { return tokens.deleteExpired(Instant.now()); }
}
