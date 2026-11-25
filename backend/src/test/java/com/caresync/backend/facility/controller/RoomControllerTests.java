
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

import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.repository.RoomRepository;
import com.caresync.backend.facility.repository.WardRepository;
import com.caresync.backend.security.AuthAccount;
import com.caresync.backend.security.AuthAccountRepository;

@SpringBootTest(properties = {
        "caresync.security.jwt-secret=local-test-secret-change-before-deployment-123456789",
        "spring.datasource.url=jdbc:h2:mem:caresync-room-api-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
@AutoConfigureMockMvc
class RoomControllerTests {

    @Autowired
    private MockMvc mvc;

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

    @Test
    void anonymousUserCannotAccessRooms() throws Exception {
        mvc.perform(get("/api/v1/facilities/rooms"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedUserCanCreateRoom() throws Exception {
        mvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "wardId": %d,
                                  "roomNumber": "ROOM-101",
                                  "roomType": "General",
                                  "floor": "First Floor",
                                  "description": "General patient room"
                                }
                                """.formatted(hospital42Ward.getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.roomNumber").value("ROOM-101"))
                .andExpect(jsonPath("$.roomType").value("General"))
                .andExpect(jsonPath("$.active").value(true))
                .andExpect(jsonPath("$.uuid").exists());
    }

    @Test
    void userCanOnlySeeRoomsBelongingToTheirHospital() throws Exception {
        createRoom(42L, hospital42Ward, "ROOM-101");
        createRoom(99L, hospital99Ward, "ROOM-201");

        mvc.perform(get("/api/v1/facilities/rooms")
                        .header("Authorization", hospital42Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].roomNumber").value("ROOM-101"));
    }

    @Test
    void userCanFilterRoomsByWard() throws Exception {
        createRoom(42L, hospital42Ward, "ROOM-101");
        createRoom(42L, hospital42Ward, "ROOM-102");

        mvc.perform(get("/api/v1/facilities/rooms")
                        .param("wardId", hospital42Ward.getId().toString())
                        .header("Authorization", hospital42Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));
    }

    @Test
    void userCannotAccessAnotherHospitalsRoom() throws Exception {
        Room room = createRoom(
                99L,
                hospital99Ward,
                "ROOM-201"
        );

        mvc.perform(get("/api/v1/facilities/rooms/" + room.getId())
                        .header("Authorization", hospital42Token))
                .andExpect(status().isNotFound());
    }

    @Test
    void authenticatedUserCanUpdateRoom() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        mvc.perform(put("/api/v1/facilities/rooms/" + room.getId())
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "wardId": %d,
                                  "roomNumber": "ROOM-102",
                                  "roomType": "Private",
                                  "floor": "Second Floor",
                                  "description": "Updated room"
                                }
                                """.formatted(hospital42Ward.getId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.roomNumber").value("ROOM-102"))
                .andExpect(jsonPath("$.roomType").value("Private"))
                .andExpect(jsonPath("$.floor").value("Second Floor"));
    }

    @Test
    void authenticatedUserCanDeactivateRoom() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        mvc.perform(patch(
                        "/api/v1/facilities/rooms/" + room.getId() + "/status"
                )
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "active": false
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(false));
    }

    @Test
    void authenticatedUserCanActivateRoom() throws Exception {
        Room room = createRoom(
                42L,
                hospital42Ward,
                "ROOM-101"
        );

        room.setActive(false);
        roomRepository.saveAndFlush(room);

        mvc.perform(patch(
                        "/api/v1/facilities/rooms/" + room.getId() + "/status"
                )
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "active": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(true));
    }


@Test
void userCannotUpdateAnotherHospitalsRoom() throws Exception {
    Room room = createRoom(99L, hospital99Ward, "ROOM-201");

    mvc.perform(put("/api/v1/facilities/rooms/" + room.getId())
                    .header("Authorization", hospital42Token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {
                              "wardId": %d,
                              "roomNumber": "ROOM-MOD",
                              "roomType": "Private",
                              "floor": "Second Floor",
                              "description": "Unauthorized modification"
                            }
                            """.formatted(hospital42Ward.getId())))
            .andExpect(status().isNotFound());

    Room unchanged = roomRepository.findById(room.getId()).orElseThrow();
    org.junit.jupiter.api.Assertions.assertEquals("ROOM-201", unchanged.getRoomNumber());
}

@Test
void userCannotChangeStatusOfAnotherHospitalsRoom() throws Exception {
    Room room = createRoom(99L, hospital99Ward, "ROOM-201");

    mvc.perform(patch("/api/v1/facilities/rooms/" + room.getId() + "/status")
                    .header("Authorization", hospital42Token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("""
                            {
                              "active": false
                            }
                            """))
            .andExpect(status().isNotFound());

    Room unchanged = roomRepository.findById(room.getId()).orElseThrow();
    org.junit.jupiter.api.Assertions.assertTrue(unchanged.isActive());
}


    @Test
    void invalidRoomRequestReturnsBadRequest() throws Exception {
        mvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "wardId": null,
                                  "roomNumber": "",
                                  "roomType": "",
                                  "floor": "First Floor",
                                  "description": "Invalid room"
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void duplicateRoomNumberInSameWardReturnsConflict() throws Exception {
        createRoom(42L, hospital42Ward, "ROOM-101");

        mvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "wardId": %d,
                                  "roomNumber": "ROOM-101",
                                  "roomType": "General",
                                  "floor": "First Floor",
                                  "description": "Duplicate room"
                                }
                                """.formatted(hospital42Ward.getId())))
                .andExpect(status().isConflict());
    }

    @Test
    void invalidWardReturnsNotFound() throws Exception {
        mvc.perform(post("/api/v1/facilities/rooms")
                        .header("Authorization", hospital42Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "wardId": 99999,
                                  "roomNumber": "ROOM-101",
                                  "roomType": "General",
                                  "floor": "First Floor",
                                  "description": "Invalid ward"
                                }
                                """))
                .andExpect(status().isNotFound());
    }

    @Test
    void nonexistentRoomReturnsNotFound() throws Exception {
        mvc.perform(get("/api/v1/facilities/rooms/99999")
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
