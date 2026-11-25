package com.caresync.backend.facility.service;

import java.lang.reflect.Field;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
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

import com.caresync.backend.facility.dto.BedRequest;
import com.caresync.backend.facility.dto.BedResponse;
import com.caresync.backend.facility.entity.Bed;
import com.caresync.backend.facility.entity.BedStatus;
import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.exception.BedAlreadyExistsException;
import com.caresync.backend.facility.exception.BedNotFoundException;
import com.caresync.backend.facility.exception.RoomNotFoundException;
import com.caresync.backend.facility.repository.BedRepository;
import com.caresync.backend.facility.repository.RoomRepository;

@ExtendWith(MockitoExtension.class)
class BedServiceTests {

    @Mock
    private BedRepository bedRepository;

    @Mock
    private RoomRepository roomRepository;

    @InjectMocks
    private BedService bedService;

    private void setId(Object entity, Long id) {
        try {
            Field idField = entity.getClass().getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(entity, id);
        } catch (ReflectiveOperationException exception) {
            throw new RuntimeException(exception);
        }
    }

    private Ward createSampleWard(Long hospitalId) {
        Ward ward = new Ward(
                hospitalId,
                "General Ward",
                "GEN-01",
                "Test ward"
        );

        setId(ward, 10L);
        return ward;
    }

    private Room createSampleRoom(Long hospitalId, Ward ward) {
        Room room = new Room(
                hospitalId,
                ward,
                "ROOM-101",
                "General",
                "First Floor",
                "Test room"
        );

        setId(room, 20L);
        return room;
    }

    private Bed createSampleBed(Long hospitalId, Room room) {
        Bed bed = new Bed(
                hospitalId,
                room,
                "BED-01",
                "General",
                50000,
                BedStatus.AVAILABLE
        );

        setId(bed, 30L);
        return bed;
    }

    private BedRequest sampleRequest() {
        return new BedRequest(
                20L,
                " bed-01 ",
                " General ",
                50000,
                null
        );
    }

    @Test
    void createBedSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);

        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.of(room));

        when(bedRepository.existsByRoom_IdAndBedNo(
                20L, "BED-01"
        )).thenReturn(false);

        when(bedRepository.save(any(Bed.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        BedResponse response = bedService.createBed(
                1L, sampleRequest()
        );

        assertEquals("BED-01", response.bedNo());
        assertEquals("General", response.bedType());
        assertEquals(20L, response.roomId());
        assertEquals(BedStatus.AVAILABLE, response.status());

        verify(bedRepository).save(any(Bed.class));
    }

    @Test
    void createBedRejectsDuplicateBedNumber() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);

        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.of(room));

        when(bedRepository.existsByRoom_IdAndBedNo(
                20L, "BED-01"
        )).thenReturn(true);

        assertThrows(
                BedAlreadyExistsException.class,
                () -> bedService.createBed(1L, sampleRequest())
        );

        verify(bedRepository, never()).save(any(Bed.class));
    }

    @Test
    void createBedRejectsRoomFromDifferentHospital() {
        when(roomRepository.findByIdAndHospitalId(20L, 1L))
                .thenReturn(Optional.empty());

        assertThrows(
                RoomNotFoundException.class,
                () -> bedService.createBed(1L, sampleRequest())
        );

        verify(bedRepository, never()).save(any(Bed.class));
    }

    @Test
    void getAllBedsSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);

        when(bedRepository.findBeds(1L, null, null, null))
                .thenReturn(List.of(createSampleBed(1L, room)));

        List<BedResponse> responses = bedService.getAllBeds(
                1L, null, null, null
        );

        assertEquals(1, responses.size());
        assertEquals("BED-01", responses.get(0).bedNo());
    }

@Test
void getAllBedsSupportsFilters() {
    Ward ward = createSampleWard(1L);
    Room room = createSampleRoom(20L, ward);

    when(roomRepository.findByIdAndHospitalId(20L, 1L))
            .thenReturn(Optional.of(room));

    when(bedRepository.findBeds(
            1L, 20L, 10L, BedStatus.CLEANING
    )).thenReturn(List.of());

    List<BedResponse> responses = bedService.getAllBeds(
            1L, 10L, 20L, BedStatus.CLEANING
    );

    assertTrue(responses.isEmpty());

    verify(roomRepository).findByIdAndHospitalId(20L, 1L);
    verify(bedRepository).findBeds(
            1L, 20L, 10L, BedStatus.CLEANING
    );
}
    @Test
    void getBedByIdSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);
        Bed bed = createSampleBed(1L, room);

        when(bedRepository.findByIdAndHospitalId(30L, 1L))
                .thenReturn(Optional.of(bed));

        BedResponse response = bedService.getBedById(1L, 30L);

        assertEquals("BED-01", response.bedNo());
        assertEquals(30L, response.id());
    }

    @Test
    void getBedByIdRejectsDifferentHospital() {
        when(bedRepository.findByIdAndHospitalId(30L, 2L))
                .thenReturn(Optional.empty());

        assertThrows(
                BedNotFoundException.class,
                () -> bedService.getBedById(2L, 30L)
        );
    }

    @Test
    void updateBedStatusSuccessfully() {
        Ward ward = createSampleWard(1L);
        Room room = createSampleRoom(1L, ward);
        Bed bed = createSampleBed(1L, room);

        when(bedRepository.findByIdAndHospitalId(30L, 1L))
                .thenReturn(Optional.of(bed));

        when(bedRepository.save(any(Bed.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        BedResponse response = bedService.updateBedStatus(
                1L, 30L, BedStatus.CLEANING
        );

        assertEquals(BedStatus.CLEANING, response.status());
    }

    @Test
    void rejectRequestWhenHospitalIdIsNull() {
        assertThrows(
                IllegalStateException.class,
                () -> bedService.getAllBeds(null, null, null, null)
        );

        verifyNoInteractions(bedRepository, roomRepository);
    }
}