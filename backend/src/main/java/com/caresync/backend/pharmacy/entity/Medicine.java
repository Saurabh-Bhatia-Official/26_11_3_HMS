package com.caresync.backend.pharmacy.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "medicines", uniqueConstraints = @UniqueConstraint(
        name = "uk_medicine_hospital_variant", columnNames = {"hospital_id", "name", "form", "strength"}))
public class Medicine extends HospitalScopedEntity {
    @Column(nullable = false, length = 180)
    private String name;

    @Column(name = "generic_name", nullable = false, length = 180)
    private String genericName = "";

    @Column(nullable = false, length = 32)
    private String form;

    @Column(nullable = false, length = 64)
    private String strength = "";

    @Column(nullable = false, length = 160)
    private String manufacturer = "";

    @Column(nullable = false, length = 100)
    private String category = "";

    @Column(nullable = false, length = 32)
    private String unit = "";

    @Column(name = "tax_rate_pct", nullable = false)
    private double taxRatePct;

    @Column(name = "reorder_level", nullable = false)
    private int reorderLevel = 10;

    @Column(name = "hsn_code", length = 32)
    private String hsnCode;

    protected Medicine() {}

    public Medicine(long hospitalId, String name, String genericName, String form, String strength,
                    String manufacturer, String category, String unit, double taxRatePct, int reorderLevel,
                    String hsnCode) {
        super(hospitalId);
        update(name, genericName, form, strength, manufacturer, category, unit, taxRatePct, reorderLevel, hsnCode);
    }

    public void update(String name, String genericName, String form, String strength, String manufacturer,
                       String category, String unit, double taxRatePct, int reorderLevel, String hsnCode) {
        this.name = name;
        this.genericName = genericName == null ? "" : genericName;
        this.form = form;
        this.strength = strength == null ? "" : strength;
        this.manufacturer = manufacturer == null ? "" : manufacturer;
        this.category = category == null ? "" : category;
        this.unit = unit == null ? "" : unit;
        this.taxRatePct = taxRatePct;
        this.reorderLevel = reorderLevel;
        this.hsnCode = hsnCode;
    }

    public String getName() { return name; }
    public String getGenericName() { return genericName; }
    public String getForm() { return form; }
    public String getStrength() { return strength; }
    public String getManufacturer() { return manufacturer; }
    public String getCategory() { return category; }
    public String getUnit() { return unit; }
    public double getTaxRatePct() { return taxRatePct; }
    public int getReorderLevel() { return reorderLevel; }
    public String getHsnCode() { return hsnCode; }
}
