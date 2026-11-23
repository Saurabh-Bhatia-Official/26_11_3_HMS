package com.caresync.backend.reference;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "beds", uniqueConstraints = {
        @UniqueConstraint(name = "uk_bed_hospital_number", columnNames = {"hospital_id", "bed_number"})
})
public class BedRecord extends HospitalScopedEntity {
    @Column(name = "bed_number", nullable = false, length = 32)
    private String bedNumber;

    @Column(nullable = false, length = 64)
    private String ward = "General Ward";

    @Column(name = "bed_type", nullable = false, length = 32)
    private String bedType = "General";

    @Column(name = "tariff_paise", nullable = false)
    private long tariffPaise = 80000;

    @Column(nullable = false, length = 24)
    private String status = "available";

    @Column(name = "patient_id")
    private Long patientId;

    @Column(name = "patient_name", length = 200)
    private String patientName;

    @Column(length = 32)
    private String uhid;

    @Column(name = "admission_id")
    private Long admissionId;

    protected BedRecord() {}

    public BedRecord(long hospitalId, String uuid, String bedNumber, String ward, String bedType,
                     long tariffPaise, String status) {
        super(hospitalId, uuid);
        this.bedNumber = bedNumber;
        this.ward = ward == null || ward.isBlank() ? "General Ward" : ward.trim();
        this.bedType = bedType == null || bedType.isBlank() ? "General" : bedType.trim();
        this.tariffPaise = tariffPaise;
        this.status = status == null || status.isBlank() ? "available" : status.trim().toLowerCase();
    }

    public void allocate(Long patientId, String patientName, String uhid, Long admissionId) {
        this.patientId = patientId;
        this.patientName = patientName;
        this.uhid = uhid;
        this.admissionId = admissionId;
        this.status = "occupied";
    }

    public void release(String newStatus) {
        this.patientId = null;
        this.patientName = null;
        this.uhid = null;
        this.admissionId = null;
        this.status = (newStatus != null && !newStatus.isBlank()) ? newStatus.trim().toLowerCase() : "available";
    }

    public String getBedNumber() { return bedNumber; }
    public void setBedNumber(String bedNumber) { this.bedNumber = bedNumber; }

    public String getWard() { return ward; }
    public void setWard(String ward) { this.ward = ward; }

    public String getBedType() { return bedType; }
    public void setBedType(String bedType) { this.bedType = bedType; }

    public long getTariffPaise() { return tariffPaise; }
    public void setTariffPaise(long tariffPaise) { this.tariffPaise = tariffPaise; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Long getPatientId() { return patientId; }
    public String getPatientName() { return patientName; }
    public String getUhid() { return uhid; }
    public Long getAdmissionId() { return admissionId; }
}
