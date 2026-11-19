package com.caresync.backend.patient;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.repository.HospitalMembershipRepository;
import com.caresync.backend.membership.repository.MembershipAuditEventRepository;
import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.patient.entity.PatientStatus;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.SecurityAuditEventRepository;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.security.SecurityRole;
import com.caresync.backend.tenant.TenantContextHolder;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789"
})
@AutoConfigureMockMvc
class PatientManagementControllerTests {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper mapper;
    @Autowired PatientRepository patients;
    @Autowired HospitalRepository hospitals;
    @Autowired AuthAccountRepository accounts;
    @Autowired HospitalMembershipRepository memberships;
    @Autowired MembershipAuditEventRepository membershipAuditEvents;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired SecurityAuditEventRepository securityAuditEvents;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired TenantContextHolder tenantContextHolder;

    @BeforeEach
    void clearIsolatedDatabase() {
        jdbc.update("delete from appointment_events");
        jdbc.update("delete from appointments");
        refreshTokens.deleteAll();
        patients.deleteAll();
        membershipAuditEvents.deleteAll();
        memberships.deleteAll();
        securityAuditEvents.deleteAll();
        hospitals.deleteAll();
        accounts.deleteAll();
        assertEquals(null, tenantContextHolder.get());
    }

    @Test
    void createsPatientWithClientUuidAndServerAssignedHospitalUhid() throws Exception {
        Hospital hospital = hospital("Patient Hospital", 234_567_890_123L);
        String token = token(hospital, MembershipRole.RECEPTIONIST, "patient-reception");
        UUID uuid = UUID.randomUUID();

        String response = mvc.perform(post("/api/v1/patients")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createJson(uuid, "Asha Patient", "asha@example.test", "9876543210")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.uuid").value(uuid.toString()))
                .andExpect(jsonPath("$.uhid").value(org.hamcrest.Matchers.matchesPattern("UHID-[0-9]{6,}")))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.archived").value(false))
                .andReturn().getResponse().getContentAsString();

        JsonNode json = mapper.readTree(response);
        assertTrue(json.path("id").longValue() > 0);
        Patient stored = patients.findByUuid(uuid).orElseThrow();
        assertEquals(hospital.getId(), stored.getHospital().getId());
        assertEquals("Asha Patient", stored.getName());
        assertNotNull(stored.getCreatedByAccountId());
        assertTrue(securityAuditEvents.findAll().stream()
                .anyMatch(event -> "PATIENT_CREATED".equals(event.getEventType())));
    }

    @Test
    void clientSuppliedHospitalUuidCannotOverrideMembershipTenant() throws Exception {
        Hospital authorized = hospital("Authorized Tenant", 234_567_890_140L);
        Hospital attackerSelected = hospital("Untrusted Tenant", 234_567_890_141L);
        String authorizedToken = token(authorized, MembershipRole.ADMIN, "patient-tenant-authority");
        UUID uuid = UUID.randomUUID();
        String body = createJson(uuid, "Tenant Bound Patient", null, null)
                .replace("}", ",\"hospitalUuid\":\"" + attackerSelected.getId() + "\"}");

        mvc.perform(post("/api/v1/patients").header("Authorization", bearer(authorizedToken))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated());

        Patient stored = patients.findByUuid(uuid).orElseThrow();
        assertEquals(authorized.getId(), stored.getHospital().getId());
    }

    @Test
    void repeatedCreateWithSameUuidAndPayloadIsIdempotentButChangedPayloadConflicts() throws Exception {
        Hospital hospital = hospital("Idempotency Hospital", 234_567_890_124L);
        String token = token(hospital, MembershipRole.RECEPTIONIST, "patient-idempotent");
        UUID uuid = UUID.randomUUID();
        String body = createJson(uuid, "Retry Patient", null, null);

        String first = mvc.perform(post("/api/v1/patients").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String retry = mvc.perform(post("/api/v1/patients").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        assertEquals(mapper.readTree(first).path("id").longValue(), mapper.readTree(retry).path("id").longValue());
        assertEquals(1, patients.count());

        mvc.perform(post("/api/v1/patients").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(uuid, "Different Patient", null, null)))
                .andExpect(status().isConflict());
    }

    @Test
    void listSearchAndPaginationAreScopedToTheMembershipHospital() throws Exception {
        Hospital first = hospital("First Patient Hospital", 234_567_890_125L);
        Hospital second = hospital("Second Patient Hospital", 234_567_890_126L);
        String firstToken = token(first, MembershipRole.ADMIN, "patient-admin-one");
        String secondToken = token(second, MembershipRole.ADMIN, "patient-admin-two");
        create(firstToken, UUID.randomUUID(), "Lila One", "1111111111");
        create(firstToken, UUID.randomUUID(), "Lila Two", "2222222222");
        create(secondToken, UUID.randomUUID(), "Lila Other", "3333333333");

        mvc.perform(get("/api/v1/patients").param("query", "Lila").param("page", "0").param("size", "1")
                        .header("Authorization", bearer(firstToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1))
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.size").value(1));
        mvc.perform(get("/api/v1/patients").header("Authorization", bearer(secondToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void concurrentRequestsKeepTenantContextIsolated() throws Exception {
        Hospital first = hospital("Concurrent First Hospital", 234_567_890_142L);
        Hospital second = hospital("Concurrent Second Hospital", 234_567_890_143L);
        String firstToken = token(first, MembershipRole.ADMIN, "patient-concurrent-one");
        String secondToken = token(second, MembershipRole.ADMIN, "patient-concurrent-two");
        create(firstToken, UUID.randomUUID(), "First Tenant Patient", null);
        create(secondToken, UUID.randomUUID(), "Second Tenant Patient", null);

        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            for (int attempt = 0; attempt < 10; attempt++) {
                CountDownLatch start = new CountDownLatch(1);
                Future<JsonNode> firstResponse = executor.submit(() -> {
                    if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("start timed out");
                    return mapper.readTree(mvc.perform(get("/api/v1/patients")
                                    .header("Authorization", bearer(firstToken)))
                            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
                });
                Future<JsonNode> secondResponse = executor.submit(() -> {
                    if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("start timed out");
                    return mapper.readTree(mvc.perform(get("/api/v1/patients")
                                    .header("Authorization", bearer(secondToken)))
                            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
                });
                start.countDown();
                assertEquals("First Tenant Patient", firstResponse.get(20, TimeUnit.SECONDS)
                        .path("items").get(0).path("name").asText());
                assertEquals("Second Tenant Patient", secondResponse.get(20, TimeUnit.SECONDS)
                        .path("items").get(0).path("name").asText());
            }
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void inactiveOrRevokedMembershipCannotUsePreviouslyIssuedPatientSession() throws Exception {
        Hospital hospital = hospital("Membership Enforcement Hospital", 234_567_890_144L);
        String inactiveToken = token(hospital, MembershipRole.DOCTOR, "patient-inactive-member");
        AuthAccount inactiveAccount = accounts.findByUsername("patient-inactive-member").orElseThrow();
        HospitalMembership inactiveMembership = memberships.findByAccount_Id(inactiveAccount.getId()).orElseThrow();
        inactiveMembership.deactivate(Instant.now());
        memberships.saveAndFlush(inactiveMembership);

        mvc.perform(get("/api/v1/patients").header("Authorization", bearer(inactiveToken)))
                .andExpect(status().isUnauthorized());

        String revokedToken = token(hospital, MembershipRole.NURSE, "patient-revoked-member");
        AuthAccount revokedAccount = accounts.findByUsername("patient-revoked-member").orElseThrow();
        HospitalMembership revokedMembership = memberships.findByAccount_Id(revokedAccount.getId()).orElseThrow();
        revokedMembership.revoke(inactiveAccount.getId(), Instant.now());
        memberships.saveAndFlush(revokedMembership);

        mvc.perform(get("/api/v1/patients").header("Authorization", bearer(revokedToken)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void crossHospitalUuidLookupAndUpdateReturnNotFound() throws Exception {
        Hospital owner = hospital("Owner Hospital", 234_567_890_127L);
        Hospital other = hospital("Other Hospital", 234_567_890_128L);
        String ownerToken = token(owner, MembershipRole.ADMIN, "patient-owner");
        String otherToken = token(other, MembershipRole.ADMIN, "patient-other");
        UUID uuid = UUID.randomUUID();
        create(ownerToken, uuid, "Scoped Patient", null);

        mvc.perform(get("/api/v1/patients/{uuid}", uuid).header("Authorization", bearer(otherToken)))
                .andExpect(status().isNotFound());
        mvc.perform(put("/api/v1/patients/{uuid}", uuid).header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateJson(0, "Unauthorized Update")))
                .andExpect(status().isNotFound());
        mvc.perform(delete("/api/v1/patients/{uuid}", uuid).header("Authorization", bearer(otherToken)))
                .andExpect(status().isNotFound());
        Patient unchanged = patients.findByUuid(uuid).orElseThrow();
        assertEquals("Scoped Patient", unchanged.getName());
        assertEquals(null, unchanged.getArchivedAt());
    }

    @Test
    void missingMembershipAndCentralAdminCannotAccessPatientApi() throws Exception {
        mvc.perform(get("/api/v1/patients")).andExpect(status().isUnauthorized());

        Hospital hospital = hospital("Legacy Hospital", 234_567_890_129L);
        AuthAccount legacy = accounts.saveAndFlush(new AuthAccount("legacy-patient-user",
                passwordEncoder.encode("StrongPassword9!"), "Legacy User", "DOCTOR", hospital.getHospitalId()));
        String legacyToken = login(hospital.getHospitalId(), legacy.getUsername(), "StrongPassword9!");
        mvc.perform(get("/api/v1/patients").header("Authorization", bearer(legacyToken)))
                .andExpect(status().isForbidden());

        AuthAccount central = accounts.saveAndFlush(new AuthAccount("central-patient-admin",
                passwordEncoder.encode("StrongPassword9!"), "Central User", "SUPER_ADMIN", null));
        String centralToken = loginCentral(central.getUsername(), "StrongPassword9!");
        mvc.perform(get("/api/v1/patients").header("Authorization", bearer(centralToken)))
                .andExpect(status().isForbidden());
    }

    @Test
    void approvedRoleMatrixRestrictsCreationAndStatusChanges() throws Exception {
        Hospital hospital = hospital("Role Hospital", 234_567_890_130L);
        String doctorToken = token(hospital, MembershipRole.DOCTOR, "patient-doctor");
        String receptionistToken = token(hospital, MembershipRole.RECEPTIONIST, "patient-receptionist");
        UUID uuid = UUID.randomUUID();

        mvc.perform(post("/api/v1/patients").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(uuid, "Denied Create", null, null)))
                .andExpect(status().isForbidden());
        JsonNode created = mapper.readTree(create(receptionistToken, uuid, "Role Patient", null));
        mvc.perform(patch("/api/v1/patients/{uuid}/status", uuid).header("Authorization", bearer(receptionistToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"INACTIVE\",\"version\":" + created.path("version").longValue() + "}"))
                .andExpect(status().isForbidden());
        assertEquals(PatientStatus.ACTIVE, patients.findByUuid(uuid).orElseThrow().getStatus());
    }

    @Test
    void updateRequiresExpectedVersionAndStatusAndArchiveAreSoftOperations() throws Exception {
        Hospital hospital = hospital("Update Hospital", 234_567_890_131L);
        String adminToken = token(hospital, MembershipRole.ADMIN, "patient-update-admin");
        UUID uuid = UUID.randomUUID();
        JsonNode created = mapper.readTree(create(adminToken, uuid, "Original Name", null));
        long version = created.path("version").longValue();

        mvc.perform(put("/api/v1/patients/{uuid}", uuid).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content(updateJson(version, "Changed Name")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Changed Name"));
        mvc.perform(patch("/api/v1/patients/{uuid}/status", uuid).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"INACTIVE\",\"version\":" + version + "}"))
                .andExpect(status().isConflict());
        long updatedVersion = patients.findByUuid(uuid).orElseThrow().getVersion();
        mvc.perform(patch("/api/v1/patients/{uuid}/status", uuid).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"INACTIVE\",\"version\":" + updatedVersion + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("INACTIVE"));
        mvc.perform(delete("/api/v1/patients/{uuid}", uuid).header("Authorization", bearer(adminToken)))
                .andExpect(status().isNoContent());
        assertTrue(patients.findByUuid(uuid).orElseThrow().getArchivedAt() != null);
        mvc.perform(get("/api/v1/patients/{uuid}", uuid).header("Authorization", bearer(adminToken)))
                .andExpect(status().isNotFound());
    }

    @Test
    void malformedPatientRequestIsRejectedWithoutPersistence() throws Exception {
        Hospital hospital = hospital("Validation Hospital", 234_567_890_132L);
        String token = token(hospital, MembershipRole.RECEPTIONIST, "patient-validation");
        mvc.perform(post("/api/v1/patients").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"uuid\":\"" + UUID.randomUUID() + "\",\"name\":\"\",\"phone\":\"abc\",\"email\":\"bad\"}"))
                .andExpect(status().isBadRequest());
        assertEquals(0, patients.count());
    }

    private String create(String token, UUID uuid, String name, String phone) throws Exception {
        return mvc.perform(post("/api/v1/patients").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(uuid, name, null, phone)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
    }

    private static String createJson(UUID uuid, String name, String email, String phone) {
        String emailJson = email == null ? "null" : "\"" + email + "\"";
        String phoneJson = phone == null ? "null" : "\"" + phone + "\"";
        return "{\"uuid\":\"" + uuid + "\",\"name\":\"" + name + "\",\"email\":" + emailJson
                + ",\"phone\":" + phoneJson + "}";
    }

    private static String updateJson(long version, String name) {
        return "{\"version\":" + version + ",\"name\":\"" + name + "\"}";
    }

    private Hospital hospital(String name, long publicId) {
        Hospital hospital = new Hospital(UUID.randomUUID(), name, name.substring(0, Math.min(3, name.length())),
                "Clinic", null, null, null, null, Instant.now());
        hospital.approve(publicId);
        return hospitals.saveAndFlush(hospital);
    }

    private String token(Hospital hospital, MembershipRole role, String username) throws Exception {
        AuthAccount account = accounts.saveAndFlush(new AuthAccount(username,
                passwordEncoder.encode("StrongPassword9!"), "Patient Test User", role.name(), hospital.getHospitalId()));
        memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(), account, hospital, role, Instant.now()));
        return login(hospital.getHospitalId(), username, "StrongPassword9!");
    }

    private String login(Long hospitalId, String username, String password) throws Exception {
        String body = "{\"username\":\"" + username + "\",\"password\":\"" + password
                + "\",\"hospitalId\":\"" + hospitalId + "\"}";
        String json = mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(json).path("accessToken").asText();
    }

    private String loginCentral(String username, String password) throws Exception {
        String body = "{\"username\":\"" + username + "\",\"password\":\"" + password + "\"}";
        String json = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(json).path("accessToken").asText();
    }

    private static String bearer(String token) { return "Bearer " + token; }
}
