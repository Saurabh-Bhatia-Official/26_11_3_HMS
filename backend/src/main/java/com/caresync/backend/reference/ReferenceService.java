package com.caresync.backend.reference;

import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.patient.entity.PatientRecord;
import com.caresync.backend.patient.repository.PatientRepository;
import com.caresync.backend.staff.entity.StaffMember;
import com.caresync.backend.staff.repository.StaffRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ReferenceService {
    private final AccessContext access;
    private final PatientRepository patients;
    private final StaffRepository staff;
    private final VisitRepository visits;
    private final AdmissionRepository admissions;
    private final PrescriptionRepository prescriptions;
    private final BedRepository beds;

    public ReferenceService(AccessContext access, PatientRepository patients, StaffRepository staff,
                            VisitRepository visits, AdmissionRepository admissions,
                            PrescriptionRepository prescriptions, BedRepository beds) {
        this.access = access;
        this.patients = patients;
        this.staff = staff;
        this.visits = visits;
        this.admissions = admissions;
        this.prescriptions = prescriptions;
        this.beds = beds;
    }

    public ReferenceDtos.VisitResponse createVisit(ReferenceDtos.VisitRequest request) {
        long hospitalId = access.hospitalId();
        PatientRecord patient = patient(request.patientUuid(), hospitalId);
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
        PatientRecord patient = patient(request.patientUuid(), hospitalId);
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
        VisitRecord visit = visit(request.visitUuid(), hospitalId);
        StaffMember doctor = request.doctorId() == null ? visit.getDoctor()
                : doctor(request.doctorId(), hospitalId);
        PrescriptionRecord existing = prescriptions.findByUuidAndHospitalIdAndDeletedFalse(request.uuid(), hospitalId)
                .orElse(null);
        if (existing != null) {
            Long requestedDoctorId = doctor == null ? null : doctor.getId();
            Long existingDoctorId = existing.getDoctor() == null ? null : existing.getDoctor().getId();
            if (!existing.getVisit().getId().equals(visit.getId())
                    || !java.util.Objects.equals(existingDoctorId, requestedDoctorId)) {
                throw BusinessException.conflict("Prescription UUID is already assigned to different prescription data");
            }
            return prescriptionResponse(existing);
        }
        PrescriptionRecord prescription = prescriptions.save(new PrescriptionRecord(hospitalId, request.uuid(),
                visit.getPatient(), visit, doctor, "active"));
        return prescriptionResponse(prescription);
    }

    public Long resolveVisitId(Long id, String uuid, long patientId) {
        ensureSingleReference(id, uuid, "Visit");
        if (id == null && uuid == null) return null;
        long hospitalId = access.hospitalId();
        VisitRecord visit = id == null ? visit(uuid, hospitalId) : visit(id, hospitalId);
        if (visit.getPatient().getId() != patientId) {
            throw BusinessException.invalid("Visit does not belong to the patient");
        }
        return visit.getId();
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
            VisitRecord visit = visitId == null ? visit(visitUuid, hospitalId) : visit(visitId, hospitalId);
            if (!prescription.getVisit().getId().equals(visit.getId())) {
                throw BusinessException.invalid("Prescription does not belong to the visit");
            }
        }
        return prescription.getId();
    }

    private PatientRecord patient(String uuid, long hospitalId) {
        return patients.findByUuidAndHospitalIdAndDeletedFalse(uuid, hospitalId)
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

    private static void requireSamePatient(PatientRecord expected, PatientRecord actual, String reference) {
        if (!expected.getId().equals(actual.getId())) {
            throw BusinessException.invalid(reference + " does not belong to the patient");
        }
    }

    private static void ensureSingleReference(Long id, String uuid, String resource) {
        if (id != null && uuid != null) {
            throw BusinessException.invalid("Provide either " + resource + " ID or UUID, not both");
        }
    }

    public ReferenceDtos.AdmissionResponse dischargeAdmission(long id) {
        long hospitalId = access.hospitalId();
        AdmissionRecord admission = admissions.findByIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Admission not found"));
        admission.discharge();
        beds.findByAdmissionIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .ifPresent(bed -> bed.release("available"));
        return admissionResponse(admission);
    }

    public ReferenceDtos.AdmissionResponse getAdmission(long id) {
        return admissions.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .map(ReferenceService::admissionResponse)
                .orElseThrow(() -> BusinessException.notFound("Admission not found"));
    }

    public java.util.List<ReferenceDtos.AdmissionResponse> listAdmissions() {
        return admissions.findAll().stream()
                .filter(a -> a.getHospitalId().equals(access.hospitalId()) && !a.isDeleted())
                .map(ReferenceService::admissionResponse)
                .toList();
    }

    public ReferenceDtos.BedResponse createBed(ReferenceDtos.BedRequest request) {
        long hospitalId = access.hospitalId();
        beds.findByBedNumberAndHospitalIdAndDeletedFalse(request.bedNumber(), hospitalId)
                .ifPresent(existing -> {
                    throw BusinessException.conflict("Bed number already exists: " + request.bedNumber());
                });
        long tariff = request.tariffPaise() != null ? request.tariffPaise() : 80000;
        BedRecord bed = beds.save(new BedRecord(hospitalId, request.uuid(), request.bedNumber(),
                request.ward(), request.bedType(), tariff, request.status()));
        return bedResponse(bed);
    }

    public ReferenceDtos.BedResponse updateBed(long id, ReferenceDtos.BedRequest request) {
        long hospitalId = access.hospitalId();
        BedRecord bed = beds.findByIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Bed not found"));
        if (request.bedNumber() != null && !request.bedNumber().isBlank()) {
            bed.setBedNumber(request.bedNumber().trim());
        }
        if (request.ward() != null) bed.setWard(request.ward().trim());
        if (request.bedType() != null) bed.setBedType(request.bedType().trim());
        if (request.tariffPaise() != null) bed.setTariffPaise(request.tariffPaise());
        if (request.status() != null) bed.setStatus(request.status().trim().toLowerCase());
        return bedResponse(bed);
    }

    public java.util.List<ReferenceDtos.BedResponse> listBeds() {
        return beds.findAllByHospitalIdAndDeletedFalseOrderByBedNumberAsc(access.hospitalId()).stream()
                .map(ReferenceService::bedResponse)
                .toList();
    }

    public ReferenceDtos.BedResponse getBed(long id) {
        return beds.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .map(ReferenceService::bedResponse)
                .orElseThrow(() -> BusinessException.notFound("Bed not found"));
    }

    public ReferenceDtos.BedResponse allocateBed(long bedId, ReferenceDtos.BedAllocationRequest request) {
        long hospitalId = access.hospitalId();
        BedRecord bed = beds.findByIdAndHospitalIdAndDeletedFalse(bedId, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Bed not found"));
        bed.allocate(request.patientId(), request.patientName(), request.uhid(), request.admissionId());
        return bedResponse(bed);
    }

    public ReferenceDtos.BedResponse releaseBed(long bedId, String status) {
        long hospitalId = access.hospitalId();
        BedRecord bed = beds.findByIdAndHospitalIdAndDeletedFalse(bedId, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Bed not found"));
        bed.release(status);
        return bedResponse(bed);
    }

    public void deleteBed(long id) {
        long hospitalId = access.hospitalId();
        BedRecord bed = beds.findByIdAndHospitalIdAndDeletedFalse(id, hospitalId)
                .orElseThrow(() -> BusinessException.notFound("Bed not found"));
        bed.markDeleted();
    }

    private static ReferenceDtos.BedResponse bedResponse(BedRecord b) {
        return new ReferenceDtos.BedResponse(b.getId(), b.getUuid(), b.getBedNumber(), b.getWard(),
                b.getBedType(), b.getTariffPaise(), b.getStatus(), b.getPatientId(), b.getPatientName(),
                b.getUhid(), b.getAdmissionId(), b.getCreatedAt(), b.getUpdatedAt());
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
        return new ReferenceDtos.PrescriptionResponse(prescription.getId(), prescription.getUuid(),
                prescription.getPatient().getId(), prescription.getVisit().getId(), prescription.getVisit().getUuid(),
                prescription.getDoctor() == null ? null : prescription.getDoctor().getId(),
                prescription.getStatus(), prescription.getCreatedAt(), prescription.getUpdatedAt());
    }
}
