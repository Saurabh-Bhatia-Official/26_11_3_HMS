package com.caresync.backend.billing.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "invoice_payments")
public class Payment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @Column(name = "payment_mode", nullable = false, length = 24)
    private String paymentMode;

    @Column(name = "amount_paise", nullable = false)
    private long amountPaise;

    @Column(name = "reference_no", length = 100)
    private String referenceNo;

    @Column(name = "received_by", nullable = false)
    private long receivedBy;

    @Column(name = "paid_at", nullable = false)
    private Instant paidAt = Instant.now();

    protected Payment() {}

    public Payment(String paymentMode, long amountPaise, String referenceNo, long receivedBy) {
        this.paymentMode = paymentMode;
        this.amountPaise = amountPaise;
        this.referenceNo = referenceNo;
        this.receivedBy = receivedBy;
    }

    void setInvoice(Invoice invoice) { this.invoice = invoice; }
    public long getId() { return id; }
    public String getPaymentMode() { return paymentMode; }
    public long getAmountPaise() { return amountPaise; }
    public String getReferenceNo() { return referenceNo; }
    public long getReceivedBy() { return receivedBy; }
    public Instant getPaidAt() { return paidAt; }
}
