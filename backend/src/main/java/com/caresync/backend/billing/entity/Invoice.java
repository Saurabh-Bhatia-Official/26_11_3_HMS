package com.caresync.backend.billing.entity;

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
@Table(name = "invoices", uniqueConstraints = @UniqueConstraint(
        name = "uk_invoice_hospital_number", columnNames = {"hospital_id", "invoice_number"}))
public class Invoice extends HospitalScopedEntity {
    @Column(name = "invoice_number", nullable = false, length = 48)
    private String invoiceNo;

    @Column(name = "patient_id", nullable = false)
    private long patientId;

    @Column(name = "patient_name", nullable = false, length = 200)
    private String patientName;

    @Column(nullable = false, length = 32)
    private String uhid = "";

    @Column(name = "visit_id")
    private Long visitId;

    @Column(name = "admission_id")
    private Long admissionId;

    @Column(name = "invoice_type", nullable = false, length = 32)
    private String invoiceType;

    @Column(name = "subtotal_paise", nullable = false)
    private long subtotalPaise;

    @Column(name = "discount_paise", nullable = false)
    private long discountPaise;

    @Column(name = "discount_reason", length = 300)
    private String discountReason;

    @Column(name = "tax_paise", nullable = false)
    private long taxPaise;

    @Column(name = "total_paise", nullable = false)
    private long totalPaise;

    @Column(name = "paid_paise", nullable = false)
    private long paidPaise;

    @Column(name = "due_paise", nullable = false)
    private long duePaise;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(length = 1000)
    private String notes;

    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<InvoiceItem> items = new ArrayList<>();

    @OneToMany(mappedBy = "invoice", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<Payment> payments = new ArrayList<>();

    protected Invoice() {}

    public Invoice(long hospitalId, String invoiceNo, long patientId, String patientName, String uhid,
                   Long visitId, Long admissionId, String invoiceType, long subtotalPaise, long discountPaise,
                   String discountReason, long taxPaise, long totalPaise, String notes) {
        super(hospitalId);
        this.invoiceNo = invoiceNo;
        this.patientId = patientId;
        this.patientName = patientName;
        this.uhid = uhid == null ? "" : uhid;
        this.visitId = visitId;
        this.admissionId = admissionId;
        this.invoiceType = invoiceType;
        this.subtotalPaise = subtotalPaise;
        this.discountPaise = discountPaise;
        this.discountReason = discountReason;
        this.taxPaise = taxPaise;
        this.totalPaise = totalPaise;
        this.paidPaise = 0;
        this.duePaise = totalPaise;
        this.status = "issued";
        this.notes = notes;
    }

    public void addItem(InvoiceItem item) {
        items.add(item);
        item.setInvoice(this);
    }

    public void addPayment(Payment payment) {
        payments.add(payment);
        payment.setInvoice(this);
        paidPaise += payment.getAmountPaise();
        duePaise -= payment.getAmountPaise();
        status = duePaise == 0 ? "paid" : "partial";
    }

    public void cancel() {
        if (paidPaise > 0) throw new IllegalStateException("An invoice with payments cannot be cancelled");
        status = "cancelled";
        duePaise = 0;
    }

    public String getInvoiceNo() { return invoiceNo; }
    public long getPatientId() { return patientId; }
    public String getPatientName() { return patientName; }
    public String getUhid() { return uhid; }
    public Long getVisitId() { return visitId; }
    public Long getAdmissionId() { return admissionId; }
    public String getInvoiceType() { return invoiceType; }
    public long getSubtotalPaise() { return subtotalPaise; }
    public long getDiscountPaise() { return discountPaise; }
    public String getDiscountReason() { return discountReason; }
    public long getTaxPaise() { return taxPaise; }
    public long getTotalPaise() { return totalPaise; }
    public long getPaidPaise() { return paidPaise; }
    public long getDuePaise() { return duePaise; }
    public String getStatus() { return status; }
    public String getNotes() { return notes; }
    public List<InvoiceItem> getItems() { return List.copyOf(items); }
    public List<Payment> getPayments() { return List.copyOf(payments); }
}
