package com.caresync.backend.facility.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.caresync.backend.facility.dto.BedRequest;
import com.caresync.backend.facility.dto.BedResponse;
import com.caresync.backend.facility.entity.Bed;
import com.caresync.backend.facility.entity.BedStatus;
import com.caresync.backend.facility.entity.Room;
import com.caresync.backend.facility.exception.BedAlreadyExistsException;
import com.caresync.backend.facility.exception.BedNotFoundException;
import com.caresync.backend.facility.exception.RoomNotFoundException;
import com.caresync.backend.facility.repository.BedRepository;
import com.caresync.backend.facility.repository.RoomRepository;

@Service
@Transactional
public class BedService {

    private final BedRepository bedRepository;
    private final RoomRepository roomRepository;

    public BedService(
            BedRepository bedRepository,
            RoomRepository roomRepository
    ) {
        this.bedRepository = bedRepository;
        this.roomRepository = roomRepository;
    }

    public BedResponse createBed(Long hospitalId, BedRequest request) {
        validateHospitalId(hospitalId);

        Room room = findRoom(hospitalId, request.roomId());
        String bedNo = normalizeBedNo(request.bedNo());

        validateDuplicateBed(room.getId(), bedNo);

        Bed bed = new Bed(
                hospitalId,
                room,
                bedNo,
                normalizeBedType(request.bedType()),
                request.dailyTariffPaise(),
                request.status() != null
                        ? request.status()
                        : BedStatus.AVAILABLE
        );

        return toResponse(bedRepository.save(bed));
    }

    @Transactional(readOnly = true)
    public List<BedResponse> getAllBeds(
            Long hospitalId,
            Long wardId,
            Long roomId,
            BedStatus status
    ) {
        validateHospitalId(hospitalId);

        if (roomId != null) {
            findRoom(hospitalId, roomId);
        }

        return bedRepository.findBeds(
                        hospitalId, roomId, wardId, status
                )
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public BedResponse getBedById(Long hospitalId, Long bedId) {
        validateHospitalId(hospitalId);
        return toResponse(findBed(hospitalId, bedId));
    }

    public BedResponse updateBed(
            Long hospitalId,
            Long bedId,
            BedRequest request
    ) {
        validateHospitalId(hospitalId);

        Bed bed = findBed(hospitalId, bedId);
        Room room = findRoom(hospitalId, request.roomId());
        String bedNo = normalizeBedNo(request.bedNo());

        validateDuplicateBed(room.getId(), bedNo, bedId);

        bed.updateDetails(
                room,
                bedNo,
                normalizeBedType(request.bedType()),
                request.dailyTariffPaise()
        );

        return toResponse(bedRepository.save(bed));
    }

    public BedResponse updateBedStatus(
            Long hospitalId,
            Long bedId,
            BedStatus status
    ) {
        validateHospitalId(hospitalId);

        Bed bed = findBed(hospitalId, bedId);
        bed.setStatus(status);

        return toResponse(bedRepository.save(bed));
    }

    private Bed findBed(Long hospitalId, Long bedId) {
        return bedRepository.findByIdAndHospitalId(bedId, hospitalId)
                .orElseThrow(() -> new BedNotFoundException(bedId));
    }

    private Room findRoom(Long hospitalId, Long roomId) {
        return roomRepository.findByIdAndHospitalId(roomId, hospitalId)
                .orElseThrow(() -> new RoomNotFoundException(roomId));
    }

    private void validateDuplicateBed(Long roomId, String bedNo) {
        if (bedRepository.existsByRoom_IdAndBedNo(roomId, bedNo)) {
            throw new BedAlreadyExistsException(bedNo);
        }
    }

    private void validateDuplicateBed(
            Long roomId,
            String bedNo,
            Long excludeBedId
    ) {
        if (bedRepository.existsByRoom_IdAndBedNoAndIdNot(
                roomId, bedNo, excludeBedId
        )) {
            throw new BedAlreadyExistsException(bedNo);
        }
    }

    private void validateHospitalId(Long hospitalId) {
        if (hospitalId == null) {
            throw new IllegalStateException(
                    "No hospital is associated with the authenticated user"
            );
        }
    }

    private String normalizeBedNo(String bedNo) {
        return bedNo.trim().toUpperCase();
    }

    private String normalizeBedType(String bedType) {
        return bedType.trim();
    }

    private BedResponse toResponse(Bed bed) {
        Room room = bed.getRoom();

        return new BedResponse(
                bed.getId(),
                bed.getUuid(),
                room.getId(),
                room.getRoomNumber(),
                room.getWard().getId(),
                room.getWard().getName(),
                bed.getBedNo(),
                bed.getBedType(),
                bed.getDailyTariffPaise(),
                bed.getStatus(),
                bed.getCreatedAt(),
                bed.getUpdatedAt()
        );
    }
}