package com.caresync.backend.lab.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "lab_tests", uniqueConstraints = @UniqueConstraint(
        name = "uk_lab_test_hospital_name", columnNames = {"hospital_id", "name"}))
public class LabTest extends HospitalScopedEntity {
    @Column(nullable = false, length = 180)
    private String name;

    @Column(nullable = false, length = 100)
    private String category = "";

    @Column(name = "sample_type", nullable = false, length = 80)
    private String sampleType = "";

    @Column(name = "price_paise", nullable = false)
    private long pricePaise;

    @Column(name = "turnaround_hours", nullable = false)
    private int turnaroundHours = 24;

    @Column(name = "is_outsourced", nullable = false)
    private boolean outsourced;

    @OneToMany(mappedBy = "test", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<LabTestParameter> parameters = new ArrayList<>();

    protected LabTest() {}

    public LabTest(long hospitalId, String name, String category, String sampleType, long pricePaise,
                   int turnaroundHours, boolean outsourced) {
        super(hospitalId);
        update(name, category, sampleType, pricePaise, turnaroundHours, outsourced);
    }

    public void update(String name, String category, String sampleType, long pricePaise, int turnaroundHours,
                       boolean outsourced) {
        this.name = name;
        this.category = category == null ? "" : category;
        this.sampleType = sampleType == null ? "" : sampleType;
        this.pricePaise = pricePaise;
        this.turnaroundHours = turnaroundHours;
        this.outsourced = outsourced;
    }

    public void replaceParameters(List<LabTestParameter> newParameters) {
        parameters.clear();
        newParameters.forEach(parameter -> {
            parameters.add(parameter);
            parameter.setTest(this);
        });
    }

    public String getName() { return name; }
    public String getCategory() { return category; }
    public String getSampleType() { return sampleType; }
    public long getPricePaise() { return pricePaise; }
    public int getTurnaroundHours() { return turnaroundHours; }
    public boolean isOutsourced() { return outsourced; }
    public List<LabTestParameter> getParameters() { return List.copyOf(parameters); }
}
