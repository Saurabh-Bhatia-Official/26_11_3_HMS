package com.caresync.backend.reports.dto;

import java.time.LocalDate;
import java.util.List;

public final class ReportDtos {
    private ReportDtos() {}

    public record Summary(LocalDate from, LocalDate to, long invoiceCount, long revenuePaise,
                          long currentOutstandingPaise, long lowStockMedicineCount, long pendingLabOrderCount,
                          long activeStaffCount) {}
    public record RevenuePoint(LocalDate date, long revenuePaise) {}
    public record StockAlert(long medicineId, String medicineName, int stockQty, int reorderLevel) {}
}
