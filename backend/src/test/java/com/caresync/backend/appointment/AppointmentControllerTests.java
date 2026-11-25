package com.caresync.backend.appointment;

import com.caresync.backend.appointment.entity.Appointment;
import com.caresync.backend.appointment.entity.AppointmentEvent;
import com.caresync.backend.appointment.repository.AppointmentEventRepository;
import com.caresync.backend.appointment.repository.AppointmentRepository;
import com.caresync.backend.department.repository.DepartmentRepository;
import com.caresync.backend.doctor.entity.DoctorProfile;
import com.caresync.backend.doctor.entity.DoctorSchedule;
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
import com.caresync.backend.patient.entity.Patient;
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
import tools.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "caresync.security.jwt-secret=appointment-test-secret-only-for-tests-123456789")
@AutoConfigureMockMvc
class AppointmentControllerTests {
    @Autowired MockMvc mvc;
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
    @Autowired PatientRepository patients;
    @Autowired DepartmentRepository departments;
    @Autowired AppointmentRepository appointments;
    @Autowired AppointmentEventRepository appointmentEvents;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired SecurityAuditEventRepository securityAudits;

    @BeforeEach
    void clearOnlyTestSchemaRowsInForeignKeyOrder() {
        appointmentEvents.deleteAll();
        appointments.deleteAll();
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
    void createsScheduledAppointmentUsingConfiguredDoctorSlotAndStoresEvent() throws Exception {
        Fixture fixture = fixture("appointment-create");
        String token = login(fixture.hospital(), MembershipRole.RECEPTIONIST, "appointment-reception-create");
        String response = mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(fixture, "09:00")))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.status").value("SCHEDULED"))
                .andExpect(jsonPath("$.patientUuid").value(fixture.patient().getUuid().toString()))
                .andExpect(jsonPath("$.endsAt").value(org.hamcrest.Matchers.containsString("09:30")))
                .andReturn().getResponse().getContentAsString();
        String appointmentId = mapper.readTree(response).path("appointmentUuid").asText();

        mvc.perform(get("/api/v1/appointments/{id}/events", appointmentId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].eventType").value("CREATED"));
        mvc.perform(get("/api/v1/appointments").header("Authorization", bearer(token)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.items.length()").value(1));
    }

    @Test
    void rejectsOverlappingAndCrossHospitalPatientAppointments() throws Exception {
        Fixture fixture = fixture("appointment-conflict");
        String token = login(fixture.hospital(), MembershipRole.ADMIN, "appointment-admin-conflict");
        mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(fixture, "09:00")))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(fixture, "09:00")))
                .andExpect(status().isConflict());

        Hospital otherHospital = hospital("Appointment Other Hospital", 247_890_123_012L);
        String otherToken = login(otherHospital, MembershipRole.RECEPTIONIST, "appointment-reception-other");
        mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(otherToken))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(fixture, "10:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    void concurrentBookingRequestsCannotDoubleBookDoctorSlot() throws Exception {
        Fixture fixture = fixture("appointment-concurrent");
        String token = login(fixture.hospital(), MembershipRole.RECEPTIONIST, "appointment-reception-concurrent");
        String body = createJson(fixture, "09:00");
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            var booking = (java.util.concurrent.Callable<Integer>) () -> {
                ready.countDown();
                if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("Concurrent test start timed out");
                return mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(token))
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                        .andReturn().getResponse().getStatus();
            };
            Future<Integer> first = executor.submit(booking);
            Future<Integer> second = executor.submit(booking);
            org.junit.jupiter.api.Assertions.assertTrue(ready.await(10, TimeUnit.SECONDS));
            start.countDown();
            int firstStatus = first.get(30, TimeUnit.SECONDS);
            int secondStatus = second.get(30, TimeUnit.SECONDS);
            org.junit.jupiter.api.Assertions.assertTrue(
                    (firstStatus == 201 && secondStatus == 409) || (firstStatus == 409 && secondStatus == 201),
                    "Expected exactly one booking and one conflict, got " + firstStatus + " and " + secondStatus);
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    void enforcesStatusTransitionsAndPersistsAuditHistory() throws Exception {
        Fixture fixture = fixture("appointment-status");
        String receptionist = login(fixture.hospital(), MembershipRole.RECEPTIONIST, "appointment-reception-status");
        String doctorToken = loginExisting(fixture.hospital(), fixture.doctorUsername());
        String response = mvc.perform(post("/api/v1/appointments").header("Authorization", bearer(receptionist))
                        .contentType(MediaType.APPLICATION_JSON).content(createJson(fixture, "09:00")))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String id = mapper.readTree(response).path("appointmentUuid").asText();

        mvc.perform(patch("/api/v1/appointments/{id}/status", id).header("Authorization", bearer(receptionist))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"CONFIRMED\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("CONFIRMED"));
        mvc.perform(patch("/api/v1/appointments/{id}/status", id).header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"IN_PROGRESS\"}"))
                .andExpect(status().isConflict());
        mvc.perform(patch("/api/v1/appointments/{id}/status", id).header("Authorization", bearer(receptionist))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"CHECKED_IN\"}"))
                .andExpect(status().isOk());
        mvc.perform(patch("/api/v1/appointments/{id}/status", id).header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":\"IN_PROGRESS\"}"))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/appointments/{id}/cancel", id).header("Authorization", bearer(receptionist)))
                .andExpect(status().isConflict());
        mvc.perform(get("/api/v1/appointments/{id}/events", id).header("Authorization", bearer(receptionist)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(4));
    }

    private Fixture fixture(String key) {
        Hospital hospital = hospital("Appointment " + key, 247_890_123_010L + Math.abs(key.hashCode() % 1000));
        String doctorUsername = key + "-doctor";
        HospitalMembership doctorMembership = membership(hospital, MembershipRole.DOCTOR, doctorUsername);
        DoctorProfile doctor = doctors.saveAndFlush(new DoctorProfile(UUID.randomUUID(), hospital, doctorMembership,
                null, "General Medicine", "MBBS", null, Instant.now()));
        Patient patient = patients.saveAndFlush(new Patient(UUID.randomUUID(), hospital, "UHID-" + key, "Patient " + key,
                null, null, null, null, null, null, null, null, null, null, null, null, null,
                doctorMembership.getAccount().getId(), Instant.now()));
        LocalDate day = LocalDate.now(ZoneId.of("Asia/Kolkata")).plusDays(7);
        schedules.saveAndFlush(new DoctorSchedule(UUID.randomUUID(), hospital, doctor, day.getDayOfWeek().getValue(),
                LocalTime.of(9, 0), LocalTime.of(11, 0), 30, day, null, Instant.now()));
        return new Fixture(hospital, doctor, patient, day, doctorUsername);
    }

    private Hospital hospital(String name, long publicId) {
        Hospital hospital = new Hospital(UUID.randomUUID(), name, "AP" + (publicId % 1000), "Clinic",
                null, null, null, null, Instant.now());
        hospital.approve(publicId);
        hospital.configureTimeZone("Asia/Kolkata");
        return hospitals.saveAndFlush(hospital);
    }

    private HospitalMembership membership(Hospital hospital, MembershipRole role, String username) {
        AuthAccount account = accounts.saveAndFlush(new AuthAccount(username,
                passwordEncoder.encode("StrongPassword9!"), "Appointment Test User", role.name(), hospital.getHospitalId()));
        return memberships.saveAndFlush(new HospitalMembership(UUID.randomUUID(), account, hospital, role, Instant.now()));
    }

    private String login(Hospital hospital, MembershipRole role, String username) throws Exception {
        membership(hospital, role, username);
        return loginExisting(hospital, username);
    }

    private String loginExisting(Hospital hospital, String username) throws Exception {
        String response = mvc.perform(post("/api/auth/hospital-login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"" + username + "\",\"password\":\"StrongPassword9!\",\"hospitalId\":\""
                                + hospital.getHospitalId() + "\"}"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).path("accessToken").asText();
    }

    private static String createJson(Fixture fixture, String time) {
        OffsetDateTime start = fixture.day().atTime(LocalTime.parse(time)).atZone(ZoneId.of("Asia/Kolkata")).toOffsetDateTime();
        return "{\"patientUuid\":\"" + fixture.patient().getUuid() + "\",\"doctorUuid\":\"" + fixture.doctor().getId()
                + "\",\"startsAt\":\"" + start + "\",\"appointmentType\":\"CONSULTATION\",\"reason\":\"Review\"}";
    }

    private static String bearer(String token) { return "Bearer " + token; }
    private record Fixture(Hospital hospital, DoctorProfile doctor, Patient patient, LocalDate day,
                           String doctorUsername) {}
}
