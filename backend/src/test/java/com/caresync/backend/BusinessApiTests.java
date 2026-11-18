package com.caresync.backend;

import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.security.SecurityAuditEventRepository;
import com.caresync.backend.patient.entity.PatientRecord;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.pharmacy.entity.MedicineBatch;
import com.caresync.backend.pharmacy.repository.MedicineBatchRepository;
import com.caresync.backend.pharmacy.repository.MedicineRepository;
import com.caresync.backend.staff.entity.StaffMember;
import com.caresync.backend.staff.repository.StaffRepository;
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
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-business-test-secret-change-before-deployment",
        "spring.datasource.url=jdbc:h2:mem:caresync-business-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"
})
@AutoConfigureMockMvc
class BusinessApiTests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AuthAccountRepository accounts;
    @Autowired RefreshTokenRepository refreshTokens;
    @Autowired SecurityAuditEventRepository auditEvents;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired PatientRepository patients;
    @Autowired StaffRepository staff;
    @Autowired MedicineBatchRepository batches;
    @Autowired MedicineRepository medicines;

    private PatientRecord patient;
    private PatientRecord otherHospitalPatient;
    private StaffMember doctor;
    private StaffMember otherHospitalDoctor;

    @BeforeEach
    void resetAccounts() {
        refreshTokens.deleteAll();
        auditEvents.deleteAll();
        accounts.deleteAll();
        accounts.save(new AuthAccount("accounts1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Billing Officer", "ACCOUNTS", 42L));
        accounts.save(new AuthAccount("accounts2", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Other Billing Officer", "ACCOUNTS", 43L));
        accounts.save(new AuthAccount("pharmacy1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Pharmacist", "PHARMACIST", 42L));
        accounts.save(new AuthAccount("doctor1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Doctor", "DOCTOR", 42L));
        accounts.save(new AuthAccount("doctor2", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Other Doctor", "DOCTOR", 43L));
        accounts.save(new AuthAccount("lab1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Lab Technician", "LAB_TECHNICIAN", 42L));
        String patientUuid = UUID.randomUUID().toString();
        patient = patients.save(new PatientRecord(42L, patientUuid, "UHID-" + patientUuid.substring(0, 8),
                "Test Patient"));
        String otherPatientUuid = UUID.randomUUID().toString();
        otherHospitalPatient = patients.save(new PatientRecord(43L, otherPatientUuid,
                "UHID-" + otherPatientUuid.substring(0, 8), "Other Hospital Patient"));
        doctor = saveDoctor(42L, "Test Doctor", "5550001");
        otherHospitalDoctor = saveDoctor(43L, "Other Hospital Doctor", "5550002");
    }

    @Test
    void invoiceTotalsAndPaymentsAreCalculatedAndHospitalScoped() throws Exception {
        String billingToken = login("accounts1");
        String invoiceJson = """
                {
                  "patientId": %d,
                  "patientName": "Test Patient",
                  "uhid": "%s",
                  "invoiceType": "opd",
                  "discountPaise": 100,
                  "items": [
                    {"itemType":"service","description":"Consultation","qty":2,"unitPricePaise":1000,"discountPaise":0,"taxRatePct":10}
                  ]
                }
                """.formatted(patient.getId(), patient.getUhid());
        MvcResult created = mvc.perform(post("/api/billing/invoices")
                        .header("Authorization", bearer(billingToken))
                        .contentType(MediaType.APPLICATION_JSON).content(invoiceJson))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.subtotalPaise").value(2000))
                .andExpect(jsonPath("$.taxPaise").value(200))
                .andExpect(jsonPath("$.totalPaise").value(2100))
                .andExpect(jsonPath("$.duePaise").value(2100))
                .andReturn();
        long invoiceId = mapper.readTree(created.getResponse().getContentAsString()).path("id").asLong();

        mvc.perform(post("/api/billing/invoices/{id}/payments", invoiceId)
                        .header("Authorization", bearer(billingToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("paymentMode", "cash", "amountPaise", 2000))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("partial"))
                .andExpect(jsonPath("$.duePaise").value(100));

        mvc.perform(post("/api/billing/invoices/{id}/payments", invoiceId)
                        .header("Authorization", bearer(billingToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("paymentMode", "cash", "amountPaise", 101))))
                .andExpect(status().isBadRequest());

        String otherHospitalToken = login("accounts2");
        mvc.perform(get("/api/billing/invoices/{id}", invoiceId)
                        .header("Authorization", bearer(otherHospitalToken)))
                .andExpect(status().isNotFound());

        mvc.perform(get("/api/staff").header("Authorization", bearer(billingToken)))
                .andExpect(status().isForbidden());
    }

    @Test
    void patientIdentityIsHospitalScopedAndCreateIsSafeToReplay() throws Exception {
        String uuid = UUID.randomUUID().toString();
        String request = mapper.writeValueAsString(Map.of(
                "uuid", uuid,
                "uhid", "UHID-SYNC-" + uuid.substring(0, 8),
                "name", "Sync Patient"));
        String doctorToken = login("doctor1");

        MvcResult created = mvc.perform(post("/api/patients")
                        .header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(request))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.uuid").value(uuid))
                .andReturn();
        long id = mapper.readTree(created.getResponse().getContentAsString()).path("id").asLong();

        mvc.perform(post("/api/patients")
                        .header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(request))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(id));

        mvc.perform(get("/api/patients/by-uuid/{uuid}", uuid)
                        .header("Authorization", bearer(login("accounts2"))))
                .andExpect(status().isNotFound());
    }

    @Test
    void invoiceDiscountUsesPostItemDiscountTotalAndCannotMakeInvoiceNegative() throws Exception {
        String token = login("accounts1");
        Map<String, Object> common = Map.of(
                "patientId", patient.getId(),
                "patientName", patient.getName(),
                "invoiceType", "opd",
                "discountPaise", 0,
                "items", java.util.List.of(Map.of("itemType", "service", "description", "Consultation",
                        "qty", 1, "unitPricePaise", 1000, "discountPaise", 600, "taxRatePct", 0)));

        Map<String, Object> nullItem = new java.util.HashMap<>(common);
        nullItem.put("items", java.util.Collections.singletonList(null));
        mvc.perform(post("/api/billing/invoices").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(nullItem)))
                .andExpect(status().isBadRequest());

        Map<String, Object> invalid = new java.util.HashMap<>(common);
        invalid.put("discountPaise", 401);
        mvc.perform(post("/api/billing/invoices").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest());

        Map<String, Object> valid = new java.util.HashMap<>(common);
        valid.put("discountPaise", 400);
        mvc.perform(post("/api/billing/invoices").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(valid)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.totalPaise").value(0))
                .andExpect(jsonPath("$.duePaise").value(0));

        Map<String, Object> foreignPatient = new java.util.HashMap<>(common);
        foreignPatient.put("patientId", otherHospitalPatient.getId());
        mvc.perform(post("/api/billing/invoices").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(foreignPatient)))
                .andExpect(status().isNotFound());
    }

    @Test
    void dispensingConsumesEarliestUnexpiredBatchesAndRejectsShortage() throws Exception {
        String token = login("pharmacy1");
        MvcResult medicineResponse = mvc.perform(post("/api/pharmacy/medicines")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Medicine A","form":"tablet","strength":"10mg","unit":"tablet",
                                 "taxRatePct":0,"reorderLevel":5}
                                """))
                .andExpect(status().isCreated())
                .andReturn();
        long medicineId = mapper.readTree(medicineResponse.getResponse().getContentAsString()).path("id").asLong();

        receive(token, medicineId, "BATCH-LATE", LocalDate.now(ZoneOffset.UTC).plusMonths(8), 5, 200);
        receive(token, medicineId, "BATCH-EARLY", LocalDate.now(ZoneOffset.UTC).plusMonths(2), 2, 100);

        mvc.perform(post("/api/pharmacy/dispensings")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", otherHospitalPatient.getId(), "items",
                                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 1))))))
                .andExpect(status().isNotFound());

        MvcResult dispensed = mvc.perform(post("/api/pharmacy/dispensings")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(), "items",
                                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 5))))))
                .andExpect(status().isCreated())
                .andReturn();
        JsonNode response = mapper.readTree(dispensed.getResponse().getContentAsString());
        assertEquals(2, response.path("items").size());
        assertEquals("BATCH-EARLY", response.path("items").get(0).path("batchNo").asText());
        assertEquals(800, response.path("totalAmountPaise").asLong());

        mvc.perform(post("/api/pharmacy/dispensings")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(), "items",
                                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 3))))))
                .andExpect(status().isConflict());
        MvcResult medicineList = mvc.perform(get("/api/pharmacy/medicines")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk()).andReturn();
        assertEquals(2, findById(mapper.readTree(medicineList.getResponse().getContentAsString()), medicineId)
                .path("stockQty").asInt());
    }

    @Test
    void concurrentDispensingsCannotOversellTheSameBatch() throws Exception {
        String token = login("pharmacy1");
        MvcResult medicineResponse = mvc.perform(post("/api/pharmacy/medicines")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Concurrent Medicine","form":"tablet","strength":"10mg","unit":"tablet",
                                 "taxRatePct":0,"reorderLevel":0}
                                """))
                .andExpect(status().isCreated())
                .andReturn();
        long medicineId = mapper.readTree(medicineResponse.getResponse().getContentAsString()).path("id").asLong();
        receive(token, medicineId, "CONCURRENT-BATCH", LocalDate.now(ZoneOffset.UTC).plusDays(30), 5, 100);
        String request = mapper.writeValueAsString(Map.of("patientId", patient.getId(), "items",
                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 4))));

        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        try {
            Future<Integer> first = executor.submit(() -> concurrentDispense(token, request, ready, start));
            Future<Integer> second = executor.submit(() -> concurrentDispense(token, request, ready, start));
            assertTrue(ready.await(10, TimeUnit.SECONDS));
            start.countDown();
            int firstStatus = first.get(30, TimeUnit.SECONDS);
            int secondStatus = second.get(30, TimeUnit.SECONDS);

            assertEquals(1, java.util.stream.Stream.of(firstStatus, secondStatus).filter(status -> status == 201).count());
            assertEquals(1, java.util.stream.Stream.of(firstStatus, secondStatus).filter(status -> status == 409).count());
            int stock = batches.findAllByHospitalIdAndMedicineIdAndDeletedFalseOrderByExpiryDateAsc(42L, medicineId)
                    .stream().mapToInt(MedicineBatch::getQuantityOnHand).sum();
            assertEquals(1, stock);
        } finally {
            start.countDown();
            executor.shutdownNow();
        }
    }

    @Test
    void batchesExpiringTodayAreExcludedFromPharmacyAndReportStock() throws Exception {
        String pharmacyToken = login("pharmacy1");
        MvcResult medicineResponse = mvc.perform(post("/api/pharmacy/medicines")
                        .header("Authorization", bearer(pharmacyToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Today Expiry Medicine","form":"tablet","strength":"10mg","unit":"tablet",
                                 "taxRatePct":0,"reorderLevel":1}
                                """))
                .andExpect(status().isCreated())
                .andReturn();
        long medicineId = mapper.readTree(medicineResponse.getResponse().getContentAsString()).path("id").asLong();
        var medicine = medicines.findById(medicineId).orElseThrow();
        batches.save(new MedicineBatch(42L, medicine, "TODAY-EXPIRY", LocalDate.now(ZoneOffset.UTC),
                null, 5, 50, 100, null));

        MvcResult medicineList = mvc.perform(get("/api/pharmacy/medicines")
                        .header("Authorization", bearer(pharmacyToken)))
                .andExpect(status().isOk()).andReturn();
        JsonNode pharmacyMedicine = findById(mapper.readTree(medicineList.getResponse().getContentAsString()),
                medicineId);
        assertEquals(0, pharmacyMedicine.path("stockQty").asInt());

        MvcResult alerts = mvc.perform(get("/api/reports/stock-alerts")
                        .header("Authorization", bearer(login("accounts1"))))
                .andExpect(status().isOk()).andReturn();
        JsonNode stockAlert = findById(mapper.readTree(alerts.getResponse().getContentAsString()), medicineId);
        assertEquals(0, stockAlert.path("stockQty").asInt());
    }

    @Test
    void visitAdmissionAndPrescriptionReferencesAreHospitalAndPatientScoped() throws Exception {
        String doctorToken = login("doctor1");
        String visitUuid = UUID.randomUUID().toString();
        Map<String, Object> visitRequest = Map.of(
                "uuid", visitUuid,
                "patientUuid", patient.getUuid(),
                "visitType", "opd",
                "visitDate", LocalDate.now(ZoneOffset.UTC).toString(),
                "status", "open");
        MvcResult visitResponse = mvc.perform(post("/api/visits")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(visitRequest)))
                .andExpect(status().isCreated()).andReturn();
        long visitId = mapper.readTree(visitResponse.getResponse().getContentAsString()).path("id").asLong();
        mvc.perform(post("/api/visits").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(visitRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(visitId));

        Map<String, Object> foreignVisit = new java.util.HashMap<>(visitRequest);
        foreignVisit.put("uuid", UUID.randomUUID().toString());
        foreignVisit.put("patientUuid", otherHospitalPatient.getUuid());
        mvc.perform(post("/api/visits").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(foreignVisit)))
                .andExpect(status().isNotFound());

        String admissionUuid = UUID.randomUUID().toString();
        Map<String, Object> admissionRequest = Map.of(
                "uuid", admissionUuid,
                "patientUuid", patient.getUuid(),
                "visitUuid", visitUuid,
                "admitDate", LocalDate.now(ZoneOffset.UTC).toString(),
                "reason", "Observation",
                "status", "admitted");
        MvcResult admissionResponse = mvc.perform(post("/api/admissions")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(admissionRequest)))
                .andExpect(status().isCreated()).andReturn();
        assertEquals(visitId, mapper.readTree(admissionResponse.getResponse().getContentAsString())
                .path("visitId").asLong());

        Map<String, Object> mismatchedAdmission = new java.util.HashMap<>(admissionRequest);
        mismatchedAdmission.put("uuid", UUID.randomUUID().toString());
        mismatchedAdmission.put("patientUuid", otherHospitalPatient.getUuid());
        mvc.perform(post("/api/admissions").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(mismatchedAdmission)))
                .andExpect(status().isNotFound());

        String secondPatientUuid = UUID.randomUUID().toString();
        PatientRecord secondPatient = patients.save(new PatientRecord(42L, secondPatientUuid,
                "UHID-" + secondPatientUuid.substring(0, 8), "Another Local Patient"));
        Map<String, Object> wrongPatientVisit = new java.util.HashMap<>(admissionRequest);
        wrongPatientVisit.put("uuid", UUID.randomUUID().toString());
        wrongPatientVisit.put("patientUuid", secondPatient.getUuid());
        mvc.perform(post("/api/admissions").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(wrongPatientVisit)))
                .andExpect(status().isBadRequest());

        String prescriptionUuid = UUID.randomUUID().toString();
        MvcResult prescriptionResponse = mvc.perform(post("/api/prescriptions")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("uuid", prescriptionUuid,
                                "visitUuid", visitUuid, "doctorId", doctor.getId()))))
                .andExpect(status().isCreated()).andReturn();
        assertEquals(patient.getId(), mapper.readTree(prescriptionResponse.getResponse().getContentAsString())
                .path("patientId").asLong());
        long prescriptionId = mapper.readTree(prescriptionResponse.getResponse().getContentAsString())
                .path("id").asLong();

        String pharmacyToken = login("pharmacy1");
        MvcResult medicineResponse = mvc.perform(post("/api/pharmacy/medicines")
                        .header("Authorization", bearer(pharmacyToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Prescription Medicine","form":"tablet","strength":"10mg","unit":"tablet",
                                 "taxRatePct":0,"reorderLevel":0}
                                """))
                .andExpect(status().isCreated()).andReturn();
        long medicineId = mapper.readTree(medicineResponse.getResponse().getContentAsString()).path("id").asLong();
        receive(pharmacyToken, medicineId, "PRESCRIPTION-BATCH",
                LocalDate.now(ZoneOffset.UTC).plusDays(30), 2, 100);
        MvcResult dispensing = mvc.perform(post("/api/pharmacy/dispensings")
                        .header("Authorization", bearer(pharmacyToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(),
                                "prescriptionUuid", prescriptionUuid, "items",
                                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 1))))))
                .andExpect(status().isCreated()).andReturn();
        assertEquals(prescriptionId,
                mapper.readTree(dispensing.getResponse().getContentAsString()).path("prescriptionId").asLong());

        mvc.perform(post("/api/pharmacy/dispensings")
                        .header("Authorization", bearer(pharmacyToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(),
                                "prescriptionUuid", UUID.randomUUID().toString(), "items",
                                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 1))))))
                .andExpect(status().isNotFound());

        MvcResult invoice = mvc.perform(post("/api/billing/invoices")
                        .header("Authorization", bearer(login("accounts1"))).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(),
                                "patientName", patient.getName(), "invoiceType", "ipd", "discountPaise", 0,
                                "visitUuid", visitUuid, "admissionUuid", admissionUuid,
                                "items", java.util.List.of(Map.of("itemType", "service", "description", "Bed",
                                        "qty", 1, "unitPricePaise", 100, "discountPaise", 0, "taxRatePct", 0))))))
                .andExpect(status().isCreated()).andReturn();
        assertEquals(visitId, mapper.readTree(invoice.getResponse().getContentAsString()).path("visitId").asLong());

        mvc.perform(post("/api/billing/invoices")
                        .header("Authorization", bearer(login("accounts1"))).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(),
                                "patientName", patient.getName(), "invoiceType", "ipd", "discountPaise", 0,
                                "visitUuid", visitUuid, "admissionUuid", UUID.randomUUID().toString(),
                                "items", java.util.List.of(Map.of("itemType", "service", "description", "Bed",
                                        "qty", 1, "unitPricePaise", 100, "discountPaise", 0, "taxRatePct", 0))))))
                .andExpect(status().isNotFound());
    }

    @Test
    void outstandingReportValueIsCurrentAcrossTheSelectedDateRange() throws Exception {
        String token = login("accounts1");
        MvcResult beforeResponse = mvc.perform(get("/api/reports/summary")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk()).andReturn();
        long outstandingBefore = mapper.readTree(beforeResponse.getResponse().getContentAsString())
                .path("outstandingPaise").asLong();

        mvc.perform(post("/api/billing/invoices").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(),
                                "patientName", patient.getName(), "invoiceType", "opd", "discountPaise", 0,
                                "items", java.util.List.of(Map.of("itemType", "service", "description", "Visit",
                                        "qty", 1, "unitPricePaise", 1000, "discountPaise", 0, "taxRatePct", 0))))))
                .andExpect(status().isCreated());

        MvcResult historicalResponse = mvc.perform(get("/api/reports/summary")
                        .param("from", "2000-01-01").param("to", "2000-01-01")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk()).andReturn();
        JsonNode summary = mapper.readTree(historicalResponse.getResponse().getContentAsString());
        assertEquals(0, summary.path("invoiceCount").asInt());
        assertEquals(outstandingBefore + 1000, summary.path("outstandingPaise").asLong());
    }

    @Test
    void labOrdersRequireOrderedWorkflowAndConfiguredResults() throws Exception {
        String doctorToken = login("doctor1");
        String labToken = login("lab1");
        String visitUuid = UUID.randomUUID().toString();
        MvcResult visitResponse = mvc.perform(post("/api/visits")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("uuid", visitUuid,
                                "patientUuid", patient.getUuid(), "visitType", "opd",
                                "visitDate", LocalDate.now(ZoneOffset.UTC).toString(), "status", "open"))))
                .andExpect(status().isCreated()).andReturn();
        long visitId = mapper.readTree(visitResponse.getResponse().getContentAsString()).path("id").asLong();
        MvcResult testResult = mvc.perform(post("/api/lab/tests")
                        .header("Authorization", bearer(labToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Complete Blood Count","category":"Blood","sampleType":"Blood",
                                 "pricePaise":5000,"turnaroundHours":24,
                                 "parameters":[{"parameterName":"Hemoglobin","unit":"g/dL","rangeLow":12.0,"rangeHigh":17.0}]}
                                """))
                .andExpect(status().isCreated()).andReturn();
        long testId = mapper.readTree(testResult.getResponse().getContentAsString()).path("id").asLong();

        Map<String, Object> orderRequest = new java.util.HashMap<>(Map.of(
                "patientId", patient.getId(),
                "patientName", patient.getName(),
                "uhid", patient.getUhid(),
                "visitUuid", visitUuid,
                "doctorId", doctor.getId(),
                "testId", testId));

        Map<String, Object> foreignPatient = new java.util.HashMap<>(orderRequest);
        foreignPatient.put("patientId", otherHospitalPatient.getId());
        mvc.perform(post("/api/lab/orders").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(foreignPatient)))
                .andExpect(status().isNotFound());

        Map<String, Object> foreignDoctor = new java.util.HashMap<>(orderRequest);
        foreignDoctor.put("doctorId", otherHospitalDoctor.getId());
        mvc.perform(post("/api/lab/orders").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(foreignDoctor)))
                .andExpect(status().isNotFound());

        Map<String, Object> invalidPriority = new java.util.HashMap<>(orderRequest);
        invalidPriority.put("priority", "immediate");
        mvc.perform(post("/api/lab/orders").header("Authorization", bearer(doctorToken))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(invalidPriority)))
                .andExpect(status().isBadRequest());

        mvc.perform(post("/api/lab/tests")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Unauthorized test\",\"pricePaise\":100,\"turnaroundHours\":1}"))
                .andExpect(status().isForbidden());

        MvcResult orderResult = mvc.perform(post("/api/lab/orders")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", patient.getId(),
                                "patientName", patient.getName(), "uhid", patient.getUhid(),
                                "visitUuid", visitUuid,
                                "doctorId", doctor.getId(), "testId", testId))))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.status").value("pending"))
                .andExpect(jsonPath("$.visitId").value(visitId))
                .andReturn();
        long orderId = mapper.readTree(orderResult.getResponse().getContentAsString()).path("id").asLong();
        mvc.perform(get("/api/lab/orders").header("Authorization", bearer(login("doctor2"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));

        mvc.perform(post("/api/lab/orders/{id}/results", orderId)
                        .header("Authorization", bearer(labToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"results":[{"parameterName":"Hemoglobin","value":"14.2","unit":"g/dL",
                                 "referenceRange":"12-17 g/dL","abnormalFlag":"normal"}]}
                                """))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/lab/orders/{id}/collect", orderId)
                        .header("Authorization", bearer(labToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("collected"));
        mvc.perform(post("/api/lab/orders/{id}/start", orderId)
                        .header("Authorization", bearer(labToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("processing"));
        mvc.perform(post("/api/lab/orders/{id}/results", orderId)
                        .header("Authorization", bearer(labToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"results":[{"parameterName":"Hemoglobin","value":"14.2","unit":"g/dL",
                                 "referenceRange":"12-17 g/dL","abnormalFlag":"normal"}]}
                                """))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("resulted"));
        mvc.perform(post("/api/lab/orders/{id}/verify", orderId).header("Authorization", bearer(labToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("verified"));
        mvc.perform(post("/api/lab/orders/{id}/deliver", orderId).header("Authorization", bearer(labToken)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("delivered"));
    }

    private void receive(String token, long medicineId, String batch, LocalDate expiry, int qty, long mrp)
            throws Exception {
        mvc.perform(post("/api/pharmacy/stock/receive")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("medicineId", medicineId, "batchNo", batch,
                                "expiryDate", expiry.toString(), "quantity", qty, "purchasePricePaise", mrp / 2,
                                "mrpPaise", mrp))))
                .andExpect(status().isCreated());
    }

    private String login(String username) throws Exception {
        MvcResult result = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("username", username,
                                "password", "CorrectHorseBattery9!"))))
                .andExpect(status().isOk()).andReturn();
        return mapper.readTree(result.getResponse().getContentAsString()).path("accessToken").asText();
    }

    private static String bearer(String token) { return "Bearer " + token; }

    private StaffMember saveDoctor(long hospitalId, String name, String phone) {
        return staff.save(new StaffMember(hospitalId, name, "Other", null, phone, null, "", "doctor", null,
                "", null, null, "", 0, 0, 7, 30, true));
    }

    private int concurrentDispense(String token, String request, CountDownLatch ready, CountDownLatch start)
            throws Exception {
        ready.countDown();
        if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("Concurrent test did not start");
        return mvc.perform(post("/api/pharmacy/dispensings").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(request))
                .andReturn().getResponse().getStatus();
    }

    private static JsonNode findById(JsonNode rows, long id) {
        for (JsonNode row : rows) {
            if (row.path("id").asLong() == id || row.path("medicineId").asLong() == id) return row;
        }
        throw new AssertionError("Expected record was not found");
    }
}
