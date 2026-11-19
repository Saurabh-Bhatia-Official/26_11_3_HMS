package com.caresync.backend.facility.repository;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;

import com.caresync.backend.facility.entity.Bed;
import com.caresync.backend.facility.entity.BedStatus;
import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.entity.Ward;

@DataJpaTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:caresync-bed-repository-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE"
})
class BedRepositoryTests {

    @Autowired
    private BedRepository bedRepository;

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
                        50000,
                        status
                )
        );
    }

    @Test
    void saveBedSuccessfully() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");
        Room room = createRoom(1L, ward, "ROOM-101");

        Bed savedBed = createBed(
                1L, room, "BED-01", BedStatus.AVAILABLE
        );

        assertNotNull(savedBed.getId());
        assertNotNull(savedBed.getUuid());
        assertEquals("BED-01", savedBed.getBedNo());
        assertEquals(1L, savedBed.getHospitalId());
        assertEquals(room.getId(), savedBed.getRoom().getId());
        assertEquals(BedStatus.AVAILABLE, savedBed.getStatus());
    }

    @Test
    void findBedsByHospitalId() {
        Ward ward1 = createWard(1L, "General Ward", "GEN-01");
        Ward ward2 = createWard(2L, "Private Ward", "PVT-01");

        Room room1 = createRoom(1L, ward1, "ROOM-101");
        Room room2 = createRoom(2L, ward2, "ROOM-201");

        createBed(1L, room1, "BED-01", BedStatus.AVAILABLE);
        createBed(2L, room2, "BED-02", BedStatus.AVAILABLE);

        List<Bed> beds = bedRepository.findBeds(
                1L, null, null, null
        );

        assertEquals(1, beds.size());
        assertEquals("BED-01", beds.get(0).getBedNo());
    }

    @Test
    void findBedsByRoomId() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");

        Room room1 = createRoom(1L, ward, "ROOM-101");
        Room room2 = createRoom(1L, ward, "ROOM-102");

        createBed(1L, room1, "BED-01", BedStatus.AVAILABLE);
        createBed(1L, room2, "BED-02", BedStatus.AVAILABLE);

        List<Bed> beds = bedRepository.findBeds(
                1L, room1.getId(), null, null
        );

        assertEquals(1, beds.size());
        assertEquals("BED-01", beds.get(0).getBedNo());
    }

    @Test
    void findBedsByWardId() {
        Ward ward1 = createWard(1L, "General Ward", "GEN-01");
        Ward ward2 = createWard(1L, "ICU", "ICU-01");

        Room room1 = createRoom(1L, ward1, "ROOM-101");
        Room room2 = createRoom(1L, ward2, "ROOM-201");

        createBed(1L, room1, "BED-01", BedStatus.AVAILABLE);
        createBed(1L, room2, "BED-02", BedStatus.AVAILABLE);

        List<Bed> beds = bedRepository.findBeds(
                1L, null, ward1.getId(), null
        );

        assertEquals(1, beds.size());
        assertEquals("BED-01", beds.get(0).getBedNo());
    }

    @Test
    void findBedsByStatus() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");
        Room room = createRoom(1L, ward, "ROOM-101");

        createBed(1L, room, "BED-01", BedStatus.AVAILABLE);
        createBed(1L, room, "BED-02", BedStatus.CLEANING);
        createBed(1L, room, "BED-03", BedStatus.MAINTENANCE);

        List<Bed> beds = bedRepository.findBeds(
                1L, null, null, BedStatus.CLEANING
        );

        assertEquals(1, beds.size());
        assertEquals("BED-02", beds.get(0).getBedNo());
    }

    @Test
    void findBedByIdAndHospitalId() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");
        Room room = createRoom(1L, ward, "ROOM-101");

        Bed savedBed = createBed(
                1L, room, "BED-01", BedStatus.AVAILABLE
        );

        Optional<Bed> result = bedRepository.findByIdAndHospitalId(
                savedBed.getId(), 1L
        );

        assertTrue(result.isPresent());
        assertEquals("BED-01", result.get().getBedNo());
    }

    @Test
    void bedCannotBeFoundUnderDifferentHospital() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");
        Room room = createRoom(1L, ward, "ROOM-101");

        Bed savedBed = createBed(
                1L, room, "BED-01", BedStatus.AVAILABLE
        );

        Optional<Bed> result = bedRepository.findByIdAndHospitalId(
                savedBed.getId(), 2L
        );

        assertTrue(result.isEmpty());
    }

    @Test
    void bedNumberMustBeUniqueWithinRoom() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");
        Room room = createRoom(1L, ward, "ROOM-101");

        createBed(1L, room, "BED-01", BedStatus.AVAILABLE);

        assertTrue(
                bedRepository.existsByRoom_IdAndBedNo(
                        room.getId(), "BED-01"
                )
        );

        assertFalse(
                bedRepository.existsByRoom_IdAndBedNo(
                        room.getId(), "BED-02"
                )
        );
    }

    @Test
    void sameBedNumberCanExistInDifferentRooms() {
        Ward ward = createWard(1L, "General Ward", "GEN-01");

        Room room1 = createRoom(1L, ward, "ROOM-101");
        Room room2 = createRoom(1L, ward, "ROOM-102");

        Bed firstBed = createBed(
                1L, room1, "BED-01", BedStatus.AVAILABLE
        );

        Bed secondBed = createBed(
                1L, room2, "BED-01", BedStatus.AVAILABLE
        );

        assertNotNull(firstBed.getId());
        assertNotNull(secondBed.getId());
        assertFalse(firstBed.getRoom().getId()
                .equals(secondBed.getRoom().getId()));
    }
}