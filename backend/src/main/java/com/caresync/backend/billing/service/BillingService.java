package com.caresync.backend.billing.service;

import com.caresync.backend.billing.dto.BillingDtos;
import com.caresync.backend.billing.entity.BillableService;
import com.caresync.backend.billing.entity.Invoice;
import com.caresync.backend.billing.entity.InvoiceItem;
import com.caresync.backend.billing.entity.Payment;
import com.caresync.backend.billing.repository.BillableServiceRepository;
import com.caresync.backend.billing.repository.InvoiceRepository;
import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class BillingService {
    private final AccessContext access;
    private final BillableServiceRepository services;
    private final InvoiceRepository invoices;

    public BillingService(AccessContext access, BillableServiceRepository services, InvoiceRepository invoices) {
        this.access = access;
        this.services = services;
        this.invoices = invoices;
    }

    @Transactional(readOnly = true)
    public List<BillingDtos.ServiceResponse> services() {
        return services.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(access.hospitalId())
                .stream().map(BillingService::serviceResponse).toList();
    }

    public BillingDtos.ServiceResponse createService(BillingDtos.ServiceRequest request) {
        BillableService service = new BillableService(access.hospitalId(), request.name().trim(),
                request.category(), request.pricePaise(), request.taxRatePct(), !Boolean.FALSE.equals(request.active()));
        return serviceResponse(services.save(service));
    }

    public BillingDtos.ServiceResponse updateService(long id, BillingDtos.ServiceRequest request) {
        BillableService service = services.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Service"));
        service.update(request.name().trim(), request.category(), request.pricePaise(), request.taxRatePct(),
                !Boolean.FALSE.equals(request.active()));
        return serviceResponse(service);
    }

    @Transactional(readOnly = true)
    public List<BillingDtos.InvoiceResponse> invoices() {
        return invoices.findAllByHospitalIdAndDeletedFalseOrderByCreatedAtDesc(access.hospitalId())
                .stream().map(BillingService::invoiceResponse).toList();
    }

    @Transactional(readOnly = true)
    public BillingDtos.InvoiceResponse invoice(long id) {
        return invoiceResponse(findInvoice(id));
    }

    public BillingDtos.InvoiceResponse createInvoice(BillingDtos.InvoiceRequest request) {
        long hospitalId = access.hospitalId();
        long subtotal = 0;
        long tax = 0;
        long itemsTotal = 0;
        for (BillingDtos.InvoiceItemRequest item : request.items()) {
            long base = Math.multiplyExact(item.unitPricePaise(), item.qty());
            if (item.discountPaise() > base) throw BusinessException.invalid("Item discount exceeds item value");
            long discounted = base - item.discountPaise();
            long itemTax = percent(discounted, item.taxRatePct());
            subtotal = Math.addExact(subtotal, base);
            tax = Math.addExact(tax, itemTax);
            itemsTotal = Math.addExact(itemsTotal, Math.addExact(discounted, itemTax));
        }
        if (request.discountPaise() > Math.addExact(subtotal, tax)) {
            throw BusinessException.invalid("Invoice discount exceeds invoice value");
        }
        long total = Math.subtractExact(itemsTotal, request.discountPaise());
        String invoiceNo = "INV-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase();
        Invoice invoice = new Invoice(hospitalId, invoiceNo, request.patientId(), request.patientName().trim(),
                request.uhid(), request.visitId(), request.admissionId(), request.invoiceType(), subtotal,
                request.discountPaise(), request.discountReason(), tax, total, request.notes());
        for (BillingDtos.InvoiceItemRequest item : request.items()) {
            long base = Math.multiplyExact(item.unitPricePaise(), item.qty());
            long discounted = base - item.discountPaise();
            long itemTax = percent(discounted, item.taxRatePct());
            invoice.addItem(new InvoiceItem(item.itemType(), item.itemId(), item.description().trim(), item.qty(),
                    item.unitPricePaise(), item.discountPaise(), item.taxRatePct(),
                    Math.addExact(discounted, itemTax)));
        }
        return invoiceResponse(invoices.save(invoice));
    }

    public BillingDtos.InvoiceResponse addPayment(long invoiceId, BillingDtos.PaymentRequest request) {
        Invoice invoice = invoices.findForUpdate(invoiceId, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Invoice"));
        if (invoice.getStatus().equals("cancelled")) throw BusinessException.conflict("Cancelled invoices cannot be paid");
        if (request.amountPaise() > invoice.getDuePaise()) {
            throw BusinessException.invalid("Payment exceeds the invoice balance");
        }
        invoice.addPayment(new Payment(request.paymentMode(), request.amountPaise(), request.referenceNo(),
                access.userId()));
        invoices.flush();
        return invoiceResponse(invoice);
    }

    public void cancelInvoice(long invoiceId) {
        Invoice invoice = invoices.findForUpdate(invoiceId, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Invoice"));
        try {
            invoice.cancel();
        } catch (IllegalStateException exception) {
            throw BusinessException.conflict(exception.getMessage());
        }
    }

    private Invoice findInvoice(long id) {
        return invoices.findByIdAndHospitalIdAndDeletedFalse(id, access.hospitalId())
                .orElseThrow(() -> BusinessException.notFound("Invoice"));
    }

    private static long percent(long amount, double percentage) {
        return BigDecimal.valueOf(amount).multiply(BigDecimal.valueOf(percentage))
                .divide(BigDecimal.valueOf(100), 0, RoundingMode.HALF_UP).longValueExact();
    }

    private static BillingDtos.ServiceResponse serviceResponse(BillableService service) {
        return new BillingDtos.ServiceResponse(service.getId(), service.getUuid(), service.getName(),
                service.getCategory(), service.getPricePaise(), service.getTaxRatePct(), service.isActive(),
                service.getCreatedAt(), service.getUpdatedAt());
    }

    private static BillingDtos.InvoiceResponse invoiceResponse(Invoice invoice) {
        List<BillingDtos.InvoiceItemResponse> items = invoice.getItems().stream()
                .map(item -> new BillingDtos.InvoiceItemResponse(item.getId(), item.getItemType(), item.getItemId(),
                        item.getDescription(), item.getQty(), item.getUnitPricePaise(), item.getDiscountPaise(),
                        item.getTaxRatePct(), item.getTotalPaise())).toList();
        List<BillingDtos.PaymentResponse> payments = invoice.getPayments().stream()
                .map(payment -> new BillingDtos.PaymentResponse(payment.getId(), payment.getPaymentMode(),
                        payment.getAmountPaise(), payment.getReferenceNo(), payment.getReceivedBy(),
                        payment.getPaidAt())).toList();
        return new BillingDtos.InvoiceResponse(invoice.getId(), invoice.getUuid(), invoice.getInvoiceNo(),
                invoice.getPatientId(), invoice.getPatientName(), invoice.getUhid(), invoice.getVisitId(),
                invoice.getAdmissionId(), invoice.getInvoiceType(), invoice.getSubtotalPaise(),
                invoice.getDiscountPaise(), invoice.getDiscountReason(), invoice.getTaxPaise(),
                invoice.getTotalPaise(), invoice.getPaidPaise(), invoice.getDuePaise(), invoice.getStatus(),
                invoice.getNotes(), invoice.getCreatedAt(), invoice.getUpdatedAt(), items, payments);
    }
}
