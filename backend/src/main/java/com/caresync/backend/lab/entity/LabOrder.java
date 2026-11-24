package com.caresync.backend.lab.entity;

import com.caresync.backend.common.BusinessException;
import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "lab_orders", uniqueConstraints = @UniqueConstraint(
        name = "uk_lab_order_hospital_number", columnNames = {"hospital_id", "order_number"}))
public class LabOrder extends HospitalScopedEntity {
    @Column(name = "order_number", nullable = false, length = 48)
    private String orderNo;

    @Column(name = "patient_id", nullable = false)
    private long patientId;

    @Column(name = "patient_name", nullable = false, length = 200)
    private String patientName;

    @Column(nullable = false, length = 32)
    private String uhid = "";

    @Column(name = "visit_id")
    private Long visitId;

    @Column(name = "doctor_id")
    private Long doctorId;

    @Column(name = "doctor_name", nullable = false, length = 160)
    private String doctorName = "";

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "test_id", nullable = false)
    private LabTest test;

    @Column(nullable = false, length = 20)
    private String priority;

    @Column(nullable = false, length = 24)
    private String status = "pending";

    @Column(nullable = false, length = 1000)
    private String notes = "";

    @Column(name = "ordered_at", nullable = false)
    private Instant orderedAt = Instant.now();

    @Column(name = "sample_collected_at")
    private Instant sampleCollectedAt;

    @Column(name = "resulted_at")
    private Instant resultedAt;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    @Column(name = "entered_by")
    private Long enteredBy;

    @Column(name = "verified_by")
    private Long verifiedBy;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<LabResult> results = new ArrayList<>();

    protected LabOrder() {}

    public LabOrder(long hospitalId, String orderNo, long patientId, String patientName, String uhid,
                    Long visitId, Long doctorId, String doctorName, LabTest test, String priority, String notes) {
        super(hospitalId);
        this.orderNo = orderNo;
        this.patientId = patientId;
        this.patientName = patientName;
        this.uhid = uhid == null ? "" : uhid;
        this.visitId = visitId;
        this.doctorId = doctorId;
        this.doctorName = doctorName == null ? "" : doctorName;
        this.test = test;
        this.priority = priority;
        this.notes = notes == null ? "" : notes;
    }

    public void collect() {
        requireStatus("pending");
        status = "collected";
        sampleCollectedAt = Instant.now();
    }

    public void startProcessing() {
        requireStatus("collected");
        status = "processing";
    }

    public void enterResults(List<LabResult> newResults, long userId) {
        if (!"processing".equals(status) && !"resulted".equals(status) && !"verified".equals(status) && !"completed".equals(status) && !"collected".equals(status)) {
            throw BusinessException.conflict("Order must be collected, processing, resulted, or verified before this action");
        }
        results.clear();
        newResults.forEach(result -> {
            results.add(result);
            result.setOrder(this);
        });
        enteredBy = userId;
        resultedAt = Instant.now();
        if ("processing".equals(status) || "collected".equals(status)) {
            status = "resulted";
        }
    }

    public void verify(long userId) {
        requireStatus("resulted");
        verifiedBy = userId;
        verifiedAt = Instant.now();
        status = "verified";
    }

    public void deliver() {
        requireStatus("verified");
        status = "delivered";
    }

    private void requireStatus(String expected) {
        if (!status.equals(expected)) throw BusinessException.conflict("Order must be " + expected + " before this action");
    }

    public String getOrderNo() { return orderNo; }
    public long getPatientId() { return patientId; }
    public String getPatientName() { return patientName; }
    public String getUhid() { return uhid; }
    public Long getVisitId() { return visitId; }
    public Long getDoctorId() { return doctorId; }
    public String getDoctorName() { return doctorName; }
    public LabTest getTest() { return test; }
    public String getPriority() { return priority; }
    public String getStatus() { return status; }
    public String getNotes() { return notes; }
    public Instant getOrderedAt() { return orderedAt; }
    public Instant getSampleCollectedAt() { return sampleCollectedAt; }
    public Instant getResultedAt() { return resultedAt; }
    public Instant getVerifiedAt() { return verifiedAt; }
    public Long getEnteredBy() { return enteredBy; }
    public Long getVerifiedBy() { return verifiedBy; }
    public List<LabResult> getResults() { return List.copyOf(results); }
}
