package com.caresync.backend.membership;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalRegistration;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.hospital.repository.HospitalRegistrationRepository;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipAuditEvent;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.repository.HospitalMembershipRepository;
import com.caresync.backend.membership.repository.MembershipAuditEventRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.security.SecurityAuditEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=membership-test-secret-keep-this-only-for-tests-123456789",
        "spring.datasource.url=jdbc:h2:mem:caresync-membership-controller-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
@AutoConfigureMockMvc
class MembershipControllerTests {
    private static final String PASSWORD = "ExistingAccountPassword9!";
    private static final long HOSPITAL_ID = 712_345_678_901L;

    @Autowired MockMvc mvc;
    @Autowired HospitalRepository hospitals;
    @Autowired HospitalRegistrationRepository registrations;
    @Autowired AuthAccountRepository accounts;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired SecurityAuditEventRepository securityAuditEvents;
    @Autowired HospitalMembershipRepository memberships;
    @Autowired MembershipAuditEventRepository membershipAuditEvents;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired JdbcTemplate jdbc;
    @Autowired tools.jackson.databind.ObjectMapper objectMapper;

    private Hospital hospital;
    private AuthAccount hospitalAdmin;
    private String hospitalAdminToken;

    @BeforeEach
    void prepareIsolatedDatabase() throws Exception {
        membershipAuditEvents.deleteAll();
        memberships.deleteAll();
        refreshTokens.deleteAll();
        registrations.deleteAll();
        hospitals.deleteAll();
        securityAuditEvents.deleteAll();
        accounts.deleteAll();

        hospital = createHospital("Membership API Hospital", HOSPITAL_ID);
        hospitalAdmin = createAccount("membership-hsa", "HOSPITAL_SUPER_ADMIN", HOSPITAL_ID);
        memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(), hospitalAdmin, hospital,
                MembershipRole.HOSPITAL_SUPER_ADMIN, Instant.now()));
        hospitalAdminToken = login(hospitalAdmin.getUsername(), HOSPITAL_ID).accessToken();
    }

    @Test
    void grantsListsAndChangesOnlyTheAuthenticatedHospitalsMemberships() throws Exception {
        AuthAccount employee = createAccount("membership-target", "STAFF", HOSPITAL_ID);

        String response = mvc.perform(post("/api/v1/memberships")
                        .header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accountId\":" + employee.getId() + ",\"role\":\"DOCTOR\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accountId").value(employee.getId()))
                .andExpect(jsonPath("$.role").value("DOCTOR"))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andReturn().getResponse().getContentAsString();
        UUID membershipId = UUID.fromString(objectMapper.readTree(response).get("membershipId").asText());

        mvc.perform(get("/api/v1/memberships").header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.membershipId == '" + membershipId + "')]").isArray());

        mvc.perform(patch("/api/v1/memberships/{membershipId}/role", membershipId)
                        .header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"NURSE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("NURSE"));

        assertEquals("NURSE", accounts.findById(employee.getId()).orElseThrow().getRole());
        List<MembershipAuditEvent> events = membershipAuditEvents.findAll();
        assertTrue(events.stream().anyMatch(event -> event.getEventType().equals("GRANTED")
                && event.getActorAccountId().equals(hospitalAdmin.getId())));
        assertTrue(events.stream().anyMatch(event -> event.getEventType().equals("ROLE_CHANGED")
                && event.getActorAccountId().equals(hospitalAdmin.getId())));
    }

    @Test
    void deniesAnonymousNonAdminPlatformAndCrossHospitalAccess() throws Exception {
        mvc.perform(get("/api/v1/memberships")).andExpect(status().isUnauthorized());

        AuthAccount hospitalAdminRole = createAccount("membership-admin-role", "ADMIN", HOSPITAL_ID);
        memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(), hospitalAdminRole, hospital,
                MembershipRole.ADMIN, Instant.now()));
        String adminToken = login(hospitalAdminRole.getUsername(), HOSPITAL_ID).accessToken();
        mvc.perform(get("/api/v1/memberships").header("Authorization", bearer(adminToken)))
                .andExpect(status().isForbidden());

        AuthAccount platformAdmin = createAccount("membership-platform-admin", "SUPER_ADMIN", null);
        String platformToken = login(platformAdmin.getUsername(), null).accessToken();
        mvc.perform(get("/api/v1/memberships").header("Authorization", bearer(platformToken)))
                .andExpect(status().isForbidden());

        Hospital otherHospital = createHospital("Other Membership Hospital", HOSPITAL_ID + 1);
        AuthAccount otherEmployee = createAccount("other-hospital-member", "DOCTOR", HOSPITAL_ID + 1);
        HospitalMembership otherMembership = memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(),
                otherEmployee, otherHospital, MembershipRole.DOCTOR, Instant.now()));
        mvc.perform(get("/api/v1/memberships/{membershipId}", otherMembership.getId())
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isNotFound());

        mvc.perform(get("/api/v1/memberships").header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.accountId == " + otherEmployee.getId() + ")]").isEmpty());
    }

    @Test
    void rejectsPlatformAndHospitalSuperAdminRoleGrantsAndForeignAccounts() throws Exception {
        AuthAccount employee = createAccount("membership-role-target", "STAFF", HOSPITAL_ID);
        AuthAccount otherHospitalAccount = createAccount("membership-foreign-target", "DOCTOR", HOSPITAL_ID + 10);
        AuthAccount unlinkedHospitalSuperAdmin = createAccount("membership-unlinked-hsa", "HOSPITAL_SUPER_ADMIN", HOSPITAL_ID);

        grant(employee, "DOCTOR").andExpect(status().isCreated());

        mvc.perform(post("/api/v1/memberships").header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accountId\":" + otherHospitalAccount.getId() + ",\"role\":\"NURSE\"}"))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/v1/memberships").header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accountId\":" + unlinkedHospitalSuperAdmin.getId() + ",\"role\":\"STAFF\"}"))
                .andExpect(status().isConflict());

        var member = memberships.findByAccount_Id(employee.getId()).orElseThrow();
        mvc.perform(patch("/api/v1/memberships/{membershipId}/role", member.getId())
                        .header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"ADMIN\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/memberships/{membershipId}/role", member.getId())
                        .header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"HOSPITAL_SUPER_ADMIN\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/memberships/{membershipId}/role", member.getId())
                        .header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"role\":\"SUPER_ADMIN\"}"))
                .andExpect(status().isBadRequest());

        UUID ownMembershipId = memberships.findByAccount_Id(hospitalAdmin.getId()).orElseThrow().getId();
        mvc.perform(patch("/api/v1/memberships/{membershipId}/deactivate", ownMembershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isForbidden());
        mvc.perform(patch("/api/v1/memberships/{membershipId}/revoke", ownMembershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isForbidden());
    }

    @Test
    void activationDeactivationAndRevocationPreserveAuditAndInvalidateOldSessions() throws Exception {
        AuthAccount employee = createAccount("membership-lifecycle", "STAFF", HOSPITAL_ID);
        String createResponse = grant(employee, "DOCTOR").andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        UUID membershipId = UUID.fromString(objectMapper.readTree(createResponse).get("membershipId").asText());

        TokenPair firstSession = login(employee.getUsername(), HOSPITAL_ID);
        mvc.perform(patch("/api/v1/memberships/{membershipId}/deactivate", membershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("INACTIVE"));
        expectSessionRejected(firstSession);

        mvc.perform(patch("/api/v1/memberships/{membershipId}/activate", membershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("ACTIVE"));
        TokenPair secondSession = login(employee.getUsername(), HOSPITAL_ID);
        mvc.perform(patch("/api/v1/memberships/{membershipId}/revoke", membershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("REVOKED"));
        expectSessionRejected(secondSession);

        mvc.perform(patch("/api/v1/memberships/{membershipId}/deactivate", membershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isConflict());

        mvc.perform(patch("/api/v1/memberships/{membershipId}/activate", membershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.revokedAt").doesNotExist());

        List<String> lifecycleEvents = jdbc.query(
                "SELECT event_type FROM membership_audit_events WHERE membership_id = ? ORDER BY id",
                (result, row) -> result.getString(1), membershipId);
        assertEquals(List.of("GRANTED", "INACTIVE", "ACTIVE", "REVOKED", "ACTIVE"), lifecycleEvents);
        List<Long> actors = jdbc.query(
                "SELECT actor_account_id FROM membership_audit_events WHERE membership_id = ? ORDER BY id",
                (result, row) -> result.getLong(1), membershipId);
        assertTrue(actors.stream().allMatch(id -> id.equals(hospitalAdmin.getId())));
    }

    @Test
    void validatesGrantFieldsAndReturnsScopedMembershipDetails() throws Exception {
        mvc.perform(post("/api/v1/memberships").header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"accountId\":0,\"role\":\"DOCTOR\"}"))
                .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/memberships").header("Authorization", bearer(hospitalAdminToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"accountId\":null,\"role\":null}"))
                .andExpect(status().isBadRequest());

        AuthAccount employee = createAccount("membership-detail", "STAFF", HOSPITAL_ID);
        String response = grant(employee, "RECEPTIONIST").andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        UUID membershipId = UUID.fromString(objectMapper.readTree(response).get("membershipId").asText());
        mvc.perform(get("/api/v1/memberships/{membershipId}", membershipId)
                        .header("Authorization", bearer(hospitalAdminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accountId").value(employee.getId()))
                .andExpect(jsonPath("$.role").value("RECEPTIONIST"));
    }

    private org.springframework.test.web.servlet.ResultActions grant(AuthAccount account, String role) throws Exception {
        return mvc.perform(post("/api/v1/memberships").header("Authorization", bearer(hospitalAdminToken))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"accountId\":" + account.getId() + ",\"role\":\"" + role + "\"}"));
    }

    private Hospital createHospital(String name, long publicId) {
        Hospital created = new Hospital(UUID.randomUUID(), name, name.replace(" ", "").toUpperCase(),
                "Clinic", null, null, null, null, Instant.now());
        created.approve(publicId);
        return hospitals.saveAndFlush(created);
    }

    private AuthAccount createAccount(String username, String role, Long hospitalId) {
        return accounts.saveAndFlush(new AuthAccount(username, passwordEncoder.encode(PASSWORD),
                "Test " + username, role, hospitalId));
    }

    private TokenPair login(String username, Long hospitalId) throws Exception {
        String endpoint = hospitalId == null ? "/api/auth/login" : "/api/auth/hospital-login";
        String body = "{\"username\":\"" + username + "\",\"password\":\"" + PASSWORD + "\""
                + (hospitalId == null ? "" : ",\"hospitalId\":\"" + hospitalId + "\"") + "}";
        String response = mvc.perform(post(endpoint).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        var json = objectMapper.readTree(response);
        return new TokenPair(json.get("accessToken").asText(), json.get("refreshToken").asText());
    }

    private void expectSessionRejected(TokenPair tokens) throws Exception {
        mvc.perform(get("/api/v1/memberships").header("Authorization", bearer(tokens.accessToken())))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + tokens.refreshToken() + "\"}"))
                .andExpect(status().isUnauthorized());
    }

    private static String bearer(String token) { return "Bearer " + token; }

    private record TokenPair(String accessToken, String refreshToken) {}
}
