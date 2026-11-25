package com.caresync.backend.reference;

import com.caresync.backend.common.HospitalScopedEntity;
import com.caresync.backend.patient.entity.Patient;
import com.caresync.backend.opd.entity.OpdVisit;
import com.caresync.backend.staff.entity.StaffMember;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "prescriptions")
public class PrescriptionRecord extends HospitalScopedEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "visit_id")
    private VisitRecord visit;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "opd_visit_id")
    private OpdVisit opdVisit;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doctor_id")
    private StaffMember doctor;

    @Column(nullable = false, length = 20)
    private String status;

    protected PrescriptionRecord() {}

    public PrescriptionRecord(long hospitalId, String uuid, Patient patient, VisitRecord visit,
                              OpdVisit opdVisit, StaffMember doctor, String status) {
        super(hospitalId, uuid);
        this.patient = patient;
        this.visit = visit;
        this.opdVisit = opdVisit;
        this.doctor = doctor;
        this.status = status;
    }

    public Patient getPatient() { return patient; }
    public VisitRecord getVisit() { return visit; }
    public OpdVisit getOpdVisit() { return opdVisit; }
    public StaffMember getDoctor() { return doctor; }
    public String getStatus() { return status; }
}
