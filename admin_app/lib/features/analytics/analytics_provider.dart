import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsData {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final Map<String, double> revenueByDay;

  const AnalyticsData({
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.averageOrderValue = 0,
    this.revenueByDay = const {},
  });
}

class AnalyticsNotifier extends Notifier<AnalyticsData> {
  @override
  AnalyticsData build() => const AnalyticsData();
}

final analyticsProvider =
    NotifierProvider<AnalyticsNotifier, AnalyticsData>(AnalyticsNotifier.new);
