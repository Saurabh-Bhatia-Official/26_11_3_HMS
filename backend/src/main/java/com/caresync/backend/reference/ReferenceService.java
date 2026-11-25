package com.caresync.backend.reference;

import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.opd.entity.OpdVisit;
import com.caresync.backend.opd.repository.OpdVisitRepository;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.staff.entity.StaffMember;
import com.caresync.backend.staff.repository.StaffRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@Transactional
public class ReferenceService {
    private final AccessContext access;
    private final PatientRepository patients;
    private final StaffRepository staff;
    private final VisitRepository visits;
    private final AdmissionRepository admissions;
    private final PrescriptionRepository prescriptions;
    private final OpdVisitRepository opdVisits;

    public ReferenceService(AccessContext access, PatientRepository patients, StaffRepository staff,
                            VisitRepository visits, AdmissionRepository admissions,
                            PrescriptionRepository prescriptions, OpdVisitRepository opdVisits) {
        this.access = access;
        this.patients = patients;
        this.staff = staff;
        this.visits = visits;
        this.admissions = admissions;
        this.prescriptions = prescriptions;
        this.opdVisits = opdVisits;
    }

    public ReferenceDtos.VisitResponse createVisit(ReferenceDtos.VisitRequest request) {
        long hospitalId = access.hospitalId();
        Patient patient = patient(request.patientUuid(), hospitalId);
        VisitRecord existing = visits.findByUuidAndHospitalIdAndDeletedFalse(request.uuid(), hospitalId)
                .orElse(null);
        if (existing != null) {
            Long requestedDoctorId = request.doctorId();
            Long existingDoctorId = existing.getDoctor() == null ? null : existing.getDoctor().getId();
            if (!existing.getPatient().getId().equals(patient.getId())
                    || !existing.getVisitType().equals(request.visitType())
                    || !existing.getVisitDate().equals(request.visitDate())
                    || !existing.getStatus().equals(request.status())
                    || !java.util.Objects.equals(existingDoctorId, requestedDoctorId)) {
                throw BusinessException.conflict("Visit UUID is already assigned to different visit data");
            }
            return visitResponse(existing);
        }
        StaffMember doctor = request.doctorId() == null ? null : doctor(request.doctorId(), hospitalId);
        VisitRecord visit = visits.save(new VisitRecord(hospitalId, request.uuid(), patient, doctor,
                request.visitType(), request.visitDate(), request.status()));
        return visitResponse(visit);
    }

    public ReferenceDtos.AdmissionResponse createAdmission(ReferenceDtos.AdmissionRequest request) {
        long hospitalId = access.hospitalId();
        Patient patient = patient(request.patientUuid(), hospitalId);
        VisitRecord visit = visit(request.visitUuid(), hospitalId);
        requireSamePatient(patient, visit.getPatient(), "Visit");
        AdmissionRecord existing = admissions.findByUuidAndHospitalIdAndDeletedFalse(request.uuid(), hospitalId)
                .orElse(null);
        if (existing != null) {
            if (!existing.getPatient().getId().equals(patient.getId())
                    || !existing.getVisit().getId().equals(visit.getId())
                    || !existing.getAdmitDate().equals(request.admitDate())
                    || !existing.getReason().equals(request.reason().trim())
                    || !existing.getStatus().equals(request.status())) {
                throw BusinessException.conflict("Admission UUID is already assigned to different admission data");
            }
            return admissionResponse(existing);
        }
        AdmissionRecord admission = admissions.save(new AdmissionRecord(hospitalId, request.uuid(), patient, visit,
                request.admitDate(), request.reason().trim(), request.status()));
        return admissionResponse(admission);
    }

    public ReferenceDtos.PrescriptionResponse createPrescription(ReferenceDtos.PrescriptionRequest request) {
        long hospitalId = access.hospitalId();
        VisitRecord legacyVisit = visits.findByUuidAndHospitalIdAndDeletedFalse(request.visitUuid(), hospitalId)
                .orElse(null);
        OpdVisit opdVisit = null;
        if (legacyVisit == null) {
            try {
                opdVisit = opdVisits.findByUuidAndHospitalId(UUID.fromString(request.visitUuid()),
                        hospitalId).orElse(null);
            } catch (IllegalArgumentException exception) {
                throw BusinessException.invalid("Visit UUID is invalid");
            }
        }
        if (legacyVisit == null && opdVisit == null) throw BusinessException.notFound("Visit");

        Patient visitPatient = legacyVisit != null
                ? legacyVisit.getPatient()
                : patients.findByIdAndHospital_HospitalIdAndArchivedAtIsNull(opdVisit.getPatientId(), hospitalId)
                    .orElseThrow(() -> BusinessException.notFound("Patient"));
        // OPD stores doctor_uuid against doctor_profiles, not the legacy staff table.
        // Preserve an explicitly supplied legacy staff doctor ID when provided; otherwise
        // leave the optional staff doctor relation empty for UUID-based OPD visits.
        StaffMember doctor = request.doctorId() == null
                ? (legacyVisit == null ? null : legacyVisit.getDoctor())
                : doctor(request.doctorId(), hospitalId);
        PrescriptionRecord existing = prescriptions.findByUuidAndHospitalIdAndDeletedFalse(request.uuid(), hospitalId)
                .orElse(null);
        if (existing != null) {
            boolean sameVisit = legacyVisit != null
                    ? existing.getVisit() != null && existing.getVisit().getId().equals(legacyVisit.getId())
                    : existing.getOpdVisit() != null && existing.getOpdVisit().getId().equals(opdVisit.getId());
            Long requestedDoctorId = doctor == null ? null : doctor.getId();
            Long existingDoctorId = existing.getDoctor() == null ? null : existing.getDoctor().getId();
            if (!sameVisit || !java.util.Objects.equals(existingDoctorId, requestedDoctorId)) {
                throw BusinessException.conflict("Prescription UUID is already assigned to different prescription data");
            }
            return prescriptionResponse(existing);
        }
        PrescriptionRecord prescription = prescriptions.save(new PrescriptionRecord(hospitalId, request.uuid(),
                visitPatient, legacyVisit, opdVisit, doctor, "active"));
        return prescriptionResponse(prescription);
    }

    public Long resolveVisitId(Long id, String uuid, long patientId) {
        ensureSingleReference(id, uuid, "Visit");
        if (id == null && uuid == null) return null;
        long hospitalId = access.hospitalId();
        if (id != null) {
            VisitRecord visit = visit(id, hospitalId);
            if (visit.getPatient().getId() != patientId) {
                throw BusinessException.invalid("Visit does not belong to the patient");
            }
            return visit.getId();
        }
        VisitRecord legacy = visits.findByUuidAndHospitalIdAndDeletedFalse(uuid, hospitalId).orElse(null);
        if (legacy != null) {
            if (legacy.getPatient().getId() != patientId) {
                throw BusinessException.invalid("Visit does not belong to the patient");
            }
            return legacy.getId();
        }
        OpdVisit opd = opdVisits.findByUuidAndHospitalId(UUID.fromString(uuid), hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Visit"));
        if (!opd.getPatientId().equals(patientId)) {
            throw BusinessException.invalid("Visit does not belong to the patient");
        }
        // OPD visits are stored separately; their numeric ID must not be written to legacy visit_id columns.
        return null;
    }

    public Long resolveAdmissionId(Long id, String uuid, long patientId) {
        ensureSingleReference(id, uuid, "Admission");
        if (id == null && uuid == null) return null;
        long hospitalId = access.hospitalId();
        AdmissionRecord admission = id == null ? admission(uuid, hospitalId) : admission(id, hospitalId);
        if (admission.getPatient().getId() != patientId) {
            throw BusinessException.invalid("Admission does not belong to the patient");
        }
        return admission.getId();
    }

    public void validateAdmissionVisitPair(Long admissionId, String admissionUuid, Long visitId, String visitUuid) {
        if ((admissionId == null && admissionUuid == null) || (visitId == null && visitUuid == null)) return;
        long hospitalId = access.hospitalId();
        AdmissionRecord admission = admissionId == null ? admission(admissionUuid, hospitalId)
                : admission(admissionId, hospitalId);
        VisitRecord visit = visitId == null ? visit(visitUuid, hospitalId) : visit(visitId, hospitalId);
        if (!admission.getVisit().getId().equals(visit.getId())) {
            throw BusinessException.invalid("Admission does not belong to the visit");
        }
    }

    public Long resolvePrescriptionId(Long id, String uuid, long patientId, Long visitId, String visitUuid) {
        ensureSingleReference(id, uuid, "Prescription");
        ensureSingleReference(visitId, visitUuid, "Visit");
        if (id == null && uuid == null) return null;
        long hospitalId = access.hospitalId();
        PrescriptionRecord prescription = id == null ? prescription(uuid, hospitalId) : prescription(id, hospitalId);
        if (prescription.getPatient().getId() != patientId) {
            throw BusinessException.invalid("Prescription does not belong to the patient");
        }
        if (visitId != null || visitUuid != null) {
            boolean matches;
            if (visitId != null) {
                VisitRecord visit = visit(visitId, hospitalId);
                matches = prescription.getVisit() != null && prescription.getVisit().getId().equals(visit.getId());
            } else {
                VisitRecord legacy = visits.findByUuidAndHospitalIdAndDeletedFalse(visitUuid, hospitalId).orElse(null);
                if (legacy != null) {
                    matches = prescription.getVisit() != null && prescription.getVisit().getId().equals(legacy.getId());
                } else {
                    OpdVisit opd = opdVisits.findByUuidAndHospitalId(UUID.fromString(visitUuid), hospitalId)
                            .orElseThrow(() -> BusinessException.notFound("Visit"));
                    matches = prescription.getOpdVisit() != null
                            && prescription.getOpdVisit().getId().equals(opd.getId());
                }
            }
            if (!matches) throw BusinessException.invalid("Prescription does not belong to the visit");
        }
        return prescription.getId();
    }

    private Patient patient(String uuid, long hospitalId) {
        final UUID patientUuid;
        try {
            patientUuid = UUID.fromString(uuid);
        } catch (IllegalArgumentException | NullPointerException exception) {
            throw BusinessException.invalid("Patient UUID is invalid");
        }
        return patients.findByUuidAndHospital_HospitalIdAndArchivedAtIsNull(patientUuid, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Patient"));
    }

    private StaffMember doctor(long id, long hospitalId) {
        return staff.findByIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .filter(member -> member.isActive() && member.getRole().equalsIgnoreCase("doctor"))
                .orElseThrow(() -> BusinessException.notFound("Doctor"));
    }

    private VisitRecord visit(String uuid, long hospitalId) {
        return visits.findByUuidAndHospitalIdAndDeletedFalse(uuid, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Visit"));
    }

    private VisitRecord visit(long id, long hospitalId) {
        return visits.findByIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Visit"));
    }

    private AdmissionRecord admission(String uuid, long hospitalId) {
        return admissions.findByUuidAndHospitalIdAndDeletedFalse(uuid, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Admission"));
    }

    private AdmissionRecord admission(long id, long hospitalId) {
        return admissions.findByIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Admission"));
    }

    private PrescriptionRecord prescription(String uuid, long hospitalId) {
        return prescriptions.findByUuidAndHospitalIdAndDeletedFalse(uuid, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Prescription"));
    }

    private PrescriptionRecord prescription(long id, long hospitalId) {
        return prescriptions.findByIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Prescription"));
    }

    private static void requireSamePatient(Patient expected, Patient actual, String reference) {
        if (!expected.getId().equals(actual.getId())) {
            throw BusinessException.invalid(reference + " does not belong to the patient");
        }
    }

    private static void ensureSingleReference(Long id, String uuid, String resource) {
        if (id != null && uuid != null) {
            throw BusinessException.invalid("Provide either " + resource + " ID or UUID, not both");
        }
    }

    private static ReferenceDtos.VisitResponse visitResponse(VisitRecord visit) {
        return new ReferenceDtos.VisitResponse(visit.getId(), visit.getUuid(), visit.getPatient().getId(),
                visit.getDoctor() == null ? null : visit.getDoctor().getId(), visit.getVisitType(),
                visit.getVisitDate(), visit.getStatus(), visit.getCreatedAt(), visit.getUpdatedAt());
    }

    private static ReferenceDtos.AdmissionResponse admissionResponse(AdmissionRecord admission) {
        return new ReferenceDtos.AdmissionResponse(admission.getId(), admission.getUuid(),
                admission.getPatient().getId(), admission.getVisit().getId(), admission.getVisit().getUuid(),
                admission.getAdmitDate(), admission.getReason(), admission.getStatus(),
                admission.getCreatedAt(), admission.getUpdatedAt());
    }

    private static ReferenceDtos.PrescriptionResponse prescriptionResponse(PrescriptionRecord prescription) {
        long visitId = prescription.getVisit() != null
                ? prescription.getVisit().getId() : prescription.getOpdVisit().getId();
        String visitUuid = prescription.getVisit() != null
                ? prescription.getVisit().getUuid() : prescription.getOpdVisit().getUuid().toString();
        return new ReferenceDtos.PrescriptionResponse(prescription.getId(), prescription.getUuid(),
                prescription.getPatient().getId(), visitId, visitUuid,
                prescription.getDoctor() == null ? null : prescription.getDoctor().getId(),
                prescription.getStatus(), prescription.getCreatedAt(), prescription.getUpdatedAt());
    }
}
