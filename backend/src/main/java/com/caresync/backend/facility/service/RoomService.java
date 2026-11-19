
package com.caresync.backend.facility.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.caresync.backend.facility.dto.RoomRequest;
import com.caresync.backend.facility.dto.RoomResponse;
import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.exception.RoomAlreadyExistsException;
import com.caresync.backend.facility.exception.RoomNotFoundException;
import com.caresync.backend.facility.exception.WardNotFoundException;
import com.caresync.backend.facility.repository.RoomRepository;
import com.caresync.backend.facility.repository.WardRepository;

@Service
@Transactional
public class RoomService {

    private final RoomRepository roomRepository;
    private final WardRepository wardRepository;

    public RoomService(
            RoomRepository roomRepository,
            WardRepository wardRepository
    ) {
        this.roomRepository = roomRepository;
        this.wardRepository = wardRepository;
    }

    public RoomResponse createRoom(Long hospitalId, RoomRequest request) {
        validateHospitalId(hospitalId);

        Ward ward = findWard(hospitalId, request.wardId());

        String roomNumber = normalizeRoomNumber(request.roomNumber());

        validateDuplicateRoomNumber(ward.getId(), roomNumber);

        Room room = new Room(
                hospitalId,
                ward,
                roomNumber,
                normalizeRoomType(request.roomType()),
                normalizeOptionalValue(request.floor()),
                normalizeDescription(request.description())
        );

        return toResponse(roomRepository.save(room));
    }

    @Transactional(readOnly = true)
    public List<RoomResponse> getAllRooms(Long hospitalId, Long wardId) {
        validateHospitalId(hospitalId);

        List<Room> rooms;

        if (wardId == null) {
            rooms = roomRepository.findAllByHospitalId(hospitalId);
        } else {
            findWard(hospitalId, wardId);
            rooms = roomRepository.findAllByHospitalIdAndWard_Id(
                    hospitalId,
                    wardId
            );
        }

        return rooms.stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public RoomResponse getRoomById(Long hospitalId, Long roomId) {
        validateHospitalId(hospitalId);

        return toResponse(findRoom(hospitalId, roomId));
    }

    public RoomResponse updateRoom(
            Long hospitalId,
            Long roomId,
            RoomRequest request
    ) {
        validateHospitalId(hospitalId);

        Room room = findRoom(hospitalId, roomId);

        Ward ward = findWard(hospitalId, request.wardId());

        String roomNumber = normalizeRoomNumber(request.roomNumber());

        validateDuplicateRoomNumber(
                ward.getId(),
                roomNumber,
                roomId
        );

        room.updateDetails(
                ward,
                roomNumber,
                normalizeRoomType(request.roomType()),
                normalizeOptionalValue(request.floor()),
                normalizeDescription(request.description())
        );

        return toResponse(roomRepository.save(room));
    }

    public RoomResponse updateRoomStatus(
            Long hospitalId,
            Long roomId,
            boolean active
    ) {
        validateHospitalId(hospitalId);

        Room room = findRoom(hospitalId, roomId);

        room.setActive(active);

        return toResponse(roomRepository.save(room));
    }

    private Ward findWard(Long hospitalId, Long wardId) {
        return wardRepository.findByIdAndHospitalId(wardId, hospitalId)
                .orElseThrow(() ->
                        new WardNotFoundException(
                                "Ward not found with ID: " + wardId
                        )
                );
    }

    private Room findRoom(Long hospitalId, Long roomId) {
        return roomRepository.findByIdAndHospitalId(roomId, hospitalId)
                .orElseThrow(() ->
                        new RoomNotFoundException(roomId)
                );
    }

    private void validateDuplicateRoomNumber(
            Long wardId,
            String roomNumber
    ) {
        if (roomRepository.existsByWard_IdAndRoomNumber(
                wardId,
                roomNumber
        )) {
            throw new RoomAlreadyExistsException(roomNumber, wardId);
        }
    }

    private void validateDuplicateRoomNumber(
            Long wardId,
            String roomNumber,
            Long excludeRoomId
    ) {
        if (roomRepository.existsByWard_IdAndRoomNumberAndIdNot(
                wardId,
                roomNumber,
                excludeRoomId
        )) {
            throw new RoomAlreadyExistsException(roomNumber, wardId);
        }
    }

    private void validateHospitalId(Long hospitalId) {
        if (hospitalId == null) {
            throw new IllegalStateException(
                    "No hospital is associated with the authenticated user"
            );
        }
    }

    private String normalizeRoomNumber(String roomNumber) {
        return roomNumber.trim().toUpperCase();
    }

    private String normalizeRoomType(String roomType) {
        return roomType.trim();
    }

    private String normalizeOptionalValue(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return value.trim();
    }

    private String normalizeDescription(String description) {
        if (description == null || description.isBlank()) {
            return null;
        }

        return description.trim();
    }

    private RoomResponse toResponse(Room room) {
        return new RoomResponse(
                room.getId(),
                room.getUuid(),
                room.getWard().getId(),
                room.getRoomNumber(),
                room.getRoomType(),
                room.getFloor(),
                room.getDescription(),
                room.isActive(),
                room.getCreatedAt(),
                room.getUpdatedAt()
        );
    }
}
