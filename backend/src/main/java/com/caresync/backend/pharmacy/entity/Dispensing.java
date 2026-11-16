package com.caresync.backend.pharmacy.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "dispensings")
public class Dispensing extends HospitalScopedEntity {
    @Column(name = "patient_id", nullable = false)
    private long patientId;

    @Column(name = "prescription_id")
    private Long prescriptionId;

    @Column(name = "visit_id")
    private Long visitId;

    @Column(name = "dispensed_by", nullable = false)
    private long dispensedBy;

    @Column(name = "total_amount_paise", nullable = false)
    private long totalAmountPaise;

    @Column(name = "counter_sale", nullable = false)
    private boolean counterSale;

    @OneToMany(mappedBy = "dispensing", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<DispensingItem> items = new ArrayList<>();

    protected Dispensing() {}

    public Dispensing(long hospitalId, long patientId, Long prescriptionId, Long visitId, long dispensedBy,
                      boolean counterSale, long totalAmountPaise) {
        super(hospitalId);
        this.patientId = patientId;
        this.prescriptionId = prescriptionId;
        this.visitId = visitId;
        this.dispensedBy = dispensedBy;
        this.counterSale = counterSale;
        this.totalAmountPaise = totalAmountPaise;
    }

    public void addItem(DispensingItem item) {
        items.add(item);
        item.setDispensing(this);
    }

    public long getPatientId() { return patientId; }
    public Long getPrescriptionId() { return prescriptionId; }
    public Long getVisitId() { return visitId; }
    public long getDispensedBy() { return dispensedBy; }
    public long getTotalAmountPaise() { return totalAmountPaise; }
    public boolean isCounterSale() { return counterSale; }
    public List<DispensingItem> getItems() { return List.copyOf(items); }
}
