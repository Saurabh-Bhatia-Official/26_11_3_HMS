package com.caresync.backend.pharmacy.entity;

import com.caresync.backend.common.HospitalScopedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "stock_adjustments")
public class StockAdjustment extends HospitalScopedEntity {
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "batch_id", nullable = false)
    private MedicineBatch batch;

    @Column(name = "adjustment_quantity", nullable = false)
    private int adjustmentQuantity;

    @Column(nullable = false, length = 300)
    private String reason;

    @Column(name = "adjusted_by", nullable = false)
    private long adjustedBy;

    protected StockAdjustment() {}

    public StockAdjustment(long hospitalId, MedicineBatch batch, int adjustmentQuantity, String reason, long adjustedBy) {
        super(hospitalId);
        this.batch = batch;
        this.adjustmentQuantity = adjustmentQuantity;
        this.reason = reason;
        this.adjustedBy = adjustedBy;
    }

    public MedicineBatch getBatch() { return batch; }
    public int getAdjustmentQuantity() { return adjustmentQuantity; }
    public String getReason() { return reason; }
    public long getAdjustedBy() { return adjustedBy; }
}
