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

@Entity
@Table(name = "invoice_items")
public class InvoiceItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;

    @Column(name = "item_type", nullable = false, length = 32)
    private String itemType;

    @Column(name = "item_id")
    private Long itemId;

    @Column(nullable = false, length = 240)
    private String description;

    @Column(nullable = false)
    private int qty;

    @Column(name = "unit_price_paise", nullable = false)
    private long unitPricePaise;

    @Column(name = "discount_paise", nullable = false)
    private long discountPaise;

    @Column(name = "tax_rate_pct", nullable = false)
    private double taxRatePct;

    @Column(name = "total_paise", nullable = false)
    private long totalPaise;

    protected InvoiceItem() {}

    public InvoiceItem(String itemType, Long itemId, String description, int qty, long unitPricePaise,
                       long discountPaise, double taxRatePct, long totalPaise) {
        this.itemType = itemType;
        this.itemId = itemId;
        this.description = description;
        this.qty = qty;
        this.unitPricePaise = unitPricePaise;
        this.discountPaise = discountPaise;
        this.taxRatePct = taxRatePct;
        this.totalPaise = totalPaise;
    }

    void setInvoice(Invoice invoice) { this.invoice = invoice; }
    public long getId() { return id; }
    public String getItemType() { return itemType; }
    public Long getItemId() { return itemId; }
    public String getDescription() { return description; }
    public int getQty() { return qty; }
    public long getUnitPricePaise() { return unitPricePaise; }
    public long getDiscountPaise() { return discountPaise; }
    public double getTaxRatePct() { return taxRatePct; }
    public long getTotalPaise() { return totalPaise; }
}
