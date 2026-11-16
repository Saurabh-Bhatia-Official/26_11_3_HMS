package com.caresync.backend.patient.service;

import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.patient.dto.PatientDtos;
import com.caresync.backend.patient.entity.PatientRecord;
import com.caresync.backend.patient.repository.PatientRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@Transactional
public class PatientService {
    private final AccessContext access;
    private final PatientRepository patients;

    public PatientService(AccessContext access, PatientRepository patients) {
        this.access = access;
        this.patients = patients;
    }

    public PatientDtos.Response create(PatientDtos.CreateRequest request) {
        long hospitalId = access.hospitalId();
        String uuid;
        try {
            uuid = UUID.fromString(request.uuid()).toString();
        } catch (IllegalArgumentException invalidUuid) {
            throw BusinessException.invalid("Patient UUID is invalid");
        }

        var existing = patients.findByUuidAndHospitalIdAndDeletedFalse(uuid, hospitalId);
        if (existing.isPresent()) {
            PatientRecord patient = existing.get();
            if (!patient.getUhid().equals(request.uhid().trim())
                    || !patient.getName().equals(request.name().trim())) {
                throw BusinessException.conflict("Patient UUID is already registered with different details");
            }
            return response(patient);
        }
        if (patients.existsByHospitalIdAndUhidAndDeletedFalse(hospitalId, request.uhid().trim())) {
            throw BusinessException.conflict("Patient UHID is already registered");
        }

        PatientRecord patient = new PatientRecord(hospitalId, uuid, request.uhid().trim(),
                request.name().trim());
        return response(patients.save(patient));
    }

    @Transactional(readOnly = true)
    public PatientDtos.Response getByUuid(String uuid) {
        PatientRecord patient = patients.findByUuidAndHospitalIdAndDeletedFalse(uuid, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Patient"));
        return response(patient);
    }

    private static PatientDtos.Response response(PatientRecord patient) {
        return new PatientDtos.Response(patient.getId(), patient.getUuid(), patient.getUhid(),
                patient.getName());
    }
}
