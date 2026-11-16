package com.caresync.backend;

import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;
import com.caresync.backend.security.RefreshTokenRepository;
import com.caresync.backend.security.SecurityAuditEventRepository;
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
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
        accounts.save(new AuthAccount("lab1", passwordEncoder.encode("CorrectHorseBattery9!"),
                "Lab Technician", "LAB_TECHNICIAN", 42L));
    }

    @Test
    void invoiceTotalsAndPaymentsAreCalculatedAndHospitalScoped() throws Exception {
        String billingToken = login("accounts1");
        String invoiceJson = """
                {
                  "patientId": 15,
                  "patientName": "Test Patient",
                  "uhid": "UHID-15",
                  "invoiceType": "opd",
                  "discountPaise": 100,
                  "items": [
                    {"itemType":"service","description":"Consultation","qty":2,"unitPricePaise":1000,"discountPaise":0,"taxRatePct":10}
                  ]
                }
                """;
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

        receive(token, medicineId, "BATCH-LATE", LocalDate.now().plusMonths(8), 5, 200);
        receive(token, medicineId, "BATCH-EARLY", LocalDate.now().plusMonths(2), 2, 100);

        MvcResult dispensed = mvc.perform(post("/api/pharmacy/dispensings")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", 20, "items",
                                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 5))))))
                .andExpect(status().isCreated())
                .andReturn();
        JsonNode response = mapper.readTree(dispensed.getResponse().getContentAsString());
        assertEquals(2, response.path("items").size());
        assertEquals("BATCH-EARLY", response.path("items").get(0).path("batchNo").asText());
        assertEquals(800, response.path("totalAmountPaise").asLong());

        mvc.perform(post("/api/pharmacy/dispensings")
                        .header("Authorization", bearer(token)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", 20, "items",
                                java.util.List.of(Map.of("medicineId", medicineId, "quantity", 3))))))
                .andExpect(status().isConflict());
        mvc.perform(get("/api/pharmacy/medicines").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].stockQty").value(2));
    }

    @Test
    void labOrdersRequireOrderedWorkflowAndConfiguredResults() throws Exception {
        String doctorToken = login("doctor1");
        String labToken = login("lab1");
        MvcResult testResult = mvc.perform(post("/api/lab/tests")
                        .header("Authorization", bearer(labToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Complete Blood Count","category":"Blood","sampleType":"Blood",
                                 "pricePaise":5000,"turnaroundHours":24,
                                 "parameters":[{"parameterName":"Hemoglobin","unit":"g/dL","rangeLow":12.0,"rangeHigh":17.0}]}
                                """))
                .andExpect(status().isCreated()).andReturn();
        long testId = mapper.readTree(testResult.getResponse().getContentAsString()).path("id").asLong();

        mvc.perform(post("/api/lab/tests")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Unauthorized test\",\"pricePaise\":100,\"turnaroundHours\":1}"))
                .andExpect(status().isForbidden());

        MvcResult orderResult = mvc.perform(post("/api/lab/orders")
                        .header("Authorization", bearer(doctorToken)).contentType(MediaType.APPLICATION_JSON)
                        .content(mapper.writeValueAsString(Map.of("patientId", 99, "patientName", "Lab Patient",
                                "testId", testId))))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.status").value("pending"))
                .andReturn();
        long orderId = mapper.readTree(orderResult.getResponse().getContentAsString()).path("id").asLong();

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
}
