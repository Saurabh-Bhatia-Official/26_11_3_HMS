package com.caresync.backend.billing.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "billable_services", uniqueConstraints = @UniqueConstraint(
        name = "uk_service_hospital_name", columnNames = {"hospital_id", "name"}))
public class BillableService extends HospitalScopedEntity {
    @Column(nullable = false, length = 160)
    private String name;

    @Column(nullable = false, length = 80)
    private String category = "";

    @Column(name = "price_paise", nullable = false)
    private long pricePaise;

    @Column(name = "tax_rate_pct", nullable = false)
    private double taxRatePct;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    protected BillableService() {}

    public BillableService(long hospitalId, String name, String category, long pricePaise, double taxRatePct,
                           boolean active) {
        super(hospitalId);
        update(name, category, pricePaise, taxRatePct, active);
    }

    public void update(String name, String category, long pricePaise, double taxRatePct, boolean active) {
        this.name = name;
        this.category = category == null ? "" : category;
        this.pricePaise = pricePaise;
        this.taxRatePct = taxRatePct;
        this.active = active;
    }

    public String getName() { return name; }
    public String getCategory() { return category; }
    public long getPricePaise() { return pricePaise; }
    public double getTaxRatePct() { return taxRatePct; }
    public boolean isActive() { return active; }
}
