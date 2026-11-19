
package com.caresync.backend.facility.controller;

import java.time.Instant;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.repository.WardRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;

import tools.jackson.databind.ObjectMapper;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789",
        "spring.datasource.url=jdbc:h2:mem:caresync-ward-api-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
@AutoConfigureMockMvc
class WardControllerTests {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired WardRepository wardRepository;
    @Autowired AuthAccountRepository accounts;
    @Autowired PasswordEncoder passwordEncoder;
    @Autowired JwtEncoder jwtEncoder;

    private String hospital42Token;
    private String hospital99Token;

    @BeforeEach
    void setUp() {
        wardRepository.deleteAll();
        accounts.deleteAll();

        accounts.save(new AuthAccount(
                "doctor42",
                passwordEncoder.encode("TestPassword123!"),
                "Doctor 42",
                "DOCTOR",
                42L
        ));

        accounts.save(new AuthAccount(
                "doctor99",
                passwordEncoder.encode("TestPassword123!"),
                "Doctor 99",
                "DOCTOR",
                99L
        ));

        hospital42Token = createToken("doctor42", 42L);
        hospital99Token = createToken("doctor99", 99L);
    }


    
    @Test
    void anonymousUserCannotAccessWards() throws Exception {
        mvc.perform(get("/api/v1/facilities/wards"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedUserCanCreateWard() throws Exception {
        mvc.perform(post("/api/v1/facilities/wards")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "General Ward",
                                  "wardCode": "GW-01",
                                  "description": "General patient ward"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("General Ward"))
                .andExpect(jsonPath("$.wardCode").value("GW-01"))
                .andExpect(jsonPath("$.active").value(true));
    }

    @Test
    void userCanOnlySeeWardsBelongingToTheirHospital() throws Exception {
        wardRepository.save(new Ward(
                42L, "General Ward", "GW-01", "Hospital 42 ward"
        ));

        wardRepository.save(new Ward(
                99L, "Private Ward", "PW-01", "Hospital 99 ward"
        ));

        mvc.perform(get("/api/v1/facilities/wards")
                        .header("Authorization", hospital42Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].wardCode").value("GW-01"));
    }

    @Test
    void userCannotAccessAnotherHospitalsWard() throws Exception {
        Ward ward = wardRepository.save(new Ward(
                99L, "Private Ward", "PW-01", "Hospital 99 ward"
        ));

        mvc.perform(get("/api/v1/facilities/wards/" + ward.getId())
                        .header("Authorization", hospital42Token))
                .andExpect(status().isNotFound());
    }

    @Test
    void invalidWardRequestReturnsBadRequest() throws Exception {
        mvc.perform(post("/api/v1/facilities/wards")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "",
                                  "wardCode": "",
                                  "description": "Invalid ward"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void duplicateWardCodeInSameHospitalReturnsConflict() throws Exception {
        wardRepository.save(new Ward(
                42L, "General Ward", "GW-01", "Existing ward"
        ));

        mvc.perform(post("/api/v1/facilities/wards")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Another Ward",
                                  "wardCode": "GW-01",
                                  "description": "Duplicate code"
                                }
                                """))
                .andExpect(status().isConflict());
    }

@Test
void userCannotUpdateAnotherHospitalsWard() throws Exception {
    Ward ward = wardRepository.saveAndFlush(new Ward(
            99L, "Private Ward", "PW-01", "Hospital 99 ward"
    ));

    mvc.perform(put("/api/v1/facilities/wards/" + ward.getId())
                    .header("Authorization", hospital42Token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {
                              "name": "Modified Ward",
                              "wardCode": "MOD-01",
                              "description": "Unauthorized modification"
                            }
                            """))
            .andExpect(status().isNotFound());

    Ward unchanged = wardRepository.findById(ward.getId()).orElseThrow();
    org.junit.jupiter.api.Assertions.assertEquals("Private Ward", unchanged.getName());
    org.junit.jupiter.api.Assertions.assertEquals("PW-01", unchanged.getWardCode());
}

@Test
void userCannotChangeStatusOfAnotherHospitalsWard() throws Exception {
    Ward ward = wardRepository.saveAndFlush(new Ward(
            99L, "Private Ward", "PW-01", "Hospital 99 ward"
    ));

    mvc.perform(patch("/api/v1/facilities/wards/" + ward.getId() + "/status")
                    .header("Authorization", hospital42Token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {
                              "active": false
                            }
                            """))
            .andExpect(status().isNotFound());

    Ward unchanged = wardRepository.findById(ward.getId()).orElseThrow();
    org.junit.jupiter.api.Assertions.assertTrue(unchanged.isActive());
}



    @Test
void superAdminWithoutHospitalCannotAccessWards() throws Exception {

    accounts.save(new AuthAccount(
            "root",
            passwordEncoder.encode("TestPassword123!"),
            "Platform Admin",
            "SUPER_ADMIN",
            null
    ));

    String token = createToken("root", null);

    mvc.perform(get("/api/v1/facilities/wards")
                    .header("Authorization", token))
            .andExpect(status().isForbidden());
}

    
    private String createToken(String username, Long hospitalId) {
        AuthAccount account = accounts.findByUsername(username).orElseThrow();

        Instant now = Instant.now();

        JwtClaimsSet.Builder claims = JwtClaimsSet.builder()
                .issuer("caresync")
                .audience(List.of("caresync-api"))
                .subject(username)
                .issuedAt(now)
                .expiresAt(now.plusSeconds(300))
                .claim("uid", account.getId())
                .claim("name", account.getFullName())
                .claim("role", account.getRole())
                .claim("ver", account.getTokenVersion());

        if (hospitalId != null) {
            claims.claim("hospitalId", hospitalId);
        }

        return "Bearer " + jwtEncoder.encode(
                JwtEncoderParameters.from(
                        JwsHeader.with(MacAlgorithm.HS256).type("JWT").build(),
                        claims.build()
                )
        ).getTokenValue();
    }
}

