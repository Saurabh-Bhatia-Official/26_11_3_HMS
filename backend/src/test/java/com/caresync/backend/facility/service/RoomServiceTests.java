
package com.caresync.backend.facility.service;

import java.lang.reflect.Field;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import static org.mockito.ArgumentMatchers.any;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;

import com.caresync.backend.facility.dto.RoomRequest;
import com.caresync.backend.facility.dto.RoomResponse;
import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.exception.RoomAlreadyExistsException;
import com.caresync.backend.facility.exception.RoomNotFoundException;
import com.caresync.backend.facility.exception.WardNotFoundException;
import com.caresync.backend.facility.repository.RoomRepository;
import com.caresync.backend.facility.repository.WardRepository;

@ExtendWith(MockitoExtension.class)
class RoomServiceTests {

    @Mock
    private RoomRepository roomRepository;

    @Mock
    private WardRepository wardRepository;

    @InjectMocks
    private RoomService roomService;

    private Ward createSampleWard(Long hospitalId) {
        Ward ward = new Ward(
                hospitalId,
                "General Ward",
                "GEN-01",
                "General patient ward"
        );

        try {
            Field idField = Ward.class.getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(ward, 10L);
        } catch (ReflectiveOperationException exception) {
            throw new RuntimeException(exception);
        }

        return ward;
    }

    private Room createSampleRoom(Long hospitalId, Ward ward) {
        return new Room(
                hospitalId,
                ward,
                "ROOM-101",
                "General",
                "First Floor",
                "General patient room"
        );
    }

    @Test
    void createRoomSuccessfully() {
        Ward ward = createSampleWard(1L);

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(roomRepository.existsByWard_IdAndRoomNumber(
                10L, "ROOM-101"
        )).thenReturn(false);

        when(roomRepository.save(any(Room.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        RoomResponse response = roomService.createRoom(
                1L,
                new RoomRequest(
                        10L,
                        " room-101 ",
                        " General ",
                        "First Floor",
                        "General patient room"
                )
        );

        assertEquals("ROOM-101", response.roomNumber());
        assertEquals("General", response.roomType());
        assertTrue(response.active());

        verify(roomRepository).save(any(Room.class));
    }

    @Test
    void createRoomRejectsDuplicateRoomNumber() {
        Ward ward = createSampleWard(1L);

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(roomRepository.existsByWard_IdAndRoomNumber(
                10L, "ROOM-101"
        )).thenReturn(true);

        assertThrows(
                RoomAlreadyExistsException.class,
                () -> roomService.createRoom(
                        1L,
                        new RoomRequest(
                                10L,
                                "ROOM-101",
                                "General",
                                null,
                                null
                        )
                )
        );

        verify(roomRepository, never()).save(any(Room.class));
    }

    @Test
    void getAllRoomsSuccessfully() {
        Ward ward = createSampleWard(1L);

        when(roomRepository.findAllByHospitalId(1L))
                .thenReturn(List.of(createSampleRoom(1L, ward)));

        List<RoomResponse> responses =
                roomService.getAllRooms(1L, null);

        assertEquals(1, responses.size());
        assertEquals("ROOM-101", responses.get(0).roomNumber());
    }

    @Test
    void getAllRoomsFilteredByWard() {
        Ward ward = createSampleWard(1L);

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(roomRepository.findAllByHospitalIdAndWard_Id(1L, 10L))
                .thenReturn(List.of(createSampleRoom(1L, ward)));

        List<RoomResponse> responses =
                roomService.getAllRooms(1L, 10L);

        assertEquals(1, responses.size());
        assertEquals("ROOM-101", responses.get(0).roomNumber());

        verify(roomRepository)
                .findAllByHospitalIdAndWard_Id(1L, 10L);
    }

    @Test
    void getRoomByIdSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);

        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.of(room));

        RoomResponse response = roomService.getRoomById(1L, 20L);

        assertEquals("ROOM-101", response.roomNumber());
        assertEquals("General", response.roomType());
    }

    @Test
    void getRoomByIdRejectsDifferentHospital() {
        when(roomRepository.findByIdAndHospitalId(20L, 2L))
                .thenReturn(Optional.empty());

        assertThrows(
                RoomNotFoundException.class,
                () -> roomService.getRoomById(2L, 20L)
        );
    }

    @Test
    void updateRoomSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);

        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.of(room));

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(roomRepository.existsByWard_IdAndRoomNumberAndIdNot(
                10L, "ROOM-102", 20L
        )).thenReturn(false);

        when(roomRepository.save(any(Room.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        RoomResponse response = roomService.updateRoom(
                1L,
                20L,
                new RoomRequest(
                        10L,
                        "ROOM-102",
                        "Private",
                        "Second Floor",
                        "Updated room"
                )
        );

        assertEquals("ROOM-102", response.roomNumber());
        assertEquals("Private", response.roomType());
        assertEquals("Second Floor", response.floor());
    }

    @Test
    void updateRoomRejectsDuplicateRoomNumber() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);

        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.of(room));

        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.of(ward));

        when(roomRepository.existsByWard_IdAndRoomNumberAndIdNot(
                10L, "ROOM-102", 20L
        )).thenReturn(true);

        assertThrows(
                RoomAlreadyExistsException.class,
                () -> roomService.updateRoom(
                        1L,
                        20L,
                        new RoomRequest(
                                10L,
                                "ROOM-102",
                                "Private",
                                null,
                                null
                        )
                )
        );

        verify(roomRepository, never()).save(any(Room.class));
    }

    @Test
    void deactivateRoomSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);

        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.of(room));

        when(roomRepository.save(any(Room.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        RoomResponse response =
                roomService.updateRoomStatus(1L, 20L, false);

        assertFalse(response.active());
    }

    @Test
    void activateRoomSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);
        room.setActive(false);

        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.of(room));

        when(roomRepository.save(any(Room.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        RoomResponse response =
                roomService.updateRoomStatus(1L, 20L, true);

        assertTrue(response.active());
    }

    @Test
    void createRoomRejectsWardFromDifferentHospital() {
        when(wardRepository.findByIdAndHospitalId(10L, 1L))
                .thenReturn(Optional.empty());

        assertThrows(
                WardNotFoundException.class,
                () -> roomService.createRoom(
                        1L,
                        new RoomRequest(
                                10L,
                                "ROOM-101",
                                "General",
                                null,
                                null
                        )
                )
        );

        verify(roomRepository, never()).save(any(Room.class));
    }

    @Test
    void rejectRequestWhenHospitalIdIsNull() {
        assertThrows(
                IllegalStateException.class,
                () -> roomService.getAllRooms(null, null)
        );

        verifyNoInteractions(roomRepository, wardRepository);
    }
}
