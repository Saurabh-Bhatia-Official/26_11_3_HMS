package com.caresync.backend.security;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;

class AccessTokenServiceTests {
    @Test
    void generatesEphemeralSecretWhenLocalProfileIsActive() {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("local");

        assertDoesNotThrow(() -> new AccessTokenService("", environment));
    }

    @Test
    void requiresConfiguredSecretOutsideLocalProfile() {
        MockEnvironment environment = new MockEnvironment();

        assertThrows(IllegalStateException.class, () -> new AccessTokenService("", environment));
    }

    @Test
    void rejectsShortConfiguredSecretEvenInLocalProfile() {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("local");

        assertThrows(IllegalStateException.class, () -> new AccessTokenService("too-short", environment));
    }

    @Test
    void acceptsConfiguredSecretOutsideLocalProfile() {
        MockEnvironment environment = new MockEnvironment();

        assertDoesNotThrow(() -> new AccessTokenService("configured-secret-with-at-least-32-bytes", environment));
    }
}
