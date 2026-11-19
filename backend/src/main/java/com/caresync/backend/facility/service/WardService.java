
package com.caresync.backend.facility.service;

import com.caresync.backend.facility.dto.WardRequest;
import com.caresync.backend.facility.dto.WardResponse;
import com.caresync.backend.facility.entity.Ward;
import com.caresync.backend.facility.exception.WardAlreadyExistsException;
import com.caresync.backend.facility.exception.WardNotFoundException;
import com.caresync.backend.facility.repository.WardRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class WardService {

    private final WardRepository wardRepository;

    public WardService(WardRepository wardRepository) {
        this.wardRepository = wardRepository;
    }

    public WardResponse createWard(Long hospitalId, WardRequest request) {
        validateHospitalId(hospitalId);

        String wardCode = normalizeWardCode(request.wardCode());

        if (wardRepository.existsByHospitalIdAndWardCode(hospitalId, wardCode)) {
            throw new WardAlreadyExistsException(
                    "A ward with code " + wardCode + " already exists"
            );
        }

        String name = request.name().trim();

                if (wardRepository.existsByHospitalIdAndName(hospitalId, name)) {
                    throw new WardAlreadyExistsException(
                            "A ward with name " + name + " already exists"
                    );
                }

                Ward ward = new Ward(
                        hospitalId,
                        name,
                        wardCode,
                        normalizeDescription(request.description())
                );

        return toResponse(wardRepository.save(ward));
    }

    @Transactional(readOnly = true)
    public List<WardResponse> getAllWards(Long hospitalId) {
        validateHospitalId(hospitalId);

        return wardRepository.findAllByHospitalId(hospitalId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public WardResponse getWardById(Long hospitalId, Long wardId) {
        return toResponse(findWard(hospitalId, wardId));
    }

    public WardResponse updateWard(
            Long hospitalId,
            Long wardId,
            WardRequest request
    ) {
        validateHospitalId(hospitalId);

        Ward ward = findWard(hospitalId, wardId);
        String wardCode = normalizeWardCode(request.wardCode());

        if (wardRepository.existsByHospitalIdAndWardCodeAndIdNot(
                hospitalId, wardCode, wardId
        )) {
            throw new WardAlreadyExistsException(
                    "A ward with code " + wardCode + " already exists"
            );
        }

        String name = request.name().trim();

            if (wardRepository.existsByHospitalIdAndNameAndIdNot(
                    hospitalId, name, wardId
            )) {
                throw new WardAlreadyExistsException(
                        "A ward with name " + name + " already exists"
                );
            }

            ward.updateDetails(
                    name,
                    wardCode,
                    normalizeDescription(request.description())
            );

        return toResponse(wardRepository.save(ward));
    }

    public WardResponse updateWardStatus(
            Long hospitalId,
            Long wardId,
            boolean active
    ) {
        Ward ward = findWard(hospitalId, wardId);
        ward.setActive(active);

        return toResponse(wardRepository.save(ward));
    }

    private Ward findWard(Long hospitalId, Long wardId) {
        validateHospitalId(hospitalId);

        return wardRepository.findByIdAndHospitalId(wardId, hospitalId)
                .orElseThrow(() ->
                        new WardNotFoundException(
                                "Ward not found with ID: " + wardId
                        )
                );
    }

    private void validateHospitalId(Long hospitalId) {
        if (hospitalId == null) {
            throw new IllegalStateException(
                    "No hospital is associated with the authenticated user"
            );
        }
    }

    private String normalizeWardCode(String wardCode) {
        return wardCode.trim().toUpperCase();
    }

    private String normalizeDescription(String description) {
        if (description == null || description.isBlank()) {
            return null;
        }

        return description.trim();
    }

    private WardResponse toResponse(Ward ward) {
        return new WardResponse(
                ward.getId(),
                ward.getUuid(),
                ward.getName(),
                ward.getWardCode(),
                ward.getDescription(),
                ward.isActive(),
                ward.getCreatedAt(),
                ward.getUpdatedAt()
        );
    }
}
