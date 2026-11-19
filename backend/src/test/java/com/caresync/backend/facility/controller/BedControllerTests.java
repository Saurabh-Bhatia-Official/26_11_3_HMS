
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

import com.caresync.backend.facility.entity.Bed;
import com.caresync.backend.facility.entity.BedStatus;
import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.repository.BedRepository;
import com.caresync.backend.facility.repository.RoomRepository;
import com.caresync.backend.facility.repository.WardRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789",
        "spring.datasource.url=jdbc:h2:mem:caresync-bed-api-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
@AutoConfigureMockMvc
class BedControllerTests {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private BedRepository bedRepository;

    @Autowired
    private RoomRepository roomRepository;

    @Autowired
    private WardRepository wardRepository;

    @Autowired
    private AuthAccountRepository accounts;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtEncoder jwtEncoder;

    private String hospital42Token;
    private String hospital99Token;

    private Ward hospital42Ward;
    private Ward hospital99Ward;

    @BeforeEach
    void setUp() {
        bedRepository.deleteAll();
        roomRepository.deleteAll();
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

        hospital42Ward = wardRepository.saveAndFlush(
                new Ward(
                        42L,
                        "General Ward",
                        "GEN-01",
                        "Hospital 42 ward"
                )
        );

        hospital99Ward = wardRepository.saveAndFlush(
                new Ward(
                        99L,
                        "Private Ward",
                        "PVT-01",
                        "Hospital 99 ward"
                )
        );
    }

    private Room createRoom(
            Long hospitalId,
            Ward ward,
            String roomNumber
    ) {
        return roomRepository.saveAndFlush(
                new Room(
                        hospitalId,
                        ward,
                        roomNumber,
                        "General",
                        "First Floor",
                        "Test room"
                )
        );
    }

    private Bed createBed(
            Long hospitalId,
            Room room,
            String bedNo,
            BedStatus status
    ) {
        return bedRepository.saveAndFlush(
                new Bed(
                        hospitalId,
                        room,
                        bedNo,
                        "General",
                        150000,
                        status
                )
        );
    }

    @Test
    void anonymousUserCannotAccessBeds() throws Exception {
        mvc.perform(get("/api/v1/facilities/beds"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedUserCanCreateBed() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        mvc.perform(post("/api/v1/facilities/beds")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": %d,
                                  "bedNo": "BED-01",
                                  "bedType": "General",
                                  "dailyTariffPaise": 150000
                                }
                                """.formatted(room.getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.bedNo").value("BED-01"))
                .andExpect(jsonPath("$.bedType").value("General"))
                .andExpect(jsonPath("$.dailyTariffPaise").value(150000))
                .andExpect(jsonPath("$.status").value("AVAILABLE"))
                .andExpect(jsonPath("$.roomId").value(room.getId()))
                .andExpect(jsonPath("$.wardName").value("General Ward"))
                .andExpect(jsonPath("$.uuid").exists());
    }

    @Test
    void userCanOnlySeeBedsBelongingToTheirHospital() throws Exception {
        Room room42 = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        Room room99 = createRoom(
                99L,
                hospital99Ward,
                "ROOM-201"
        );

        createBed(42L, room42, "BED-01", BedStatus.AVAILABLE);
        createBed(99L, room99, "BED-02", BedStatus.AVAILABLE);

        mvc.perform(get("/api/v1/facilities/beds")
                        .header("Authorization", hospital42Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].bedNo").value("BED-01"));
    }

    @Test
    void userCanFilterBedsByWardRoomAndStatus() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        createBed(42L, room, "BED-01", BedStatus.AVAILABLE);
        createBed(42L, room, "BED-02", BedStatus.CLEANING);

        mvc.perform(get("/api/v1/facilities/beds")
                        .param("wardId", hospital42Ward.getId().toString())
                        .param("roomId", room.getId().toString())
                        .param("status", "CLEANING")
                        .header("Authorization", hospital42Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].bedNo").value("BED-02"))
                .andExpect(jsonPath("$[0].status").value("CLEANING"));
    }

    @Test
    void authenticatedUserCanGetBedById() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        Bed bed = createBed(
                42L,
                room,
                "BED-01",
                BedStatus.AVAILABLE
        );

        mvc.perform(get("/api/v1/facilities/beds/" + bed.getId())
                        .header("Authorization", hospital42Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bedNo").value("BED-01"))
                .andExpect(jsonPath("$.roomNumber").value("ROOM-101"));
    }

    @Test
    void userCannotAccessAnotherHospitalsBed() throws Exception {
        Room room = createRoom(
                99L,
                hospital99Ward,
                "ROOM-201"
        );

        Bed bed = createBed(
                99L,
                room,
                "BED-99",
                BedStatus.AVAILABLE
        );

        mvc.perform(get("/api/v1/facilities/beds/" + bed.getId())
                        .header("Authorization", hospital42Token))
                .andExpect(status().isNotFound());
    }

    @Test
    void authenticatedUserCanUpdateBed() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        Bed bed = createBed(
                42L,
                room,
                "BED-01",
                BedStatus.AVAILABLE
        );

        mvc.perform(put("/api/v1/facilities/beds/" + bed.getId())
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": %d,
                                  "bedNo": "BED-02",
                                  "bedType": "ICU",
                                  "dailyTariffPaise": 250000
                                }
                                """.formatted(room.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bedNo").value("BED-02"))
                .andExpect(jsonPath("$.bedType").value("ICU"))
                .andExpect(jsonPath("$.dailyTariffPaise").value(250000));
    }

    @Test
    void authenticatedUserCanUpdateBedStatus() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        Bed bed = createBed(
                42L,
                room,
                "BED-01",
                BedStatus.AVAILABLE
        );

        mvc.perform(patch(
                        "/api/v1/facilities/beds/" + bed.getId() + "/status"
                )
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "MAINTENANCE"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("MAINTENANCE"));
    }


@Test
void userCannotUpdateAnotherHospitalsBed() throws Exception {
    Room room99 = createRoom(99L, hospital99Ward, "ROOM-201");

    Bed bed = createBed(
            99L, room99, "BED-99", BedStatus.AVAILABLE
    );

    Room room42 = createRoom(42L, hospital42Ward, "ROOM-101");

    mvc.perform(put("/api/v1/facilities/beds/" + bed.getId())
                    .header("Authorization", hospital42Token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {
                              "roomId": %d,
                              "bedNo": "BED-MOD",
                              "bedType": "ICU",
                              "dailyTariffPaise": 250000
                            }
                            """.formatted(room42.getId())))
            .andExpect(status().isNotFound());

    Bed unchanged = bedRepository.findById(bed.getId()).orElseThrow();
    org.junit.jupiter.api.Assertions.assertEquals("BED-99", unchanged.getBedNo());
    org.junit.jupiter.api.Assertions.assertEquals(
            BedStatus.AVAILABLE, unchanged.getStatus()
    );
}

@Test
void userCannotChangeStatusOfAnotherHospitalsBed() throws Exception {
    Room room99 = createRoom(99L, hospital99Ward, "ROOM-201");

    Bed bed = createBed(
            99L, room99, "BED-99", BedStatus.AVAILABLE
    );

    mvc.perform(patch("/api/v1/facilities/beds/" + bed.getId() + "/status")
                    .header("Authorization", hospital42Token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {
                              "status": "MAINTENANCE"
                            }
                            """))
            .andExpect(status().isNotFound());

    Bed unchanged = bedRepository.findById(bed.getId()).orElseThrow();
    org.junit.jupiter.api.Assertions.assertEquals(
            BedStatus.AVAILABLE, unchanged.getStatus()
    );
}



    @Test
    void invalidBedRequestReturnsBadRequest() throws Exception {
        mvc.perform(post("/api/v1/facilities/beds")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": null,
                                  "bedNo": "",
                                  "bedType": "",
                                  "dailyTariffPaise": -100
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void duplicateBedNumberInSameRoomReturnsConflict() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        createBed(
                42L,
                room,
                "BED-01",
                BedStatus.AVAILABLE
        );

        mvc.perform(post("/api/v1/facilities/beds")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": %d,
                                  "bedNo": "BED-01",
                                  "bedType": "General",
                                  "dailyTariffPaise": 150000
                                }
                                """.formatted(room.getId())))
                .andExpect(status().isConflict());
    }

    @Test
    void invalidRoomReturnsNotFound() throws Exception {
        mvc.perform(post("/api/v1/facilities/beds")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": 99999,
                                  "bedNo": "BED-01",
                                  "bedType": "General",
                                  "dailyTariffPaise": 150000
                                }
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void userCannotCreateBedInAnotherHospitalsRoom() throws Exception {
        Room room = createRoom(
                99L,
                hospital99Ward,
                "ROOM-201"
        );

        mvc.perform(post("/api/v1/facilities/beds")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "roomId": %d,
                                  "bedNo": "BED-01",
                                  "bedType": "General",
                                  "dailyTariffPaise": 150000
                                }
                                """.formatted(room.getId())))
                .andExpect(status().isNotFound());
    }

    @Test
    void nonexistentBedReturnsNotFound() throws Exception {
        mvc.perform(get("/api/v1/facilities/beds/99999")
                        .header("Authorization", hospital42Token))
                .andExpect(status().isNotFound());
    }

    private String createToken(String username, Long hospitalId) {
        AuthAccount account = accounts.findByUsername(username)
                .orElseThrow();

        Instant now = Instant.now();

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("caresync")
                .audience(List.of("caresync-api"))
                .subject(username)
                .issuedAt(now)
                .expiresAt(now.plusSeconds(300))
                .claim("uid", account.getId())
                .claim("name", account.getFullName())
                .claim("role", account.getRole())
                .claim("ver", account.getTokenVersion())
                .claim("hospitalId", hospitalId)
                .build();

        return "Bearer " + jwtEncoder.encode(
                JwtEncoderParameters.from(
                        JwsHeader.with(MacAlgorithm.HS256)
                                .type("JWT")
                                .build(),
                        claims
                )
        ).getTokenValue();
    }
}
