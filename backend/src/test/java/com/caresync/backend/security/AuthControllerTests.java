package com.caresync.backend.security;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.jdbc.core.JdbcTemplate;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789",
        "caresync.security.cors.allowed-origins=https://client.caresync.test",
        "spring.datasource.url=jdbc:h2:mem:caresync-auth-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
@AutoConfigureMockMvc
class AuthControllerTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AuthAccountRepository accounts;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired SecurityAuditEventRepository auditEvents;
    @Autowired JwtEncoder jwtEncoder;
    @Autowired AuthService authService;
    @Autowired JdbcTemplate jdbc;
    @Autowired RefreshTokenCleanupJob cleanupJob;

    @BeforeEach
    void prepareAccount() {
        refreshTokens.deleteAll();
        auditEvents.deleteAll();
        accounts.deleteAll();
        accounts.save(new AuthAccount("doctor1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Test Doctor", "DOCTOR", 42L));
    }

    @Test
    void protectedEndpointRejectsAnonymousAndAcceptsValidAccessToken() throws Exception {
        mvc.perform(get("/api/auth/me")).andExpect(status().isUnauthorized());
        JsonNode tokens = login("doctor1", "CorrectHorseBattery9!");
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + tokens.path("accessToken").asText()))
                .andExpect(status().isOk());
    }

    @Test
    void badPasswordIsGenericAndAccountLocksAfterFiveFailures() throws Exception {
        for (int i = 0; i < 5; i++) loginStatus("doctor1", "wrong-password", 401);
        loginStatus("doctor1", "CorrectHorseBattery9!", 401);
    }

    @Test
    void refreshRotatesTokenAndLogoutRevokesRenewal() throws Exception {
        JsonNode initial = login("doctor1", "CorrectHorseBattery9!");
        String firstRefresh = initial.path("refreshToken").asText();
        JsonNode rotated = mapper.readTree(mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", firstRefresh))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());

        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", firstRefresh))))
                .andExpect(status().isUnauthorized());

        String secondRefresh = rotated.path("refreshToken").asText();
        mvc.perform(post("/api/auth/logout").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", secondRefresh))))
                .andExpect(status().isNoContent());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", secondRefresh))))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void malformedLoginRequestIsRejected() throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("{"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void authenticationDtoDiagnosticsRedactPasswordsAndTokens() {
        String password = "SensitivePasswordValue";
        String refresh = "SensitiveRefreshTokenValue";
        assertFalse(new AuthDtos.LoginRequest("private-user", password).toString().contains(password));
        assertFalse(new AuthDtos.LoginRequest("private-user", password).toString().contains("private-user"));
        assertFalse(new AuthDtos.RefreshRequest(refresh).toString().contains(refresh));
        assertFalse(new AuthDtos.LogoutRequest(refresh).toString().contains(refresh));
        String diagnostics = new AuthDtos.TokenResponse("access-secret", "refresh-secret", "Bearer", 900,
                new AuthDtos.UserResponse(1, "private-user", "Private Name", "DOCTOR", 1L)).toString();
        assertFalse(diagnostics.contains("access-secret"));
        assertFalse(diagnostics.contains("refresh-secret"));
        assertFalse(diagnostics.contains("private-user"));
    }

    @Test
    void jwtRejectsExpiryIssuerAudienceSignatureAndMalformedInput() throws Exception {
        Instant now = Instant.now();
        expectUnauthorized(jwt("caresync", "caresync-api", now.minusSeconds(1200), now.minusSeconds(600)));
        expectUnauthorized(jwt("wrong-issuer", "caresync-api", now, now.plusSeconds(300)));
        expectUnauthorized(jwt("caresync", "another-api", now, now.plusSeconds(300)));

        String valid = jwt("caresync", "caresync-api", now, now.plusSeconds(300));
        int signatureStart = valid.lastIndexOf('.') + 1;
        expectUnauthorized(valid.substring(0, signatureStart) + "AAAA");
        expectUnauthorized("not.a.jwt");
        expectUnauthorized(jwtMissingRequiredClaim());
        expectUnauthorized(jwtWithWrongClaimType());
        expectUnauthorized(jwtUsingWrongAlgorithm());
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer ")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/auth/me").header("Authorization", "Basic abc")).andExpect(status().isUnauthorized());
    }

    @Test
    void configuredCorsOriginIsAllowedAndOtherOriginsAreRejected() throws Exception {
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options("/api/auth/me")
                        .header("Origin", "https://client.caresync.test")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.header()
                        .string("Access-Control-Allow-Origin", "https://client.caresync.test"));

        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options("/api/auth/me")
                        .header("Origin", "https://untrusted.example")
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden());
    }

    @Test
    void unknownRoutesAreDeniedByDefaultAndSecurityHeadersArePresent() throws Exception {
        JsonNode issued = login("doctor1", "CorrectHorseBattery9!");
        String bearer = "Bearer " + issued.path("accessToken").asText();
        mvc.perform(get("/api/unmapped-business-route").header("Authorization", bearer))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/unmapped-business-route"))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/auth/me").header("Authorization", bearer))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.header()
                        .string("X-Frame-Options", "DENY"))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.header()
                        .string("X-Content-Type-Options", "nosniff"))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.header()
                        .string("Referrer-Policy", "no-referrer"));
    }

    @Test
    void accountDeactivationInvalidatesAccessAndRefreshTokensImmediately() throws Exception {
        JsonNode issued = login("doctor1", "CorrectHorseBattery9!");
        long id = accounts.findByUsername("doctor1").orElseThrow().getId();
        authService.deactivateAccount(id);

        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + issued.path("accessToken").asText()))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", issued.path("refreshToken").asText()))))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void tokenIsRejectedWhenDatabaseHospitalScopeChanges() throws Exception {
        JsonNode issued = login("doctor1", "CorrectHorseBattery9!");
        long id = accounts.findByUsername("doctor1").orElseThrow().getId();
        jdbc.update("UPDATE auth_accounts SET hospital_id = ? WHERE id = ?", 99L, id);
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + issued.path("accessToken").asText()))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", issued.path("refreshToken").asText()))))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void changedRoleInvalidatesPreviouslyIssuedToken() throws Exception {
        JsonNode issued = login("doctor1", "CorrectHorseBattery9!");
        long id = accounts.findByUsername("doctor1").orElseThrow().getId();
        jdbc.update("UPDATE auth_accounts SET role = ? WHERE id = ?", "NURSE", id);
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + issued.path("accessToken").asText()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void tokenVersionMismatchInvalidatesPreviouslyIssuedToken() throws Exception {
        JsonNode issued = login("doctor1", "CorrectHorseBattery9!");
        long id = accounts.findByUsername("doctor1").orElseThrow().getId();
        jdbc.update("UPDATE auth_accounts SET token_version = token_version + 1 WHERE id = ?", id);
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + issued.path("accessToken").asText()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void inactiveAccountCannotLoginAndExpiredLockoutStartsANewAttemptWindow() throws Exception {
        jdbc.update("UPDATE auth_accounts SET active = FALSE WHERE username = ?", "doctor1");
        loginStatus("doctor1", "CorrectHorseBattery9!", 401);

        jdbc.update("UPDATE auth_accounts SET active = TRUE, failed_login_attempts = 5, locked_until = ? WHERE username = ?",
                Instant.now().minusSeconds(1), "doctor1");
        loginStatus("doctor1", "wrong-password", 401);
        AuthAccount afterExpiredLock = accounts.findByUsername("doctor1").orElseThrow();
        assertEquals(1, afterExpiredLock.getFailedLoginAttempts());
        assertEquals(null, afterExpiredLock.getLockedUntil());
    }

    @Test
    void successfulLoginResetsFailedAttemptCounter() throws Exception {
        loginStatus("doctor1", "wrong-password", 401);
        loginStatus("doctor1", "wrong-password", 401);
        login("doctor1", "CorrectHorseBattery9!");
        AuthAccount account = accounts.findByUsername("doctor1").orElseThrow();
        assertEquals(0, account.getFailedLoginAttempts());
        assertEquals(null, account.getLockedUntil());
    }

    @Test
    void superAdminCannotChooseHospitalBySubmittingClientSuppliedId() throws Exception {
        accounts.save(new AuthAccount("root", passwordEncoder.encode("AnotherStrongPassphrase9!"),
                "Platform Admin", "SUPER_ADMIN", null));
        String body = mapper.writeValueAsString(java.util.Map.of(
                "username", "root", "password", "AnotherStrongPassphrase9!", "hospitalId", 999L));
        JsonNode response = mapper.readTree(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        assertEquals(true, response.path("user").path("hospitalId").isNull());
    }

    @Test
    void reusingRefreshTokenRevokesItsEntireFamily() throws Exception {
        JsonNode initial = login("doctor1", "CorrectHorseBattery9!");
        JsonNode rotated = refresh(initial.path("refreshToken").asText());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", initial.path("refreshToken").asText()))))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", rotated.path("refreshToken").asText()))))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void concurrentRefreshRequestsAllowOneRotationAndRevokeFamilyOnReplay() throws Exception {
        JsonNode initial = login("doctor1", "CorrectHorseBattery9!");
        String refreshToken = initial.path("refreshToken").asText();
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Future<MvcResult> first = pool.submit(() -> refreshConcurrently(start, refreshToken));
            Future<MvcResult> second = pool.submit(() -> refreshConcurrently(start, refreshToken));
            start.countDown();
            MvcResult a = first.get();
            MvcResult b = second.get();
            int successCount = (a.getResponse().getStatus() == 200 ? 1 : 0) + (b.getResponse().getStatus() == 200 ? 1 : 0);
            assertEquals(1, successCount);
            MvcResult successful = a.getResponse().getStatus() == 200 ? a : b;
            JsonNode rotated = mapper.readTree(successful.getResponse().getContentAsString());
            mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                            .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", rotated.path("refreshToken").asText()))))
                    .andExpect(status().isUnauthorized());
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    void concurrentFailedLoginsPreserveTheFiveAttemptLockout() throws Exception {
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(5);
        try {
            Future<MvcResult>[] attempts = new Future[5];
            for (int i = 0; i < attempts.length; i++) {
                attempts[i] = pool.submit(() -> {
                    start.await();
                    return mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                            .content(mapper.writeValueAsString(java.util.Map.of("username", "doctor1", "password", "wrong"))))
                            .andReturn();
                });
            }
            start.countDown();
            for (Future<MvcResult> attempt : attempts) assertEquals(401, attempt.get().getResponse().getStatus());
        } finally {
            pool.shutdownNow();
        }
        AuthAccount account = accounts.findByUsername("doctor1").orElseThrow();
        assertEquals(5, account.getFailedLoginAttempts());
        assertEquals(true, account.getLockedUntil().isAfter(Instant.now()));
        loginStatus("doctor1", "CorrectHorseBattery9!", 401);
    }

    @Test
    void expiredRefreshIsDeniedAndCleanupRemovesOnlyExpiredRows() throws Exception {
        AuthAccount account = accounts.findByUsername("doctor1").orElseThrow();
        String token = "expired-test-refresh-token";
        refreshTokens.save(new RefreshToken(account, sha256(token), Instant.now().minusSeconds(1), 42L, "test-family"));
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", token))))
                .andExpect(status().isUnauthorized());
        assertEquals(1, cleanupJob.deleteExpiredNow());
    }

    private JsonNode login(String username, String password) throws Exception {
        return mapper.readTree(mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("username", username, "password", password))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
    }

    private void loginStatus(String username, String password, int status) throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("username", username, "password", password))))
                .andExpect(status().is(status));
    }

    private JsonNode refresh(String refreshToken) throws Exception {
        return mapper.readTree(mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", refreshToken))))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
    }

    private MvcResult refreshConcurrently(CountDownLatch start, String refreshToken) throws Exception {
        start.await();
        return mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(java.util.Map.of("refreshToken", refreshToken)))).andReturn();
    }

    private void expectUnauthorized(String token) throws Exception {
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    private String jwt(String issuer, String audience, Instant issuedAt, Instant expiresAt) {
        var claims = JwtClaimsSet.builder().issuer(issuer).audience(List.of(audience)).subject("doctor1")
                .issuedAt(issuedAt).expiresAt(expiresAt).claim("uid", accounts.findByUsername("doctor1").orElseThrow().getId())
                .claim("name", "Test Doctor").claim("role", "DOCTOR").claim("hospitalId", 42L).claim("ver", 0L).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).type("JWT").build(), claims))
                .getTokenValue();
    }

    private String jwtMissingRequiredClaim() {
        var claims = JwtClaimsSet.builder().issuer("caresync").audience(List.of("caresync-api"))
                .subject("doctor1").issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(300))
                .claim("name", "Test Doctor").claim("role", "DOCTOR").claim("hospitalId", 42L).claim("ver", 0L).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).type("JWT").build(), claims))
                .getTokenValue();
    }

    private String jwtWithWrongClaimType() {
        var claims = JwtClaimsSet.builder().issuer("caresync").audience(List.of("caresync-api"))
                .subject("doctor1").issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(300))
                .claim("uid", "not-an-integer").claim("name", "Test Doctor").claim("role", "DOCTOR")
                .claim("hospitalId", 42L).claim("ver", 0L).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).type("JWT").build(), claims))
                .getTokenValue();
    }

    private String jwtUsingWrongAlgorithm() throws Exception {
        var claims = new com.nimbusds.jwt.JWTClaimsSet.Builder().issuer("caresync").audience("caresync-api")
                .subject("doctor1").issueTime(java.util.Date.from(Instant.now()))
                .expirationTime(java.util.Date.from(Instant.now().plusSeconds(300)))
                .claim("uid", accounts.findByUsername("doctor1").orElseThrow().getId())
                .claim("name", "Test Doctor").claim("role", "DOCTOR").claim("hospitalId", 42L).claim("ver", 0L).build();
        var signed = new com.nimbusds.jwt.SignedJWT(
                new com.nimbusds.jose.JWSHeader(com.nimbusds.jose.JWSAlgorithm.HS384), claims);
        signed.sign(new com.nimbusds.jose.crypto.MACSigner(
                "local-test-secret-change-before-deployment-123456789".getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        return signed.serialize();
    }

    private String sha256(String value) throws Exception {
        return java.util.HexFormat.of().formatHex(java.security.MessageDigest.getInstance("SHA-256")
                .digest(value.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
    }
}
