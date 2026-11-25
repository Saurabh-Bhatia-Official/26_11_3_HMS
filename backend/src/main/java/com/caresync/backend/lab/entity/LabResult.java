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
@Table(name = "lab_results")
public class LabResult {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "order_id", nullable = false)
    private LabOrder order;

    @Column(name = "parameter_name", nullable = false, length = 160)
    private String parameterName;

    @Column(name = "result_value", nullable = false, length = 500)
    private String resultValue;

    @Column(nullable = false, length = 32)
    private String unit = "";

    @Column(name = "reference_range", nullable = false, length = 200)
    private String referenceRange = "";

    @Column(name = "abnormal_flag", nullable = false, length = 24)
    private String abnormalFlag = "normal";

    protected LabResult() {}

    public LabResult(String parameterName, String resultValue, String unit, String referenceRange, String abnormalFlag) {
        this.parameterName = parameterName;
        this.resultValue = resultValue;
        this.unit = unit == null ? "" : unit;
        this.referenceRange = referenceRange == null ? "" : referenceRange;
        this.abnormalFlag = abnormalFlag == null ? "normal" : abnormalFlag;
    }

    void setOrder(LabOrder order) { this.order = order; }
    public long getId() { return id; }
    public String getParameterName() { return parameterName; }
    public String getResultValue() { return resultValue; }
    public String getUnit() { return unit; }
    public String getReferenceRange() { return referenceRange; }
    public String getAbnormalFlag() { return abnormalFlag; }
}
