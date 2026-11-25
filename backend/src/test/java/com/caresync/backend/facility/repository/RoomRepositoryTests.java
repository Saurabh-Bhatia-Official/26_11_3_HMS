
package com.caresync.backend.facility.repository;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;

import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.entity.Ward;

@DataJpaTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:caresync-room-repository-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
class RoomRepositoryTests {

    @Autowired
    private RoomRepository roomRepository;

    @Autowired
    private WardRepository wardRepository;

    private Ward createWard(Long hospitalId, String name, String code) {
        return wardRepository.saveAndFlush(
                new Ward(hospitalId, name, code, null)
        );
    }

    private Room createRoom(
            Long hospitalId,
            Ward ward,
            String roomNumber
    ) {
        return new Room(
                hospitalId,
                ward,
                roomNumber,
                "General",
                "First Floor",
                "Test room"
        );
    }

    @Test
    void saveRoomSuccessfully() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");

        Room savedRoom = roomRepository.saveAndFlush(
                createRoom(1L, ward, "ROOM-101")
        );

        assertNotNull(savedRoom.getId());
        assertNotNull(savedRoom.getUuid());
        assertEquals("ROOM-101", savedRoom.getRoomNumber());
        assertEquals(1L, savedRoom.getHospitalId());
        assertEquals(ward.getId(), savedRoom.getWard().getId());
        assertTrue(savedRoom.isActive());
    }

    @Test
    void findAllRoomsByHospitalId() {
        Ward ward1 = createWard(1L, "General Ward", "GEN-01");
        Ward ward2 = createWard(1L, "ICU", "ICU-01");
        Ward ward3 = createWard(2L, "Private Ward", "PVT-01");

        roomRepository.saveAndFlush(
                createRoom(1L, ward1, "ROOM-101")
        );

        roomRepository.saveAndFlush(
                createRoom(1L, ward2, "ROOM-201")
        );

        roomRepository.saveAndFlush(
                createRoom(2L, ward3, "ROOM-301")
        );

        List<Room> rooms = roomRepository.findAllByHospitalId(1L);

        assertEquals(2, rooms.size());
    }

    @Test
    void findAllRoomsByHospitalIdAndWardId() {
        Ward ward1 = createWard(1L, "General Ward", "GEN-01");
        Ward ward2 = createWard(1L, "ICU", "ICU-01");

        roomRepository.saveAndFlush(
                createRoom(1L, ward1, "ROOM-101")
        );

        roomRepository.saveAndFlush(
                createRoom(1L, ward1, "ROOM-102")
        );

        roomRepository.saveAndFlush(
                createRoom(1L, ward2, "ROOM-201")
        );

        List<Room> rooms =
                roomRepository.findAllByHospitalIdAndWard_Id(
                        1L, ward1.getId()
                );

        assertEquals(2, rooms.size());
    }

    @Test
    void findRoomByIdAndHospitalId() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");

        Room savedRoom = roomRepository.saveAndFlush(
                createRoom(1L, ward, "ROOM-101")
        );

        Optional<Room> result =
                roomRepository.findByIdAndHospitalId(
                        savedRoom.getId(), 1L
                );

        assertTrue(result.isPresent());
        assertEquals("ROOM-101", result.get().getRoomNumber());
    }

    @Test
    void roomCannotBeFoundUnderDifferentHospital() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");

        Room savedRoom = roomRepository.saveAndFlush(
                createRoom(1L, ward, "ROOM-101")
        );

        Optional<Room> result =
                roomRepository.findByIdAndHospitalId(
                        savedRoom.getId(), 2L
                );

        assertTrue(result.isEmpty());
    }

    @Test
    void roomNumberMustBeUniqueWithinWard() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");

        roomRepository.saveAndFlush(
                createRoom(1L, ward, "ROOM-101")
        );

        assertTrue(
                roomRepository.existsByWard_IdAndRoomNumber(
                        ward.getId(), "ROOM-101"
                )
        );

        assertFalse(
                roomRepository.existsByWard_IdAndRoomNumber(
                        ward.getId(), "ROOM-102"
                )
        );
    }

    @Test
    void sameRoomNumberCanExistInDifferentWards() {
        Ward ward1 = createWard(1L, "General Ward", "GEN-01");
        Ward ward2 = createWard(1L, "ICU", "ICU-01");

        Room firstRoom = roomRepository.saveAndFlush(
                createRoom(1L, ward1, "ROOM-101")
        );

        Room secondRoom = roomRepository.saveAndFlush(
                createRoom(1L, ward2, "ROOM-101")
        );

        assertNotNull(firstRoom.getId());
        assertNotNull(secondRoom.getId());

        assertNotEquals(firstRoom.getWard().getId(),
                secondRoom.getWard().getId());
    }

    @Test
    void sameRoomNumberCanExistInDifferentHospitals() {
        Ward ward1 = createWard(1L, "General Ward", "GEN-01");
        Ward ward2 = createWard(2L, "General Ward", "GEN-01");

        Room firstRoom = roomRepository.saveAndFlush(
                createRoom(1L, ward1, "ROOM-101")
        );

        Room secondRoom = roomRepository.saveAndFlush(
                createRoom(2L, ward2, "ROOM-101")
        );

        assertNotNull(firstRoom.getId());
        assertNotNull(secondRoom.getId());
    }
}
