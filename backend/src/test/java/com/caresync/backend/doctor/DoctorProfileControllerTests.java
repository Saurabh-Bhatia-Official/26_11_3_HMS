package com.caresync.backend.doctor;

import com.caresync.backend.department.entity.Department;
import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.repository.HospitalRegistrationRepository;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipRole;
import com.caresync.backend.membership.entity.MembershipStatus;
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

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "caresync.security.jwt-secret=doctor-test-secret-keep-this-only-for-tests-123456")
@AutoConfigureMockMvc
class DoctorProfileControllerTests {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper mapper;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired AuthAccountRepository accounts;
    @Autowired HospitalRepository hospitals;
    @Autowired HospitalRegistrationRepository registrations;
    @Autowired HospitalMembershipRepository memberships;
    @Autowired MembershipAuditEventRepository membershipAudits;
    @Autowired DoctorProfileRepository doctors;
    @Autowired DepartmentRepository departments;
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
        doctors.deleteAll();
        memberships.deleteAll();
        patients.deleteAll();
        departments.deleteAll();
        registrations.deleteAll();
        securityAudits.deleteAll();
        hospitals.deleteAll();
        accounts.deleteAll();
    }

    @Test
    void hospitalAdminCanProvisionAndListDoctorProfileFromActiveDoctorMembership() throws Exception {
        Hospital hospital = hospital("Doctor Profile Hospital", 246_789_012_001L);
        String adminToken = accountWithToken(hospital, MembershipRole.ADMIN, "doctor-profile-admin");
        HospitalMembership doctorMembership = membership(hospital, MembershipRole.DOCTOR, "doctor-member-one");

        String response = mvc.perform(post("/api/v1/doctors").header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(doctorMembership.getId(), null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.displayName").value("Doctor Profile User"))
                .andExpect(jsonPath("$.registrationReferenceVerified").value(false))
                .andExpect(jsonPath("$.active").value(true))
                .andReturn().getResponse().getContentAsString();
        String profileId = mapper.readTree(response).path("id").asText();

        mvc.perform(get("/api/v1/doctors").header("Authorization", bearer(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items.length()").value(1));
        mvc.perform(get("/api/v1/doctors/{id}", profileId).header("Authorization", bearer(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.membershipId").value(doctorMembership.getId().toString()));
        mvc.perform(patch("/api/v1/doctors/{id}/status", profileId).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(false));
    }

    @Test
    void cannotAssignWrongRoleOrAnotherHospitalsDoctorMembership() throws Exception {
        Hospital first = hospital("Doctor Tenant One", 246_789_012_002L);
        Hospital second = hospital("Doctor Tenant Two", 246_789_012_003L);
        String firstAdmin = accountWithToken(first, MembershipRole.HOSPITAL_SUPER_ADMIN, "doctor-tenant-admin-one");
        HospitalMembership secondDoctor = membership(second, MembershipRole.DOCTOR, "doctor-tenant-member-two");
        HospitalMembership firstReception = membership(first, MembershipRole.RECEPTIONIST, "doctor-tenant-reception");

        mvc.perform(post("/api/v1/doctors").header("Authorization", bearer(firstAdmin))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(secondDoctor.getId(), null)))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/v1/doctors").header("Authorization", bearer(firstAdmin))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(firstReception.getId(), null)))
                .andExpect(status().isConflict());
    }

    @Test
    void receptionistCannotManageProfilesAndDoctorCanReadOnlyOwnProfile() throws Exception {
        Hospital hospital = hospital("Doctor Self Profile Hospital", 246_789_012_004L);
        String adminToken = accountWithToken(hospital, MembershipRole.ADMIN, "doctor-self-admin");
        HospitalMembership doctorMembership = membership(hospital, MembershipRole.DOCTOR, "doctor-self-member");
        HospitalMembership anotherDoctorMembership = membership(hospital, MembershipRole.DOCTOR, "doctor-self-member-two");
        HospitalMembership receptionistMembership = membership(hospital, MembershipRole.RECEPTIONIST, "doctor-self-reception");
        DoctorProfile own = profile(hospital, doctorMembership);
        DoctorProfile other = profile(hospital, anotherDoctorMembership);
        String doctorToken = login(hospital, "doctor-self-member");
        String receptionistToken = login(hospital, "doctor-self-reception");

        mvc.perform(get("/api/v1/doctors/{id}", own.getId()).header("Authorization", bearer(doctorToken)))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/doctors/{id}", other.getId()).header("Authorization", bearer(doctorToken)))
                .andExpect(status().isNotFound());
        mvc.perform(patch("/api/v1/doctors/{id}/status", own.getId())
                        .header("Authorization", bearer(receptionistToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void departmentAssignmentMustBeActiveAndHospitalScoped() throws Exception {
        Hospital first = hospital("Doctor Department One", 246_789_012_005L);
        Hospital second = hospital("Doctor Department Two", 246_789_012_006L);
        String adminToken = accountWithToken(first, MembershipRole.ADMIN, "doctor-department-admin");
        HospitalMembership doctorMembership = membership(first, MembershipRole.DOCTOR, "doctor-department-member");
        Department otherDepartment = new Department(UUID.randomUUID(), second, "CARDIO", "Cardiology", null, Instant.now());
        departments.saveAndFlush(otherDepartment);

        mvc.perform(post("/api/v1/doctors").header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createJson(doctorMembership.getId(), otherDepartment.getId())))
                .andExpect(status().isConflict());
    }

    private Hospital hospital(String name, long publicId) {
        Hospital hospital = new Hospital(UUID.randomUUID(), name, name.substring(0, 3), "Clinic",
                null, null, null, null, Instant.now());
        hospital.approve(publicId);
        return hospitals.saveAndFlush(hospital);
    }

    private String accountWithToken(Hospital hospital, MembershipRole role, String username) throws Exception {
        membership(hospital, role, username);
        return login(hospital, username);
    }

    private HospitalMembership membership(Hospital hospital, MembershipRole role, String username) {
        AuthAccount account = accounts.saveAndFlush(new AuthAccount(username, passwordEncoder.encode("StrongPassword9!"),
                "Doctor Profile User", role.name(), hospital.getHospitalId()));
        return memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(), account, hospital, role, Instant.now()));
    }

    private DoctorProfile profile(Hospital hospital, HospitalMembership membership) {
        return doctors.saveAndFlush(new DoctorProfile(UUID.randomUUID(), hospital, membership, null,
                "Internal Medicine", "MBBS", null, Instant.now()));
    }

    private String login(Hospital hospital, String username) throws Exception {
        String request = "{\"username\":\"" + username + "\",\"password\":\"StrongPassword9!\",\"hospitalId\":\""
                + hospital.getHospitalId() + "\"}";
        String response = mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).path("accessToken").asText();
    }

    private static String createJson(UUID membershipId, UUID departmentId) {
        return "{\"membershipId\":\"" + membershipId + "\",\"departmentId\":"
                + (departmentId == null ? "null" : "\"" + departmentId + "\"")
                + ",\"specialization\":\"Cardiology\",\"qualification\":\"MBBS, MD\","
                + "\"registrationReference\":\"REG-UNVERIFIED-1\"}";
    }

    private static String bearer(String token) { return "Bearer " + token; }
}
