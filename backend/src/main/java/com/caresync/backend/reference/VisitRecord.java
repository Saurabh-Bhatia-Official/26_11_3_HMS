package com.caresync.backend.reference;

import com.caresync.backend.common.HospitalScopedEntity;
import com.caresync.backend.patient.entity.PatientRecord;
import com.caresync.backend.staff.entity.StaffMember;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDate;

@Entity
@Table(name = "visits")
public class VisitRecord extends HospitalScopedEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientRecord patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doctor_id")
    private StaffMember doctor;

    @Column(name = "visit_type", nullable = false, length = 20)
    private String visitType;

    @Column(name = "visit_date", nullable = false)
    private LocalDate visitDate;

    @Column(nullable = false, length = 20)
    private String status;

    protected VisitRecord() {}

    public VisitRecord(long hospitalId, String uuid, PatientRecord patient, StaffMember doctor,
                       String visitType, LocalDate visitDate, String status) {
        super(hospitalId, uuid);
        this.patient = patient;
        this.doctor = doctor;
        this.visitType = visitType;
        this.visitDate = visitDate;
        this.status = status;
    }

    public PatientRecord getPatient() { return patient; }
    public StaffMember getDoctor() { return doctor; }
    public String getVisitType() { return visitType; }
    public LocalDate getVisitDate() { return visitDate; }
    public String getStatus() { return status; }
}
