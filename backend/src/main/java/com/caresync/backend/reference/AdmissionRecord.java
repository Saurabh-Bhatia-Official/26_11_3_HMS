package com.caresync.backend.reference;

import com.caresync.backend.common.HospitalScopedEntity;
import com.caresync.backend.patient.entity.PatientRecord;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDate;

@Entity
@Table(name = "admissions")
public class AdmissionRecord extends HospitalScopedEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientRecord patient;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "visit_id", nullable = false)
    private VisitRecord visit;

    @Column(name = "admit_date", nullable = false)
    private LocalDate admitDate;

    @Column(name = "reason", nullable = false, length = 500)
    private String reason;

    @Column(nullable = false, length = 20)
    private String status;

    protected AdmissionRecord() {}

    public AdmissionRecord(long hospitalId, String uuid, PatientRecord patient, VisitRecord visit,
                           LocalDate admitDate, String reason, String status) {
        super(hospitalId, uuid);
        this.patient = patient;
        this.visit = visit;
        this.admitDate = admitDate;
        this.reason = reason;
        this.status = status;
    }

    public PatientRecord getPatient() { return patient; }
    public VisitRecord getVisit() { return visit; }
    public LocalDate getAdmitDate() { return admitDate; }
    public String getReason() { return reason; }
    public String getStatus() { return status; }
}
