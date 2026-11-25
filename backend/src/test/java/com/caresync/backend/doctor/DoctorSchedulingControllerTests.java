package com.caresync.backend.doctor;

import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.doctor.entity.DoctorSchedule;
import com.caresync.backend.doctor.entity.DoctorScheduleException;
import com.caresync.backend.doctor.entity.ScheduleExceptionType;
import com.caresync.backend.doctor.repository.DoctorProfileRepository;
import com.caresync.backend.doctor.repository.DoctorScheduleExceptionRepository;
import com.caresync.backend.doctor.repository.DoctorScheduleRepository;
import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.repository.HospitalRegistrationRepository;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.membership.entity.HospitalMembership;
import com.caresync.backend.membership.entity.MembershipRole;
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
import tools.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "caresync.security.jwt-secret=schedule-test-secret-keep-this-only-for-tests-123456")
@AutoConfigureMockMvc
class DoctorSchedulingControllerTests {
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
    @Autowired DoctorScheduleRepository schedules;
    @Autowired DoctorScheduleExceptionRepository exceptions;
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
        exceptions.deleteAll();
        schedules.deleteAll();
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
    void availabilityUsesRecurringScheduleAndHospitalTimeZone() throws Exception {
        Hospital hospital = hospital("Schedule Availability Hospital", 247_890_123_001L);
        DoctorProfile doctor = doctor(hospital, "schedule-doctor-one");
        String adminToken = accountWithToken(hospital, MembershipRole.ADMIN, "schedule-admin-one");
        LocalDate date = futureDate();
        mvc.perform(post("/api/v1/doctors/{id}/schedules", doctor.getId()).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content(scheduleJson(date, "09:00", "10:00", 20)))
                .andExpect(status().isCreated());

        mvc.perform(get("/api/v1/doctors/{id}/availability", doctor.getId())
                        .param("date", date.toString()).header("Authorization", bearer(adminToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[0].startsAt").value(org.hamcrest.Matchers.containsString("+05:30")));
    }

    @Test
    void overlappingScheduleIntervalsAreRejected() throws Exception {
        Hospital hospital = hospital("Schedule Conflict Hospital", 247_890_123_002L);
        DoctorProfile doctor = doctor(hospital, "schedule-doctor-two");
        String adminToken = accountWithToken(hospital, MembershipRole.HOSPITAL_SUPER_ADMIN, "schedule-admin-two");
        LocalDate date = futureDate();
        mvc.perform(post("/api/v1/doctors/{id}/schedules", doctor.getId()).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content(scheduleJson(date, "09:00", "10:00", 15)))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/doctors/{id}/schedules", doctor.getId()).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content(scheduleJson(date, "09:30", "11:00", 15)))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/v1/doctors/{id}/schedules", doctor.getId()).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content(scheduleJson(date, "10:00", "11:00", 15)))
                .andExpect(status().isCreated());
    }

    @Test
    void blockedIntervalsAndFullDayLeaveRemoveAvailability() throws Exception {
        Hospital hospital = hospital("Schedule Exception Hospital", 247_890_123_003L);
        DoctorProfile doctor = doctor(hospital, "schedule-doctor-three");
        String adminToken = accountWithToken(hospital, MembershipRole.ADMIN, "schedule-admin-three");
        LocalDate date = futureDate();
        mvc.perform(post("/api/v1/doctors/{id}/schedules", doctor.getId()).header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON).content(scheduleJson(date, "09:00", "10:00", 20)))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/doctors/{id}/schedule-exceptions", doctor.getId())
                        .header("Authorization", bearer(adminToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(exceptionJson(date, "BLOCKED", "09:20", "09:40")))
                .andExpect(status().isCreated());
        mvc.perform(get("/api/v1/doctors/{id}/availability", doctor.getId())
                        .param("date", date.toString()).header("Authorization", bearer(adminToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2));
        mvc.perform(post("/api/v1/doctors/{id}/schedule-exceptions", doctor.getId())
                        .header("Authorization", bearer(adminToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(exceptionJson(date, "LEAVE", null, null)))
                .andExpect(status().isCreated());
        mvc.perform(get("/api/v1/doctors/{id}/availability", doctor.getId())
                        .param("date", date.toString()).header("Authorization", bearer(adminToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void receptionistCanViewAvailabilityButCannotManageSchedules() throws Exception {
        Hospital hospital = hospital("Schedule Permissions Hospital", 247_890_123_004L);
        DoctorProfile doctor = doctor(hospital, "schedule-doctor-four");
        String receptionist = accountWithToken(hospital, MembershipRole.RECEPTIONIST, "schedule-reception-four");
        LocalDate date = futureDate();
        mvc.perform(get("/api/v1/doctors/{id}/availability", doctor.getId())
                        .param("date", date.toString()).header("Authorization", bearer(receptionist)))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/doctors/{id}/schedules", doctor.getId())
                        .header("Authorization", bearer(receptionist)).contentType(MediaType.APPLICATION_JSON)
                        .content(scheduleJson(date, "09:00", "10:00", 15)))
                .andExpect(status().isForbidden());
    }

    private Hospital hospital(String name, long publicId) {
        Hospital hospital = new Hospital(UUID.randomUUID(), name, name.substring(0, 3), "Clinic",
                null, null, null, null, Instant.now());
        hospital.approve(publicId);
        hospital.configureTimeZone("Asia/Kolkata");
        return hospitals.saveAndFlush(hospital);
    }

    private DoctorProfile doctor(Hospital hospital, String username) {
        HospitalMembership membership = membership(hospital, MembershipRole.DOCTOR, username);
        return doctors.saveAndFlush(new DoctorProfile(UUID.randomUUID(), hospital, membership, null,
                "General Medicine", "MBBS", null, Instant.now()));
    }

    private String accountWithToken(Hospital hospital, MembershipRole role, String username) throws Exception {
        membership(hospital, role, username);
        String request = "{\"username\":\"" + username + "\",\"password\":\"StrongPassword9!\",\"hospitalId\":\""
                + hospital.getHospitalId() + "\"}";
        String response = mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).path("accessToken").asText();
    }

    private HospitalMembership membership(Hospital hospital, MembershipRole role, String username) {
        AuthAccount account = accounts.saveAndFlush(new AuthAccount(username, passwordEncoder.encode("StrongPassword9!"),
                "Schedule Test User", role.name(), hospital.getHospitalId()));
        return memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(), account, hospital, role, Instant.now()));
    }

    private static LocalDate futureDate() {
        LocalDate date = LocalDate.now(ZoneId.of("Asia/Kolkata")).plusDays(7);
        while (date.getDayOfWeek().getValue() < 1 || date.getDayOfWeek().getValue() > 7) date = date.plusDays(1);
        return date;
    }

    private static String scheduleJson(LocalDate effectiveFrom, String start, String end, int slotMinutes) {
        int day = effectiveFrom.getDayOfWeek().getValue();
        return "{\"dayOfWeek\":" + day + ",\"startTime\":\"" + start + "\",\"endTime\":\"" + end
                + "\",\"slotMinutes\":" + slotMinutes + ",\"effectiveFrom\":\"" + effectiveFrom
                + "\",\"effectiveUntil\":null,\"active\":true}";
    }

    private static String exceptionJson(LocalDate date, String type, String start, String end) {
        String startJson = start == null ? "null" : "\"" + start + "\"";
        String endJson = end == null ? "null" : "\"" + end + "\"";
        return "{\"date\":\"" + date + "\",\"type\":\"" + type + "\",\"startTime\":"
                + startJson + ",\"endTime\":" + endJson + ",\"reason\":\"test\",\"active\":true}";
    }

    private static String bearer(String token) { return "Bearer " + token; }
}
