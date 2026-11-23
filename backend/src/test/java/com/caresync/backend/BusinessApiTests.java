package com.caresync.backend;

import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.security.SecurityAuditEventRepository;
import com.caresync.backend.patient.entity.PatientRecord;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.reference.AdmissionRepository;
import com.caresync.backend.reference.BedRecord;
import com.caresync.backend.reference.BedRepository;
import com.caresync.backend.reference.PrescriptionRepository;
import com.caresync.backend.reference.VisitRecord;
import com.caresync.backend.reference.VisitRepository;
import com.caresync.backend.lab.entity.LabOrder;
import com.caresync.backend.lab.entity.LabTest;
import com.caresync.backend.lab.repository.LabOrderRepository;
import com.caresync.backend.lab.repository.LabTestRepository;
import com.caresync.backend.billing.entity.Invoice;
import com.caresync.backend.billing.entity.Payment;
import com.caresync.backend.billing.repository.InvoiceRepository;
import com.caresync.backend.pharmacy.repository.DispensingRepository;
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
    @Autowired DispensingRepository dispensings;
    @Autowired VisitRepository visits;
    @Autowired BedRepository beds;
    @Autowired AdmissionRepository admissions;
    @Autowired PrescriptionRepository prescriptions;
    @Autowired LabOrderRepository labOrders;
    @Autowired LabTestRepository labTests;
    @Autowired InvoiceRepository invoices;

    private PatientRecord patient;
    private PatientRecord otherHospitalPatient;
    private StaffMember doctor;
    private StaffMember otherHospitalDoctor;

    @BeforeEach
    void resetAccounts() {
        beds.deleteAll();
        dispensings.deleteAll();
        prescriptions.deleteAll();
        admissions.deleteAll();
        invoices.deleteAll();
        visits.deleteAll();
        labOrders.deleteAll();
        refreshTokens.deleteAll();
        auditEvents.deleteAll();
        accounts.deleteAll();
        accounts.save(new AuthAccount("accounts1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Billing Officer", "ACCOUNTS", 42L));
        accounts.save(new AuthAccount("admin1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Hospital Admin", "ADMIN", 42L));
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
    void staffPhoneMustContainExactlyTenDigits() throws Exception {
        String token = login("admin1");
        Map<String, Object> request = new java.util.HashMap<>(Map.of(
                "name", "Phone Validation Staff",
                "gender", "Other",
                "phone", "9876543210",
                "role", "staff",
                "consultationFeePaise", 0L,
                "followupFeePaise", 0L));

        mvc.perform(post("/api/staff").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.phone").value("9876543210"));

        for (String invalidPhone : java.util.List.of("12345abc90", "123456789", "12345678901")) {
            request.put("phone", invalidPhone);
            mvc.perform(post("/api/staff").header("Authorization", bearer(token))
                            .contentType(MediaType.APPLICATION_JSON).content(mapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
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
                .path("currentOutstandingPaise").asLong();

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
        assertEquals(outstandingBefore + 1000, summary.path("currentOutstandingPaise").asLong());
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

    @Test
    void dashboardStatisticsCalculationsAndScenarioVerification() throws Exception {
        String token = login("admin1");
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        LocalDate yesterday = today.minusDays(1);

        // Scenario 1: Empty database returns zeroes cleanly
        MvcResult emptyRes = mvc.perform(get("/api/reports/dashboard/stats")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.todayOpdPatients").value(0))
                .andExpect(jsonPath("$.data.todayRevenue").value(0.0))
                .andExpect(jsonPath("$.data.bedOccupancy.totalBeds").value(0))
                .andExpect(jsonPath("$.data.bedOccupancy.occupiedBeds").value(0))
                .andExpect(jsonPath("$.data.bedOccupancy.availableBeds").value(0))
                .andExpect(jsonPath("$.data.bedOccupancy.occupancyPercentage").value(0.0))
                .andExpect(jsonPath("$.data.pendingLabTests").value(0))
                .andReturn();

        // Scenario 2: Register new OPD visit today
        String visitUuid1 = UUID.randomUUID().toString();
        mvc.perform(post("/api/visits")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "uuid", visitUuid1,
                                "patientUuid", patient.getUuid(),
                                "doctorId", doctor.getId(),
                                "visitType", "opd",
                                "visitDate", today.toString(),
                                "status", "open"
                        ))))
                .andExpect(status().isCreated());

        // Verify count is now 1
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.todayOpdPatients").value(1));

        // Scenario 3: Multiple visits by SAME patient today does NOT cause duplicate counting
        String visitUuid2 = UUID.randomUUID().toString();
        mvc.perform(post("/api/visits")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "uuid", visitUuid2,
                                "patientUuid", patient.getUuid(),
                                "doctorId", doctor.getId(),
                                "visitType", "opd",
                                "visitDate", today.toString(),
                                "status", "closed"
                        ))))
                .andExpect(status().isCreated());

        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.todayOpdPatients").value(1))
                .andExpect(jsonPath("$.data.todayOpdVisits").value(2));

        // Scenario 4: Visit from previous date does NOT affect today's count
        String visitYesterday = UUID.randomUUID().toString();
        mvc.perform(post("/api/visits")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "uuid", visitYesterday,
                                "patientUuid", otherHospitalPatient.getUuid(),
                                "doctorId", doctor.getId(),
                                "visitType", "opd",
                                "visitDate", yesterday.toString(),
                                "status", "open"
                        ))))
                .andExpect(status().isNotFound()); // other hospital patient rejected with 404

        String p2Uuid = UUID.randomUUID().toString();
        PatientRecord patient2 = patients.save(new PatientRecord(42L, p2Uuid, "UHID-P2", "Patient 2"));
        mvc.perform(post("/api/visits")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "uuid", visitYesterday,
                                "patientUuid", patient2.getUuid(),
                                "doctorId", doctor.getId(),
                                "visitType", "opd",
                                "visitDate", yesterday.toString(),
                                "status", "open"
                        ))))
                .andExpect(status().isCreated());

        // Still today count is 1
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.todayOpdPatients").value(1));

        // Scenario 5: Successful payment recorded -> todayRevenue increases
        String accountsToken = login("accounts1");
        MvcResult invoiceRes = mvc.perform(post("/api/billing/invoices")
                        .header("Authorization", bearer(accountsToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "patientId", patient.getId(),
                                "patientName", patient.getName(),
                                "invoiceType", "opd",
                                "discountPaise", 0,
                                "items", java.util.List.of(Map.of(
                                        "itemType", "service",
                                        "description", "Consultation",
                                        "qty", 1,
                                        "unitPricePaise", 50000,
                                        "discountPaise", 0,
                                        "taxRatePct", 0
                                ))
                        ))))
                .andExpect(status().isCreated())
                .andReturn();
        long invoiceId = mapper.readTree(invoiceRes.getResponse().getContentAsString()).path("id").asLong();

        // Add payment of 50000 paise (₹500.00)
        mvc.perform(post("/api/billing/invoices/" + invoiceId + "/payments")
                        .header("Authorization", bearer(accountsToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "paymentMode", "cash",
                                "amountPaise", 50000,
                                "referenceNo", "REC-001"
                        ))))
                .andExpect(status().isCreated());

        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.todayRevenue").value(500.0))
                .andExpect(jsonPath("$.data.todayRevenuePaise").value(50000));

        // Scenario 6: Cancelled invoice is excluded from revenue
        MvcResult cancelledInvRes = mvc.perform(post("/api/billing/invoices")
                        .header("Authorization", bearer(accountsToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "patientId", patient.getId(),
                                "patientName", patient.getName(),
                                "invoiceType", "opd",
                                "discountPaise", 0,
                                "items", java.util.List.of(Map.of(
                                        "itemType", "service",
                                        "description", "Procedure",
                                        "qty", 1,
                                        "unitPricePaise", 30000,
                                        "discountPaise", 0,
                                        "taxRatePct", 0
                                ))
                        ))))
                .andExpect(status().isCreated())
                .andReturn();
        long cancelledInvId = mapper.readTree(cancelledInvRes.getResponse().getContentAsString()).path("id").asLong();
        mvc.perform(post("/api/billing/invoices/" + cancelledInvId + "/payments")
                        .header("Authorization", bearer(accountsToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "paymentMode", "upi",
                                "amountPaise", 30000,
                                "referenceNo", "REC-002"
                        ))))
                .andExpect(status().isCreated());
        // Cancel the second invoice
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete("/api/billing/invoices/" + cancelledInvId)
                        .header("Authorization", bearer(accountsToken)))
                .andExpect(status().isNoContent());

        // Revenue should still be ₹500.00, cancelled invoice payment is excluded!
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.todayRevenue").value(500.0));

        // Scenario 7: Bed Creation and Allocation
        // Create 2 beds
        MvcResult bed1Res = mvc.perform(post("/api/admissions/beds")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "bedNumber", "B-101",
                                "ward", "General Ward",
                                "bedType", "General",
                                "tariffPaise", 80000,
                                "status", "available"
                        ))))
                .andExpect(status().isCreated())
                .andReturn();
        long bed1Id = mapper.readTree(bed1Res.getResponse().getContentAsString()).path("id").asLong();

        mvc.perform(post("/api/admissions/beds")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "bedNumber", "B-102",
                                "ward", "ICU",
                                "bedType", "ICU",
                                "tariffPaise", 250000,
                                "status", "available"
                        ))))
                .andExpect(status().isCreated());

        // Check occupancy: 0/2 = 0%
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bedOccupancy.totalBeds").value(2))
                .andExpect(jsonPath("$.data.bedOccupancy.occupiedBeds").value(0))
                .andExpect(jsonPath("$.data.bedOccupancy.availableBeds").value(2))
                .andExpect(jsonPath("$.data.bedOccupancy.occupancyPercentage").value(0.0));

        // Allocate Bed 1
        mvc.perform(post("/api/admissions/beds/" + bed1Id + "/allocate")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "patientId", patient.getId(),
                                "patientName", patient.getName(),
                                "uhid", patient.getUhid()
                        ))))
                .andExpect(status().isOk());

        // Check occupancy: 1/2 = 50%
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bedOccupancy.totalBeds").value(2))
                .andExpect(jsonPath("$.data.bedOccupancy.occupiedBeds").value(1))
                .andExpect(jsonPath("$.data.bedOccupancy.availableBeds").value(1))
                .andExpect(jsonPath("$.data.bedOccupancy.occupancyPercentage").value(50.0));

        // Scenario 8: Release bed
        mvc.perform(post("/api/admissions/beds/" + bed1Id + "/release?status=available")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk());

        // Check occupancy back to 0%
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bedOccupancy.occupiedBeds").value(0))
                .andExpect(jsonPath("$.data.bedOccupancy.availableBeds").value(2))
                .andExpect(jsonPath("$.data.bedOccupancy.occupancyPercentage").value(0.0));

        // Scenario 9 & 10: Lab Orders
        // Create Lab Test
        String labToken = login("lab1");
        MvcResult testRes = mvc.perform(post("/api/lab/tests")
                        .header("Authorization", bearer(labToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "name", "Complete Blood Count",
                                "category", "Hematology",
                                "sampleType", "Whole Blood",
                                "turnaroundHours", 4,
                                "pricePaise", 40000,
                                "parameters", java.util.List.of(Map.of(
                                        "parameterName", "Hemoglobin",
                                        "unit", "g/dL",
                                        "rangeLow", 12.0,
                                        "rangeHigh", 16.0
                                ))
                        ))))
                .andExpect(status().isCreated())
                .andReturn();
        long labTestId = mapper.readTree(testRes.getResponse().getContentAsString()).path("id").asLong();

        // Create Lab Order
        String docToken = login("doctor1");
        MvcResult orderRes = mvc.perform(post("/api/lab/orders")
                        .header("Authorization", bearer(docToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "patientId", patient.getId(),
                                "patientName", patient.getName(),
                                "uhid", patient.getUhid(),
                                "testId", labTestId,
                                "priority", "routine"
                        ))))
                .andExpect(status().isCreated())
                .andReturn();
        long labOrderId = mapper.readTree(orderRes.getResponse().getContentAsString()).path("id").asLong();

        // Pending count is 1
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pendingLabTests").value(1));

        // Sample collected -> still pending
        mvc.perform(post("/api/lab/orders/" + labOrderId + "/collect")
                        .header("Authorization", bearer(labToken)))
                .andExpect(status().isOk());
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pendingLabTests").value(1));

        // Results entered -> resulted
        mvc.perform(post("/api/lab/orders/" + labOrderId + "/results")
                        .header("Authorization", bearer(labToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of(
                                "results", java.util.List.of(Map.of(
                                        "parameterName", "Hemoglobin",
                                        "resultValue", "13.5",
                                        "unit", "g/dL",
                                        "referenceRange", "12-16"
                                ))
                        ))))
                .andExpect(status().isOk());

        // Once resulted, it is no longer pending!
        mvc.perform(get("/api/reports/dashboard/stats").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pendingLabTests").value(0));

        // Scenario 11: Granular single metric endpoints
        mvc.perform(get("/api/reports/dashboard/today-opd-patients").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.todayOpdPatients").value(1));

        mvc.perform(get("/api/reports/dashboard/today-revenue").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.todayRevenue").value(500.0));

        mvc.perform(get("/api/reports/dashboard/bed-occupancy").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalBeds").value(2));

        mvc.perform(get("/api/reports/dashboard/pending-lab-tests").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.pendingLabTests").value(0));
    }

    private static JsonNode findById(JsonNode rows, long id) {
        for (JsonNode row : rows) {
            if (row.path("id").asLong() == id || row.path("medicineId").asLong() == id) return row;
        }
        throw new AssertionError("Expected record was not found");
    }
}
