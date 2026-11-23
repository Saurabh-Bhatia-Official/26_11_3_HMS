package com.caresync.backend.pharmacy.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "dispensing_items")
public class DispensingItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "dispensing_id", nullable = false)
    private Dispensing dispensing;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "medicine_id", nullable = false)
    private Medicine medicine;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "batch_id", nullable = false)
    private MedicineBatch batch;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "unit_price_paise", nullable = false)
    private long unitPricePaise;

    @Column(name = "tax_rate_pct", nullable = false)
    private double taxRatePct;

    @Column(name = "total_paise", nullable = false)
    private long totalPaise;

    protected DispensingItem() {}

    public DispensingItem(Medicine medicine, MedicineBatch batch, int quantity, long unitPricePaise,
                          double taxRatePct, long totalPaise) {
        this.medicine = medicine;
        this.batch = batch;
        this.quantity = quantity;
        this.unitPricePaise = unitPricePaise;
        this.taxRatePct = taxRatePct;
        this.totalPaise = totalPaise;
    }

    void setDispensing(Dispensing dispensing) { this.dispensing = dispensing; }
    public long getId() { return id; }
    public Medicine getMedicine() { return medicine; }
    public MedicineBatch getBatch() { return batch; }
    public int getQuantity() { return quantity; }
    public long getUnitPricePaise() { return unitPricePaise; }
    public double getTaxRatePct() { return taxRatePct; }
    public long getTotalPaise() { return totalPaise; }
}
