import 'dart:convert';

/// Dashboard Key Performance Indicators (KPIs) aggregated model
class DashboardKpiModel {
  final int todayAppointments;
  final int todayOpdVisits;
  final int admittedPatients;
  final int totalBeds;
  final int occupiedBeds;
  final int todayRevenuePaise;
  final int lowStockCount;
  final int pendingLabOrders;

  const DashboardKpiModel({
    this.todayAppointments = 0,
    this.todayOpdVisits = 0,
    this.admittedPatients = 0,
    this.totalBeds = 0,
    this.occupiedBeds = 0,
    this.todayRevenuePaise = 0,
    this.lowStockCount = 0,
    this.pendingLabOrders = 0,
  });

  String get todayRevenueFormatted =>
      '₹${(todayRevenuePaise / 100).toStringAsFixed(0)}';

  int get availableBeds => (totalBeds - occupiedBeds).clamp(0, totalBeds);

  double get bedOccupancyPct =>
      totalBeds > 0 ? (occupiedBeds / totalBeds) * 100 : 0.0;

  factory DashboardKpiModel.fromMap(Map<String, dynamic> map) {
    return DashboardKpiModel(
      todayAppointments: map['todayAppointments'] as int? ?? 0,
      todayOpdVisits: map['todayOpdVisits'] as int? ?? 0,
      admittedPatients: map['admittedPatients'] as int? ?? 0,
      totalBeds: map['totalBeds'] as int? ?? 0,
      occupiedBeds: map['occupiedBeds'] as int? ?? 0,
      todayRevenuePaise: map['todayRevenuePaise'] as int? ?? 0,
      lowStockCount: map['lowStockCount'] as int? ?? 0,
      pendingLabOrders: map['pendingLabOrders'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'todayAppointments': todayAppointments,
        'todayOpdVisits': todayOpdVisits,
        'admittedPatients': admittedPatients,
        'totalBeds': totalBeds,
        'occupiedBeds': occupiedBeds,
        'todayRevenuePaise': todayRevenuePaise,
        'lowStockCount': lowStockCount,
        'pendingLabOrders': pendingLabOrders,
      };

  String toJson() => jsonEncode(toMap());

  factory DashboardKpiModel.fromJson(String source) =>
      DashboardKpiModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Daily Financial collection report breakdown
class DailyRevenueReportModel {
  final String date;
  final int opdRevenuePaise;
  final int ipdRevenuePaise;
  final int pharmacyRevenuePaise;
  final int labRevenuePaise;
  final int totalRevenuePaise;

  const DailyRevenueReportModel({
    required this.date,
    this.opdRevenuePaise = 0,
    this.ipdRevenuePaise = 0,
    this.pharmacyRevenuePaise = 0,
    this.labRevenuePaise = 0,
    this.totalRevenuePaise = 0,
  });

  String get totalFormatted => '₹${(totalRevenuePaise / 100).toStringAsFixed(2)}';

  factory DailyRevenueReportModel.fromMap(Map<String, dynamic> map) {
    return DailyRevenueReportModel(
      date: map['date'] as String? ?? '',
      opdRevenuePaise: map['opd_revenue_paise'] as int? ?? 0,
      ipdRevenuePaise: map['ipd_revenue_paise'] as int? ?? 0,
      pharmacyRevenuePaise: map['pharmacy_revenue_paise'] as int? ?? 0,
      labRevenuePaise: map['lab_revenue_paise'] as int? ?? 0,
      totalRevenuePaise: map['total_revenue_paise'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'opd_revenue_paise': opdRevenuePaise,
        'ipd_revenue_paise': ipdRevenuePaise,
        'pharmacy_revenue_paise': pharmacyRevenuePaise,
        'lab_revenue_paise': labRevenuePaise,
        'total_revenue_paise': totalRevenuePaise,
      };

  String toJson() => jsonEncode(toMap());

  factory DailyRevenueReportModel.fromJson(String source) =>
      DailyRevenueReportModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Ward occupancy statistic summary
class WardOccupancyReportModel {
  final String wardName;
  final int totalBeds;
  final int occupiedBeds;

  const WardOccupancyReportModel({
    required this.wardName,
    required this.totalBeds,
    required this.occupiedBeds,
  });

  int get availableBeds => (totalBeds - occupiedBeds).clamp(0, totalBeds);
  double get occupancyRatePct =>
      totalBeds > 0 ? (occupiedBeds / totalBeds) * 100 : 0.0;

  factory WardOccupancyReportModel.fromMap(Map<String, dynamic> map) {
    return WardOccupancyReportModel(
      wardName: map['ward_name'] as String? ?? '',
      totalBeds: map['total_beds'] as int? ?? 0,
      occupiedBeds: map['occupied_beds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'ward_name': wardName,
        'total_beds': totalBeds,
        'occupied_beds': occupiedBeds,
      };

  String toJson() => jsonEncode(toMap());

  factory WardOccupancyReportModel.fromJson(String source) =>
      WardOccupancyReportModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Department workload breakdown model
class DepartmentWorkloadModel {
  final String department;
  final int opdVisits;
  final int appointments;
  final int admittedPatients;
  final int revenuePaise;

  const DepartmentWorkloadModel({
    required this.department,
    this.opdVisits = 0,
    this.appointments = 0,
    this.admittedPatients = 0,
    this.revenuePaise = 0,
  });

  String get revenueFormatted => '₹${(revenuePaise / 100).toStringAsFixed(0)}';

  factory DepartmentWorkloadModel.fromMap(Map<String, dynamic> map) {
    return DepartmentWorkloadModel(
      department: map['department'] as String? ?? '',
      opdVisits: map['opd_visits'] as int? ?? 0,
      appointments: map['appointments'] as int? ?? 0,
      admittedPatients: map['admitted_patients'] as int? ?? 0,
      revenuePaise: map['revenue_paise'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'department': department,
        'opd_visits': opdVisits,
        'appointments': appointments,
        'admitted_patients': admittedPatients,
        'revenue_paise': revenuePaise,
      };

  String toJson() => jsonEncode(toMap());

  factory DepartmentWorkloadModel.fromJson(String source) =>
      DepartmentWorkloadModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

