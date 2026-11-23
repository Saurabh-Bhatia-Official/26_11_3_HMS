package com.caresync.backend.patient.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "patients", uniqueConstraints = {
        @UniqueConstraint(name = "uk_patient_hospital_uhid", columnNames = {"hospital_id", "uhid"})
})
public class PatientRecord extends HospitalScopedEntity {
    @Column(nullable = false, length = 30)
    private String uhid;

    @Column(nullable = false, length = 200)
    private String name;

    protected PatientRecord() {}

    public PatientRecord(long hospitalId, String uuid, String uhid, String name) {
        super(hospitalId, uuid);
        this.uhid = uhid;
        this.name = name;
    }

    public String getUhid() { return uhid; }
    public String getName() { return name; }
}
