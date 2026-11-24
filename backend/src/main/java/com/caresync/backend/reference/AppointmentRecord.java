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
@Table(name = "appointments")
public class AppointmentRecord extends HospitalScopedEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private PatientRecord patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doctor_id")
    private StaffMember doctor;

    @Column(name = "appointment_date", nullable = false)
    private LocalDate appointmentDate;

    @Column(name = "time_slot", nullable = false, length = 32)
    private String timeSlot = "09:00 AM";

    @Column(name = "token_no", nullable = false)
    private int tokenNo = 1;

    @Column(name = "visit_type", nullable = false, length = 32)
    private String visitType = "New Consultation";

    @Column(nullable = false, length = 24)
    private String status = "scheduled";

    @Column(length = 1000)
    private String notes = "";

    protected AppointmentRecord() {}

    public AppointmentRecord(long hospitalId, String uuid, PatientRecord patient, StaffMember doctor,
                             LocalDate appointmentDate, String timeSlot, int tokenNo, String visitType,
                             String status, String notes) {
        super(hospitalId, uuid);
        this.patient = patient;
        this.doctor = doctor;
        this.appointmentDate = appointmentDate;
        this.timeSlot = timeSlot == null ? "09:00 AM" : timeSlot;
        this.tokenNo = tokenNo;
        this.visitType = visitType == null ? "New Consultation" : visitType;
        this.status = status == null ? "scheduled" : status.toLowerCase();
        this.notes = notes == null ? "" : notes;
    }

    public PatientRecord getPatient() { return patient; }
    public StaffMember getDoctor() { return doctor; }
    public LocalDate getAppointmentDate() { return appointmentDate; }
    public String getTimeSlot() { return timeSlot; }
    public int getTokenNo() { return tokenNo; }
    public String getVisitType() { return visitType; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status == null ? "scheduled" : status.toLowerCase(); }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes == null ? "" : notes; }
}
