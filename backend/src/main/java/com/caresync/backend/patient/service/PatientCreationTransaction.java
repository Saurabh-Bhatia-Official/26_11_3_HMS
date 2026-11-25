package com.caresync.backend.patient.service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.caresync.backend.hospital.entity.Hospital;
import com.caresync.backend.hospital.entity.HospitalStatus;
import com.caresync.backend.hospital.repository.HospitalRepository;
import com.caresync.backend.patient.dto.PatientCreateRequest;
import com.caresync.backend.patient.dto.PatientResponse;
import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.security.SecurityAuditEvent;
import com.caresync.backend.security.SecurityAuditEventRepository;

import jakarta.persistence.EntityManager;

/** Isolated transaction boundary so a UUID uniqueness race can be resolved after rollback. */
@Service
public class PatientCreationTransaction {
    private static final SecureRandom UHID_RANDOM = new SecureRandom();
    private final PatientRepository patients;
    private final HospitalRepository hospitals;
    private final EntityManager entityManager;
    private final SecurityAuditEventRepository auditEvents;

    public PatientCreationTransaction(PatientRepository patients, HospitalRepository hospitals,
                                     EntityManager entityManager, SecurityAuditEventRepository auditEvents) {
        this.patients = patients;
        this.hospitals = hospitals;
        this.entityManager = entityManager;
        this.auditEvents = auditEvents;
    }

    @Transactional
    public PatientResponse create(UUID hospitalUuid, long actorAccountId, PatientCreateRequest request) {
        Hospital hospital = hospitals.findById(hospitalUuid)
                .filter(item -> item.getStatus() == HospitalStatus.APPROVED)
                .orElseThrow(() -> new PatientApiException(HttpStatus.FORBIDDEN, "Hospital access is unavailable"));
        if (hospital.getHospitalId() == null) {
    throw new PatientApiException(
            HttpStatus.CONFLICT,
            "Approved hospital is missing its numeric hospital ID"
    );
}
        Patient existing = patients.findByUuid(request.uuid()).orElse(null);
        if (existing != null) {
            if (existing.getHospital().getId().equals(hospitalUuid) && existing.getArchivedAt() == null
                    && samePayload(existing, request)) {
                return PatientResponse.from(existing);
            }
            throw new PatientApiException(HttpStatus.CONFLICT, "Patient synchronization conflict");
        }

        Instant now = Instant.now();
        String uhid = nextHospitalUhid(hospital.getId());
        Patient patient = new Patient(request.uuid(), hospital, uhid, request.name(), request.gender(),
                request.dateOfBirth(), request.ageYears(), request.phone(), request.alternatePhone(),
                request.email(), request.address(), request.city(), request.state(), request.pincode(),
                request.bloodGroup(), request.emergencyContactName(), request.emergencyContactPhone(),
                actorAccountId, now);
        Patient saved = patients.save(patient);
        entityManager.flush();
        auditEvents.save(new SecurityAuditEvent("PATIENT_CREATED", actorAccountId, now));
        return PatientResponse.from(saved);
    }

    private String nextHospitalUhid(UUID hospitalUuid) {
        for (int attempt = 0; attempt < 8; attempt++) {
            String candidate = "UHID-" + (100_000_000_000L +
                    Math.floorMod(UHID_RANDOM.nextLong(), 900_000_000_000L));
            if (!patients.existsByHospital_IdAndUhid(hospitalUuid, candidate)) return candidate;
        }
        throw new PatientApiException(HttpStatus.SERVICE_UNAVAILABLE,
                "Could not allocate a Patient identifier; please retry");
    }

    private static boolean samePayload(Patient patient, PatientCreateRequest request) {
        return patient.getName().equals(request.name())
                && java.util.Objects.equals(patient.getGender(), request.gender())
                && java.util.Objects.equals(patient.getDateOfBirth(), request.dateOfBirth())
                && java.util.Objects.equals(patient.getAgeYears(), request.ageYears())
                && java.util.Objects.equals(patient.getPhone(), request.phone())
                && java.util.Objects.equals(patient.getAlternatePhone(), request.alternatePhone())
                && java.util.Objects.equals(patient.getEmail(), request.email())
                && java.util.Objects.equals(patient.getAddress(), request.address())
                && java.util.Objects.equals(patient.getCity(), request.city())
                && java.util.Objects.equals(patient.getState(), request.state())
                && java.util.Objects.equals(patient.getPincode(), request.pincode())
                && java.util.Objects.equals(patient.getBloodGroup(), request.bloodGroup())
                && java.util.Objects.equals(patient.getEmergencyContactName(), request.emergencyContactName())
                && java.util.Objects.equals(patient.getEmergencyContactPhone(), request.emergencyContactPhone());
    }
}
