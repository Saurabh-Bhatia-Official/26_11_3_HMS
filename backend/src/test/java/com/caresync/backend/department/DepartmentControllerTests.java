package com.caresync.backend.department;

import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.repository.HospitalRegistrationRepository;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.repository.HospitalMembershipRepository;
import com.caresync.backend.membership.repository.MembershipAuditEventRepository;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.security.SecurityAuditEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "caresync.security.jwt-secret=department-test-secret-keep-this-only-for-tests-123456")
@AutoConfigureMockMvc
class DepartmentControllerTests {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper mapper;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired AuthAccountRepository accounts;
    @Autowired HospitalRepository hospitals;
    @Autowired HospitalRegistrationRepository registrations;
    @Autowired HospitalMembershipRepository memberships;
    @Autowired MembershipAuditEventRepository membershipAudits;
    @Autowired DepartmentRepository departments;
    @Autowired DoctorProfileRepository doctorProfiles;
    @Autowired PatientRepository patients;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired SecurityAuditEventRepository securityAudits;

    @BeforeEach
    void clearOnlyTestSchemaRowsInForeignKeyOrder() {
        jdbc.update("delete from appointment_events");
        jdbc.update("delete from appointments");
        refreshTokens.deleteAll();
        membershipAudits.deleteAll();
        jdbc.update("delete from doctor_schedule_exceptions");
        jdbc.update("delete from doctor_schedules");
        doctorProfiles.deleteAll();
        memberships.deleteAll();
        patients.deleteAll();
        departments.deleteAll();
        registrations.deleteAll();
        securityAudits.deleteAll();
        hospitals.deleteAll();
        accounts.deleteAll();
    }

    @Test
    void hospitalAdminCanCreateListAndUpdateDepartment() throws Exception {
        Hospital hospital = hospital("Department One", 245_678_901_001L);
        String token = token(hospital, MembershipRole.HOSPITAL_SUPER_ADMIN, "department-admin-one");
        String response = mvc.perform(post("/api/v1/departments").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Cardiology\",\"code\":\"cardio\",\"description\":\"Heart care\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value("CARDIO"))
                .andExpect(jsonPath("$.hospitalUuid").value(hospital.getId().toString()))
                .andReturn().getResponse().getContentAsString();
        JsonNode created = mapper.readTree(response);

        mvc.perform(get("/api/v1/departments").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1));
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put(
                        "/api/v1/departments/{id}", created.path("id").asText())
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Heart Institute\",\"code\":\"CARDIO\",\"description\":null}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Heart Institute"));
    }

    @Test
    void duplicateActiveCodeAndInvalidRequestsAreRejected() throws Exception {
        Hospital hospital = hospital("Department Two", 245_678_901_002L);
        String token = token(hospital, MembershipRole.ADMIN, "department-admin-two");
        String request = "{\"name\":\"Cardiology\",\"code\":\"CARDIO\"}";
        mvc.perform(post("/api/v1/departments").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(request))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/departments").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Heart\",\"code\":\"cardio\"}"))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/v1/departments").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"code\":\"?\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void hospitalCannotReadAnotherHospitalsDepartmentAndReceptionCannotManage() throws Exception {
        Hospital owner = hospital("Department Owner", 245_678_901_003L);
        Hospital other = hospital("Department Other", 245_678_901_004L);
        String ownerToken = token(owner, MembershipRole.ADMIN, "department-owner");
        String otherToken = token(other, MembershipRole.RECEPTIONIST, "department-other");
        String response = mvc.perform(post("/api/v1/departments").header("Authorization", bearer(ownerToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Radiology\",\"code\":\"RAD\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String departmentId = mapper.readTree(response).path("id").asText();

        mvc.perform(get("/api/v1/departments/{id}", departmentId).header("Authorization", bearer(otherToken)))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/departments").header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Unauthorized\",\"code\":\"UNAUTH\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void hospitalAdministratorMustSetAnExplicitValidTimeZone() throws Exception {
        Hospital hospital = hospital("Timezone Hospital", 245_678_901_005L);
        String token = token(hospital, MembershipRole.ADMIN, "timezone-admin");

        mvc.perform(patch("/api/v1/hospitals/me/time-zone").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"timeZone\":\"Asia/Kolkata\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.timeZone").value("Asia/Kolkata"));
        mvc.perform(patch("/api/v1/hospitals/me/time-zone").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"timeZone\":\"Mars/Olympus\"}"))
                .andExpect(status().isBadRequest());
        assertEquals("Asia/Kolkata", hospitals.findById(hospital.getId()).orElseThrow().getTimeZone());
    }

    private Hospital hospital(String name, long publicId) {
        Hospital hospital = new Hospital(UUID.randomUUID(), name, name.substring(0, 3), "Clinic",
                null, null, null, null, Instant.now());
        hospital.approve(publicId);
        return hospitals.saveAndFlush(hospital);
    }

    private String token(Hospital hospital, MembershipRole role, String username) throws Exception {
        AuthAccount account = accounts.saveAndFlush(new AuthAccount(username, passwordEncoder.encode("StrongPassword9!"),
                "Department Test User", role.name(), hospital.getHospitalId()));
        memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(), account, hospital, role, Instant.now()));
        String request = "{\"username\":\"" + username + "\",\"password\":\"StrongPassword9!\",\"hospitalId\":\""
                + hospital.getHospitalId() + "\"}";
        String response = mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).path("accessToken").asText();
    }

    private static String bearer(String token) { return "Bearer " + token; }
}
