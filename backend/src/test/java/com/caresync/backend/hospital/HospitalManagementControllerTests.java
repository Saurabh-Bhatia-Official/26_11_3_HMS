package com.caresync.backend.hospital;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalRegistration;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.hospital.repository.HospitalRegistrationRepository;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.hospital.service.HospitalIdGenerator;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.security.SecurityAuditEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789",
        "spring.datasource.url=jdbc:h2:mem:caresync-hospital-module-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
@AutoConfigureMockMvc
@Import(HospitalManagementControllerTests.TestBeans.class)
class HospitalManagementControllerTests {
    @Autowired MockMvc mvc;
    @Autowired HospitalRepository hospitals;
    @Autowired HospitalRegistrationRepository registrations;
    @Autowired AuthAccountRepository accounts;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired SecurityAuditEventRepository auditEvents;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired @Qualifier("hospitalIdGenerator") HospitalIdGenerator databaseSequenceIdGenerator;

    @BeforeEach
    void clearIsolatedTestDatabase() {
        refreshTokens.deleteAll();
        registrations.deleteAll();
        hospitals.deleteAll();
        auditEvents.deleteAll();
        accounts.deleteAll();
        TestBeans.candidateIndex.set(0);
    }

    @Test
    void publicRegistrationPersistsPendingHospitalAndHashedFirstAdminCredentials() throws Exception {
        String body = registrationJson("first-admin", "RegistrationPassphrase9!");
        String response = mvc.perform(post("/api/v1/hospital-registrations")
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andReturn().getResponse().getContentAsString();

        assertEquals(1, registrations.count());
        assertEquals(1, hospitals.count());
        Hospital hospital = hospitals.findAll().getFirst();
        HospitalRegistration registration = registrations.findAll().getFirst();
        assertEquals(HospitalStatus.PENDING, hospital.getStatus());
        assertNull(hospital.getHospitalId());
        assertEquals("first-admin", registration.getAdminUsername());
        assertNotNull(registration.getAdminPasswordHash());
        assertTrue(passwordEncoder.matches("RegistrationPassphrase9!", registration.getAdminPasswordHash()));
        assertTrue(!registration.getAdminPasswordHash().equals("RegistrationPassphrase9!"));
        assertTrue(response.contains(registration.getId().toString()));
    }

    @Test
    void invalidRegistrationIsRejectedByValidation() throws Exception {
        mvc.perform(post("/api/v1/hospital-registrations")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"code\":\"X\",\"type\":\"Clinic\",\"adminUsername\":\"ab\",\"adminPassword\":\"short\",\"adminFullName\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Invalid request"));
        assertEquals(0, registrations.count());
    }

    @Test
    void duplicatePendingAdminUsernameIsRejectedWithoutCreatingAnotherHospital() throws Exception {
        mvc.perform(post("/api/v1/hospital-registrations").contentType(MediaType.APPLICATION_JSON)
                        .content(registrationJson("shared-admin", "RegistrationPassphrase9!")))
                .andExpect(status().isAccepted());
        mvc.perform(post("/api/v1/hospital-registrations").contentType(MediaType.APPLICATION_JSON)
                        .content(registrationJson("SHARED-ADMIN", "AnotherPassphrase9!")))
                .andExpect(status().isConflict());
        assertEquals(1, hospitals.count());
        assertEquals(1, registrations.count());
    }

    @Test
    void concurrentDuplicateAdminUsernameSubmissionCreatesOnlyOnePendingRegistration() throws Exception {
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Future<Integer> first = executor.submit(() -> submitAfter(start, "racing-admin"));
            Future<Integer> second = executor.submit(() -> submitAfter(start, "RACING-ADMIN"));
            start.countDown();
            int firstStatus = first.get(30, TimeUnit.SECONDS);
            int secondStatus = second.get(30, TimeUnit.SECONDS);
            assertTrue((firstStatus == 202 && secondStatus == 409) || (firstStatus == 409 && secondStatus == 202));
            assertEquals(1, registrations.count());
            assertEquals(1, hospitals.count());
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void approvalIsPlatformAdminOnlyAndAllocatesUniqueTwelveDigitId() throws Exception {
        String firstId = registerAndGetRegistrationId("hospital-admin", "HospitalPassword9!");
        Hospital collision = new Hospital(UUID.randomUUID(), "Existing", "EXIST", "Clinic", null, null,
                null, null, Instant.now());
        collision.approve(123_456_789_012L);
        hospitals.saveAndFlush(collision);

        mvc.perform(get("/api/v1/platform/hospital-registrations"))
                .andExpect(status().isUnauthorized());

        String doctorToken = createTokenAccount("review-doctor", "DOCTOR", 123_456_789_012L);
        mvc.perform(post("/api/v1/platform/hospital-registrations/{id}/approve", firstId)
                        .header("Authorization", "Bearer " + doctorToken))
                .andExpect(status().isForbidden());
        assertEquals(1, accounts.count());

        String centralToken = createTokenAccount("central-reviewer", "SUPER_ADMIN", null);
        mvc.perform(get("/api/v1/platform/hospital-registrations")
                        .header("Authorization", "Bearer " + centralToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].firstAdminUsername").value("hospital-admin"));
        mvc.perform(post("/api/v1/platform/hospital-registrations/{id}/approve", firstId)
                        .header("Authorization", "Bearer " + centralToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hospitalId").value("123456789013"))
                .andExpect(jsonPath("$.status").value("APPROVED"));

        Hospital approved = hospitals.findAll().stream()
                .filter(hospital -> "North Clinic".equals(hospital.getName())).findFirst().orElseThrow();
        assertNotNull(approved.getId());
        assertEquals(HospitalStatus.APPROVED, approved.getStatus());
        assertEquals(123_456_789_013L, approved.getHospitalId());
        assertTrue(accounts.findByUsername("hospital-admin").isPresent());
        AuthAccount admin = accounts.findByUsername("hospital-admin").orElseThrow();
        assertEquals("HOSPITAL_SUPER_ADMIN", admin.getRole());
        assertEquals(123_456_789_013L, admin.getHospitalId());
        assertNull(registrations.findAll().stream().filter(r -> r.getId().toString().equals(firstId))
                .findFirst().orElseThrow().getAdminPasswordHash());
        mvc.perform(get("/api/v1/hospitals")).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].hospitalId").value("123456789013"))
                .andExpect(jsonPath("$[0].hospitalUuid").doesNotExist());
    }

    @Test
    void hospitalLoginRequiresSelectedHospitalAndKeepsLegacyLoginPath() throws Exception {
        Hospital hospital = new Hospital(UUID.randomUUID(), "Login Clinic", "LC", "Clinic", null, null,
                null, null, Instant.now());
        hospital.approve(456_789_012_345L);
        hospitals.saveAndFlush(hospital);
        Hospital otherHospital = new Hospital(UUID.randomUUID(), "Other Clinic", "OC", "Clinic", null, null,
                null, null, Instant.now());
        otherHospital.approve(456_789_012_346L);
        hospitals.saveAndFlush(otherHospital);
        accounts.save(new AuthAccount("login-admin", passwordEncoder.encode("HospitalPassword9!"),
                "Hospital Admin", "HOSPITAL_SUPER_ADMIN", 456_789_012_345L));

        mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"login-admin\",\"password\":\"HospitalPassword9!\",\"hospitalId\":\"456789012345\"}"))
                .andExpect(status().isOk());
        mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"login-admin\",\"password\":\"HospitalPassword9!\",\"hospitalId\":\"456789012346\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"login-admin\",\"password\":\"HospitalPassword9!\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void hospitalLoginRejectsPendingSuspendedRejectedAndInvalidCredentials() throws Exception {
        Hospital pending = new Hospital(UUID.randomUUID(), "Pending", "P", "Clinic", null, null, null, null, Instant.now());
        hospitals.saveAndFlush(pending);
        Hospital suspended = new Hospital(UUID.randomUUID(), "Suspended", "S", "Clinic", null, null, null, null, Instant.now());
        suspended.approve(456_789_012_345L);
        suspended.suspend();
        hospitals.saveAndFlush(suspended);
        Hospital rejected = new Hospital(UUID.randomUUID(), "Rejected", "R", "Clinic", null, null, null, null, Instant.now());
        rejected.reject();
        hospitals.saveAndFlush(rejected);

        accounts.save(new AuthAccount("pending-admin", passwordEncoder.encode("HospitalPassword9!"),
                "Pending Admin", "HOSPITAL_SUPER_ADMIN", 456_789_012_344L));
        accounts.save(new AuthAccount("suspended-admin", passwordEncoder.encode("HospitalPassword9!"),
                "Suspended Admin", "HOSPITAL_SUPER_ADMIN", 456_789_012_345L));
        accounts.save(new AuthAccount("rejected-admin", passwordEncoder.encode("HospitalPassword9!"),
                "Rejected Admin", "HOSPITAL_SUPER_ADMIN", 456_789_012_346L));

        for (String credentials : new String[] {
                "\"username\":\"pending-admin\",\"password\":\"HospitalPassword9!\",\"hospitalId\":\"456789012344\"",
                "\"username\":\"suspended-admin\",\"password\":\"HospitalPassword9!\",\"hospitalId\":\"456789012345\"",
                "\"username\":\"rejected-admin\",\"password\":\"HospitalPassword9!\",\"hospitalId\":\"456789012346\"",
                "\"username\":\"suspended-admin\",\"password\":\"WrongPassword9!\",\"hospitalId\":\"456789012345\""
        }) {
            mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                            .content("{" + credentials + "}"))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Test
    void hospitalProfileIsResolvedFromAuthenticatedHospitalOnly() throws Exception {
        Hospital hospital = new Hospital(UUID.randomUUID(), "Scoped Clinic", "SC", "Clinic", "1 Main St",
                null, null, null, Instant.now());
        hospital.approve(678_901_234_567L);
        hospitals.saveAndFlush(hospital);
        String hospitalToken = createTokenAccount("scoped-admin", "HOSPITAL_SUPER_ADMIN", 678_901_234_567L);
        mvc.perform(get("/api/v1/hospitals/me").header("Authorization", "Bearer " + hospitalToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hospitalId").value("678901234567"))
                .andExpect(jsonPath("$.name").value("Scoped Clinic"));
        mvc.perform(get("/api/v1/hospitals/me").param("hospitalId", "111111111111")
                        .header("Authorization", "Bearer " + hospitalToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hospitalId").value("678901234567"));

        String centralToken = createTokenAccount("central-profile", "SUPER_ADMIN", null);
        mvc.perform(get("/api/v1/hospitals/me").header("Authorization", "Bearer " + centralToken))
                .andExpect(status().isForbidden());

        hospital.suspend();
        hospitals.saveAndFlush(hospital);
        mvc.perform(get("/api/v1/hospitals/me").header("Authorization", "Bearer " + hospitalToken))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void refreshRotationAndLogoutRevokeAccessForTheSessionFamily() throws Exception {
        Hospital hospital = new Hospital(UUID.randomUUID(), "Session Clinic", "SC", "Clinic", null, null,
                null, null, Instant.now());
        hospital.approve(789_012_345_678L);
        hospitals.saveAndFlush(hospital);
        accounts.save(new AuthAccount("session-admin", passwordEncoder.encode("HospitalPassword9!"),
                "Hospital Admin", "HOSPITAL_SUPER_ADMIN", 789_012_345_678L));

        String loginBody = mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"session-admin\",\"password\":\"HospitalPassword9!\",\"hospitalId\":\"789012345678\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        var mapper = new tools.jackson.databind.ObjectMapper();
        var loginJson = mapper.readTree(loginBody);
        String access = loginJson.path("accessToken").asText();
        String originalRefresh = loginJson.path("refreshToken").asText();

        String rotatedBody = mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + originalRefresh + "\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        var rotatedJson = mapper.readTree(rotatedBody);
        String rotatedAccess = rotatedJson.path("accessToken").asText();
        String rotatedRefresh = rotatedJson.path("refreshToken").asText();
        assertTrue(!originalRefresh.equals(rotatedRefresh));
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + rotatedAccess))
                .andExpect(status().isOk());

        mvc.perform(post("/api/auth/logout").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + rotatedRefresh + "\"}"))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + rotatedAccess))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + rotatedRefresh + "\"}"))
                .andExpect(status().isUnauthorized());
        assertTrue(!access.isBlank());
    }

    @Test
    void refreshRejectsAndRevokesFamilyWhenHospitalIsSuspended() throws Exception {
        Hospital hospital = new Hospital(UUID.randomUUID(), "Suspension Clinic", "SC", "Clinic", null, null,
                null, null, Instant.now());
        hospital.approve(789_012_345_678L);
        hospitals.saveAndFlush(hospital);
        accounts.save(new AuthAccount("suspended-session", passwordEncoder.encode("HospitalPassword9!"),
                "Hospital Admin", "HOSPITAL_SUPER_ADMIN", 789_012_345_678L));
        String loginBody = mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"suspended-session\",\"password\":\"HospitalPassword9!\",\"hospitalId\":\"789012345678\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String refresh = new tools.jackson.databind.ObjectMapper().readTree(loginBody).path("refreshToken").asText();

        hospital.suspend();
        hospitals.saveAndFlush(hospital);
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + refresh + "\"}"))
                .andExpect(status().isUnauthorized());
        assertTrue(refreshTokens.findAll().stream().noneMatch(token -> !token.isRevoked()));
    }

    @Test
    void exhaustedHospitalIdCollisionsReturnSafeUnavailableResponse() throws Exception {
        for (long id : new long[] {123_456_789_012L, 123_456_789_013L}) {
            Hospital existing = new Hospital(UUID.randomUUID(), "Existing " + id, "EX" + id, "Clinic",
                    null, null, null, null, Instant.now());
            existing.approve(id);
            hospitals.saveAndFlush(existing);
        }
        String registrationId = registerAndGetRegistrationId("exhausted-id-admin", "HospitalPassword9!");
        String centralToken = createTokenAccount("exhausted-id-reviewer", "SUPER_ADMIN", null);
        mvc.perform(post("/api/v1/platform/hospital-registrations/{id}/approve", registrationId)
                        .header("Authorization", "Bearer " + centralToken))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.error").value("Hospital ID allocation is temporarily unavailable"));
        assertEquals(0, accounts.findAll().stream().filter(account -> "exhausted-id-admin".equals(account.getUsername())).count());
    }

    @Test
    void concurrentApprovalsReceiveDistinctTwelveDigitIds() throws Exception {
        String first = registerAndGetRegistrationId("concurrent-admin-one", "HospitalPassword9!");
        String second = registerAndGetRegistrationId("concurrent-admin-two", "HospitalPassword9!");
        String centralToken = createTokenAccount("concurrent-reviewer", "SUPER_ADMIN", null);
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Future<String> firstResponse = executor.submit(() -> approveAfter(start, first, centralToken));
            Future<String> secondResponse = executor.submit(() -> approveAfter(start, second, centralToken));
            start.countDown();
            String firstId = firstResponse.get(30, TimeUnit.SECONDS);
            String secondId = secondResponse.get(30, TimeUnit.SECONDS);
            assertTrue(firstId.matches("[0-9]{12}"));
            assertTrue(secondId.matches("[0-9]{12}"));
            assertTrue(!firstId.equals(secondId));
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void databaseSequenceAllocatesDistinctIdsConcurrently() throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(4);
        try {
            var candidates = java.util.stream.IntStream.range(0, 8)
                    .mapToObj(index -> executor.submit(databaseSequenceIdGenerator::nextCandidate))
                    .map(future -> {
                        try {
                            return future.get(20, TimeUnit.SECONDS);
                        } catch (Exception exception) {
                            throw new AssertionError("Hospital ID sequence allocation failed", exception);
                        }
                    })
                    .toList();
            assertEquals(8, candidates.stream().distinct().count());
            assertTrue(candidates.stream().allMatch(id -> id >= 100_000_000_000L && id <= 999_999_999_999L));
        } finally {
            executor.shutdownNow();
        }
    }

    private String approveAfter(CountDownLatch start, String registrationId, String token) throws Exception {
        if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("Approval test did not start");
        String body = mvc.perform(post("/api/v1/platform/hospital-registrations/{id}/approve", registrationId)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return new tools.jackson.databind.ObjectMapper().readTree(body).path("hospitalId").asText();
    }

    @Test
    void rejectedRegistrationDoesNotProvisionAccountOrAppearInLoginOptions() throws Exception {
        String registrationId = registerAndGetRegistrationId("rejected-admin", "HospitalPassword9!");
        String centralToken = createTokenAccount("central-reviewer", "SUPER_ADMIN", null);

        mvc.perform(post("/api/v1/platform/hospital-registrations/{id}/reject", registrationId)
                        .header("Authorization", "Bearer " + centralToken))
                .andExpect(status().isNoContent());

        assertEquals(0, accounts.findAll().stream().filter(a -> "rejected-admin".equals(a.getUsername())).count());
        assertEquals(HospitalStatus.REJECTED, hospitals.findAll().getFirst().getStatus());
        assertTrue(registrations.findAll().getFirst().getAdminPasswordHash() == null);
        mvc.perform(get("/api/v1/hospitals")).andExpect(status().isOk()).andExpect(jsonPath("$").isEmpty());
    }

    private String registerAndGetRegistrationId(String username, String password) throws Exception {
        String response = mvc.perform(post("/api/v1/hospital-registrations")
                        .contentType(MediaType.APPLICATION_JSON).content(registrationJson(username, password)))
                .andExpect(status().isAccepted()).andReturn().getResponse().getContentAsString();
        return new tools.jackson.databind.ObjectMapper().readTree(response).path("registrationId").asText();
    }

    private int submitAfter(CountDownLatch start, String username) throws Exception {
        if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("Registration test did not start");
        return mvc.perform(post("/api/v1/hospital-registrations").contentType(MediaType.APPLICATION_JSON)
                        .content(registrationJson(username, "HospitalPassword9!")))
                .andReturn().getResponse().getStatus();
    }

    private String createTokenAccount(String username, String role, Long hospitalId) {
        AuthAccount account = accounts.saveAndFlush(new AuthAccount(username, passwordEncoder.encode("StrongPassword9!"),
                "Test Account", role, hospitalId));
        // The normal login API produces the same signed JWT and loads authoritative account state.
        try {
            String path = "SUPER_ADMIN".equals(role) ? "/api/auth/login" : "/api/auth/hospital-login";
            java.util.Map<String, String> loginBody = new java.util.HashMap<>();
            loginBody.put("username", username);
            loginBody.put("password", "StrongPassword9!");
            if (hospitalId != null) loginBody.put("hospitalId", Long.toString(hospitalId));
            String response = mvc.perform(post(path).contentType(MediaType.APPLICATION_JSON)
                            .content(new tools.jackson.databind.ObjectMapper().writeValueAsString(loginBody)))
                    .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
            return new tools.jackson.databind.ObjectMapper().readTree(response).path("accessToken").asText();
        } catch (Exception exception) {
            throw new AssertionError("Test account could not obtain an access token: " + account.getId(), exception);
        }
    }

    private static String registrationJson(String username, String password) {
        return """
                {"name":"North Clinic","code":"NC-1","type":"Clinic","address":"1 Health Way",
                 "phone":"+1 555 123 4567","email":"north@example.test","taxId":"TAX-123",
                 "adminUsername":"%s","adminPassword":"%s","adminFullName":"Hospital Admin"}
                """.formatted(username, password);
    }

    @TestConfiguration(proxyBeanMethods = false)
    static class TestBeans {
        static final AtomicInteger candidateIndex = new AtomicInteger();

        @Bean
        @Primary
        HospitalIdGenerator deterministicHospitalIdGenerator() {
            return new HospitalIdGenerator() {
                @Override
                public long nextCandidate() {
                    return candidateIndex.getAndIncrement() == 0 ? 123_456_789_012L : 123_456_789_013L;
                }
            };
        }
    }
}
