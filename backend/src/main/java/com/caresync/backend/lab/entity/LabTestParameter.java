package com.caresync.backend.lab.entity;

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
@Table(name = "lab_test_parameters")
public class LabTestParameter {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "test_id", nullable = false)
    private LabTest test;

    @Column(name = "parameter_name", nullable = false, length = 160)
    private String parameterName;

    @Column(nullable = false, length = 32)
    private String unit = "";

    @Column(name = "range_low")
    private Double rangeLow;

    @Column(name = "range_high")
    private Double rangeHigh;

    @Column(name = "reference_text", length = 200)
    private String referenceText;

    protected LabTestParameter() {}

    public LabTestParameter(String parameterName, String unit, Double rangeLow, Double rangeHigh,
                            String referenceText) {
        this.parameterName = parameterName;
        this.unit = unit == null ? "" : unit;
        this.rangeLow = rangeLow;
        this.rangeHigh = rangeHigh;
        this.referenceText = referenceText;
    }

    void setTest(LabTest test) { this.test = test; }
    public long getId() { return id; }
    public String getParameterName() { return parameterName; }
    public String getUnit() { return unit; }
    public Double getRangeLow() { return rangeLow; }
    public Double getRangeHigh() { return rangeHigh; }
    public String getReferenceText() { return referenceText; }
}
