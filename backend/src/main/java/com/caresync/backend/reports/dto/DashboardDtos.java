package com.caresync.backend.reports.dto;

import java.time.LocalDate;

public final class DashboardDtos {
    private DashboardDtos() {}

    public record DashboardResponse(
            boolean success,
            DashboardData data
    ) {}

    public record DashboardData(
            long todayOpdPatients,
            double todayRevenue,
            long todayRevenuePaise,
            BedOccupancy bedOccupancy,
            long pendingLabTests,
            long todayOpdVisits,
            long todayAppointments,
            long currentAdmissions,
            long lowStockMedicines
    ) {}

    public record BedOccupancy(
            long totalBeds,
            long occupiedBeds,
            long availableBeds,
            double occupancyPercentage
    ) {}

    public record SingleMetricResponse<T>(
            boolean success,
            T data
    ) {}
}
