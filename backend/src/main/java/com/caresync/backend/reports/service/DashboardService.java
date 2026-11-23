package com.caresync.backend.reports.service;

import com.caresync.backend.common.AccessContext;
import com.caresync.backend.billing.repository.InvoiceRepository;
import com.caresync.backend.lab.repository.LabOrderRepository;
import com.caresync.backend.pharmacy.repository.MedicineBatchRepository;
import com.caresync.backend.pharmacy.repository.MedicineRepository;
import com.caresync.backend.reference.AdmissionRepository;
import com.caresync.backend.reference.BedRepository;
import com.caresync.backend.reference.VisitRepository;
import com.caresync.backend.reports.dto.DashboardDtos;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;

@Service
@Transactional(readOnly = true)
public class DashboardService {
    private final AccessContext access;
    private final VisitRepository visits;
    private final InvoiceRepository invoices;
    private final BedRepository beds;
    private final AdmissionRepository admissions;
    private final LabOrderRepository labOrders;
    private final MedicineRepository medicines;
    private final MedicineBatchRepository batches;

    public DashboardService(AccessContext access, VisitRepository visits, InvoiceRepository invoices,
                            BedRepository beds, AdmissionRepository admissions, LabOrderRepository labOrders,
                            MedicineRepository medicines, MedicineBatchRepository batches) {
        this.access = access;
        this.visits = visits;
        this.invoices = invoices;
        this.beds = beds;
        this.admissions = admissions;
        this.labOrders = labOrders;
        this.medicines = medicines;
        this.batches = batches;
    }

    public DashboardDtos.DashboardResponse getDashboardStats(LocalDate targetDate) {
        long hospitalId = access.hospitalId();
        LocalDate today = targetDate == null ? LocalDate.now(ZoneOffset.UTC) : targetDate;
        Instant startOfDay = today.atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant endOfDay = today.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC);

        // 1. Today's OPD Patients (Distinct patients registered for OPD today)
        long todayOpdPatients = visits.countDistinctPatientsByVisitTypeAndDate(hospitalId, "opd", today);
        long todayOpdVisits = visits.countVisitsByVisitTypeAndDate(hospitalId, "opd", today);

        // 2. Today's Revenue (Completed payments today, excluding cancelled invoices)
        long revenuePaise = invoices.sumCompletedPaymentsBetween(hospitalId, startOfDay, endOfDay);
        double todayRevenue = revenuePaise / 100.0;

        // 3. Bed Occupancy
        DashboardDtos.BedOccupancy bedOccupancy = calculateBedOccupancy(hospitalId);
        long currentAdmissions = admissions.countByHospitalIdAndDeletedFalseAndStatusIgnoreCase(hospitalId, "admitted");

        // 4. Pending Lab Tests (Pending, Collected, Processing; excludes Resulted, Verified, Cancelled, Rejected)
        long pendingLabTests = labOrders.countPendingLabOrders(hospitalId);

        // 5. Low Stock Medicines
        long lowStockMedicines = countLowStockMedicines(hospitalId);

        DashboardDtos.DashboardData data = new DashboardDtos.DashboardData(
                todayOpdPatients,
                todayRevenue,
                revenuePaise,
                bedOccupancy,
                pendingLabTests,
                todayOpdVisits,
                todayOpdVisits,
                currentAdmissions,
                lowStockMedicines
        );

        return new DashboardDtos.DashboardResponse(true, data);
    }

    public DashboardDtos.BedOccupancy calculateBedOccupancy() {
        return calculateBedOccupancy(access.hospitalId());
    }

    public DashboardDtos.BedOccupancy calculateBedOccupancy(long hospitalId) {
        long totalBeds = beds.countByHospitalIdAndDeletedFalse(hospitalId);
        long occupiedBeds = beds.countOccupiedBeds(hospitalId);
        long availableBeds = beds.countAvailableBeds(hospitalId);

        if (totalBeds == 0) {
            long activeAdmissions = admissions.countByHospitalIdAndDeletedFalseAndStatusIgnoreCase(hospitalId, "admitted");
            if (activeAdmissions > 0) {
                return new DashboardDtos.BedOccupancy(activeAdmissions, activeAdmissions, 0, 100.0);
            }
            return new DashboardDtos.BedOccupancy(0, 0, 0, 0.0);
        }

        if (availableBeds == 0 && occupiedBeds < totalBeds) {
            availableBeds = Math.max(0, totalBeds - occupiedBeds);
        }

        double occupancyPercentage = totalBeds > 0
                ? Math.round(((double) occupiedBeds / totalBeds) * 1000.0) / 10.0
                : 0.0;

        return new DashboardDtos.BedOccupancy(totalBeds, occupiedBeds, availableBeds, occupancyPercentage);
    }

    public long getTodayOpdPatients(LocalDate targetDate) {
        LocalDate today = targetDate == null ? LocalDate.now(ZoneOffset.UTC) : targetDate;
        return visits.countDistinctPatientsByVisitTypeAndDate(access.hospitalId(), "opd", today);
    }

    public double getTodayRevenue(LocalDate targetDate) {
        LocalDate today = targetDate == null ? LocalDate.now(ZoneOffset.UTC) : targetDate;
        Instant startOfDay = today.atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant endOfDay = today.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        return invoices.sumCompletedPaymentsBetween(access.hospitalId(), startOfDay, endOfDay) / 100.0;
    }

    public long getTodayRevenuePaise(LocalDate targetDate) {
        LocalDate today = targetDate == null ? LocalDate.now(ZoneOffset.UTC) : targetDate;
        Instant startOfDay = today.atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant endOfDay = today.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        return invoices.sumCompletedPaymentsBetween(access.hospitalId(), startOfDay, endOfDay);
    }

    public long getPendingLabTests() {
        return labOrders.countPendingLabOrders(access.hospitalId());
    }

    private long countLowStockMedicines(long hospitalId) {
        java.util.Map<Long, Long> stock = new java.util.HashMap<>();
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        batches.findAllByHospitalIdAndDeletedFalse(hospitalId).stream()
                .filter(batch -> batch.isUnexpiredOn(today))
                .forEach(batch -> stock.merge(batch.getMedicine().getId(), (long) batch.getQuantityOnHand(), Math::addExact));
        return medicines.findAllByHospitalIdAndDeletedFalseOrderByNameAsc(hospitalId).stream()
                .filter(m -> stock.getOrDefault(m.getId(), 0L) <= m.getReorderLevel())
                .count();
    }
}
