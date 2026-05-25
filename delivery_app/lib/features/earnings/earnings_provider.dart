import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class EarningsSummary {
  final double total;
  final int deliveries;
  final bool isLoading;
  final String? error;
  final String period;

  const EarningsSummary({
    this.total = 0,
    this.deliveries = 0,
    this.isLoading = false,
    this.error,
    this.period = 'today',
  });

  EarningsSummary copyWith({
    double? total,
    int? deliveries,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? period,
  }) =>
      EarningsSummary(
        total: total ?? this.total,
        deliveries: deliveries ?? this.deliveries,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        period: period ?? this.period,
      );
}

class EarningsNotifier extends Notifier<EarningsSummary> {
  @override
  EarningsSummary build() {
    _load('today');
    return const EarningsSummary(isLoading: true);
  }

  Future<void> _load(String period) async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .dio
          .get('/earnings', queryParameters: {'period': period});
      final data = res.data as Map<String, dynamic>;
      state = state.copyWith(
        total: (data['total'] as num?)?.toDouble() ?? 0,
        deliveries: data['deliveries'] as int? ?? 0,
        period: period,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setPeriod(String period) {
    state = state.copyWith(period: period, isLoading: true);
    return _load(period);
  }
}

final earningsProvider =
    NotifierProvider<EarningsNotifier, EarningsSummary>(EarningsNotifier.new);
