package com.caresync.backend.reports.service;

import com.caresync.backend.billing.entity.Payment;
import com.caresync.backend.billing.repository.InvoiceRepository;
import com.caresync.backend.common.AccessContext;
import com.caresync.backend.common.BusinessException;
import com.caresync.backend.lab.repository.LabOrderRepository;
import com.caresync.backend.pharmacy.entity.Medicine;
import com.caresync.backend.pharmacy.repository.MedicineBatchRepository;
import com.caresync.backend.pharmacy.repository.MedicineRepository;
import com.caresync.backend.reports.dto.ReportDtos;
import com.caresync.backend.staff.repository.StaffRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@Transactional(readOnly = true)
public class ReportService {
    private static final List<String> OPEN_LAB_STATUSES = List.of("pending", "collected", "processing", "resulted");
    private final AccessContext access;
    private final InvoiceRepository invoices;
    private final LabOrderRepository labOrders;
    private final MedicineRepository medicines;
    private final MedicineBatchRepository batches;
    private final StaffRepository staff;

    public ReportService(AccessContext access, InvoiceRepository invoices, LabOrderRepository labOrders,
                         MedicineRepository medicines, MedicineBatchRepository batches, StaffRepository staff) {
        this.access = access;
        this.invoices = invoices;
        this.labOrders = labOrders;
        this.medicines = medicines;
        this.batches = batches;
        this.staff = staff;
    }

    public ReportDtos.Summary summary(LocalDate from, LocalDate to) {
        DateRange range = range(from, to);
        long hospitalId = access.hospitalId();
        long revenue = invoices.paymentsBetween(hospitalId, range.start(), range.end()).stream()
                .mapToLong(Payment::getAmountPaise).sum();
        long invoiceCount = invoices.countByHospitalIdAndDeletedFalseAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                hospitalId, range.start(), range.end());
        return new ReportDtos.Summary(range.from(), range.to(), invoiceCount, revenue,
                invoices.sumOutstanding(hospitalId), stockAlerts(hospitalId).size(),
                labOrders.countByHospitalIdAndDeletedFalseAndStatusIn(hospitalId, OPEN_LAB_STATUSES),
                staff.countByHospitalIdAndActiveTrueAndDeletedFalse(hospitalId));
    }

    public List<ReportDtos.RevenuePoint> revenue(LocalDate from, LocalDate to) {
        DateRange range = range(from, to);
        Map<LocalDate, Long> totals = new HashMap<>();
        for (Payment payment : invoices.paymentsBetween(access.hospitalId(), range.start(), range.end())) {
            LocalDate date = payment.getPaidAt().atZone(ZoneOffset.UTC).toLocalDate();
            totals.merge(date, payment.getAmountPaise(), Math::addExact);
        }
        List<ReportDtos.RevenuePoint> result = new ArrayList<>();
        for (LocalDate day = range.from(); !day.isAfter(range.to()); day = day.plusDays(1)) {
            result.add(new ReportDtos.RevenuePoint(day, totals.getOrDefault(day, 0L)));
        }
        return result;
    }

    public List<ReportDtos.StockAlert> stockAlerts() {
        return stockAlerts(access.hospitalId());
    }

    private List<ReportDtos.StockAlert> stockAlerts(long hospitalId) {
        Map<Long, Long> stock = new HashMap<>();
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        batches.findAllByHospitalIdAndDeletedFalse(hospitalId).stream()
                .filter(batch -> !batch.getExpiryDate().isBefore(today))
                .forEach(batch -> stock.merge(batch.getMedicine().getId(), (long) batch.getQuantityOnHand(), Math::addExact));
        return medicines.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(hospitalId).stream()
                .map(medicine -> stockAlert(medicine, stock.getOrDefault(medicine.getId(), 0L)))
                .filter(alert -> alert.stockQty() <= alert.reorderLevel()).toList();
    }

    private static ReportDtos.StockAlert stockAlert(Medicine medicine, long qty) {
        return new ReportDtos.StockAlert(medicine.getId(), medicine.getName(),
                Math.toIntExact(Math.min(qty, Integer.MAX_VALUE)), medicine.getReorderLevel());
    }

    private static DateRange range(LocalDate from, LocalDate to) {
        LocalDate end = to == null ? LocalDate.now(ZoneOffset.UTC) : to;
        LocalDate start = from == null ? end : from;
        if (start.isAfter(end)) throw BusinessException.invalid("The start date must not be after the end date");
        if (start.plusDays(365).isBefore(end)) throw BusinessException.invalid("Report date range cannot exceed 366 days");
        return new DateRange(start, end, start.atStartOfDay().toInstant(ZoneOffset.UTC),
                end.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC));
    }

    private record DateRange(LocalDate from, LocalDate to, Instant start, Instant end) {}
}
