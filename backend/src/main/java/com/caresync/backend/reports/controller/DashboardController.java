package com.caresync.backend.reports.controller;

import com.caresync.backend.reports.dto.DashboardDtos;
import com.caresync.backend.reports.service.DashboardService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.Map;

@RestController
@RequestMapping({"/api/reports/dashboard", "/api/dashboard"})
public class DashboardController {
    private final DashboardService service;

    public DashboardController(DashboardService service) {
        this.service = service;
    }

    @GetMapping({"", "/stats"})
    public DashboardDtos.DashboardResponse getDashboardStats(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return service.getDashboardStats(date);
    }

    @GetMapping("/today-opd-patients")
    public DashboardDtos.SingleMetricResponse<Map<String, Object>> getTodayOpdPatients(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        long count = service.getTodayOpdPatients(date);
        return new DashboardDtos.SingleMetricResponse<>(true, Map.of(
                "todayOpdPatients", count,
                "date", (date != null ? date : LocalDate.now()).toString()
        ));
    }

    @GetMapping("/today-revenue")
    public DashboardDtos.SingleMetricResponse<Map<String, Object>> getTodayRevenue(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        double revenue = service.getTodayRevenue(date);
        long revenuePaise = service.getTodayRevenuePaise(date);
        return new DashboardDtos.SingleMetricResponse<>(true, Map.of(
                "todayRevenue", revenue,
                "todayRevenuePaise", revenuePaise,
                "currency", "INR",
                "currencySymbol", "₹",
                "date", (date != null ? date : LocalDate.now()).toString()
        ));
    }

    @GetMapping("/bed-occupancy")
    public DashboardDtos.SingleMetricResponse<DashboardDtos.BedOccupancy> getBedOccupancy() {
        return new DashboardDtos.SingleMetricResponse<>(true, service.calculateBedOccupancy());
    }

    @GetMapping("/pending-lab-tests")
    public DashboardDtos.SingleMetricResponse<Map<String, Object>> getPendingLabTests() {
        long count = service.getPendingLabTests();
        return new DashboardDtos.SingleMetricResponse<>(true, Map.of(
                "pendingLabTests", count
        ));
    }
}
