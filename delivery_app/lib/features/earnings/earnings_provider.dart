import 'package:flutter_riverpod/flutter_riverpod.dart';

class EarningsSummary {
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final int completedDeliveries;

  const EarningsSummary({
    this.todayEarnings = 0,
    this.weekEarnings = 0,
    this.monthEarnings = 0,
    this.completedDeliveries = 0,
  });
}

class EarningsNotifier extends Notifier<EarningsSummary> {
  @override
  EarningsSummary build() => const EarningsSummary();
}

final earningsProvider =
    NotifierProvider<EarningsNotifier, EarningsSummary>(EarningsNotifier.new);
