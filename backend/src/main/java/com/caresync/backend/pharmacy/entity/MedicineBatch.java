package com.caresync.backend.pharmacy.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.LocalDate;

@Entity
@Table(name = "medicine_batches", uniqueConstraints = @UniqueConstraint(
        name = "uk_batch_hospital_medicine_batch", columnNames = {"hospital_id", "medicine_id", "batch_number"}))
public class MedicineBatch extends HospitalScopedEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "medicine_id", nullable = false)
    private Medicine medicine;

    @Column(name = "batch_number", nullable = false, length = 80)
    private String batchNo;

    @Column(name = "expiry_date", nullable = false)
    private LocalDate expiryDate;

    @Column(name = "manufacture_date")
    private LocalDate manufactureDate;

    @Column(name = "quantity_on_hand", nullable = false)
    private int quantityOnHand;

    @Column(name = "purchase_price_paise", nullable = false)
    private long purchasePricePaise;

    @Column(name = "mrp_paise", nullable = false)
    private long mrpPaise;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "supplier_id")
    private Supplier supplier;

    protected MedicineBatch() {}

    public MedicineBatch(long hospitalId, Medicine medicine, String batchNo, LocalDate expiryDate,
                         LocalDate manufactureDate, int quantityOnHand, long purchasePricePaise, long mrpPaise,
                         Supplier supplier) {
        super(hospitalId);
        this.medicine = medicine;
        this.batchNo = batchNo;
        this.expiryDate = expiryDate;
        this.manufactureDate = manufactureDate;
        this.quantityOnHand = quantityOnHand;
        this.purchasePricePaise = purchasePricePaise;
        this.mrpPaise = mrpPaise;
        this.supplier = supplier;
    }

    public void receive(int quantity, long purchasePricePaise, long mrpPaise) {
        quantityOnHand = Math.addExact(quantityOnHand, quantity);
        this.purchasePricePaise = purchasePricePaise;
        this.mrpPaise = mrpPaise;
    }

    public void adjust(int quantity) {
        int next = Math.addExact(quantityOnHand, quantity);
        if (next < 0) throw new IllegalArgumentException("Stock cannot become negative");
        quantityOnHand = next;
    }

    public Medicine getMedicine() { return medicine; }
    public String getBatchNo() { return batchNo; }
    public LocalDate getExpiryDate() { return expiryDate; }
    public LocalDate getManufactureDate() { return manufactureDate; }
    public int getQuantityOnHand() { return quantityOnHand; }
    public long getPurchasePricePaise() { return purchasePricePaise; }
    public long getMrpPaise() { return mrpPaise; }
    public Supplier getSupplier() { return supplier; }
}
