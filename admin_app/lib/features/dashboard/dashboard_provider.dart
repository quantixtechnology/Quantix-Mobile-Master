import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardStats {
  final int pendingOrders;
  final int activeRiders;
  final int totalCustomers;
  final double todayRevenue;

  const DashboardStats({
    this.pendingOrders = 0,
    this.activeRiders = 0,
    this.totalCustomers = 0,
    this.todayRevenue = 0,
  });
}

class DashboardNotifier extends Notifier<DashboardStats> {
  @override
  DashboardStats build() => const DashboardStats();
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardStats>(DashboardNotifier.new);
