import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class DashboardState {
  final AdminStats? stats;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    AdminStats? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      DashboardState(
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class DashboardNotifier extends Notifier<DashboardState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  DashboardState build() {
    _load();
    return const DashboardState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final stats = await _repo.getStats();
      state = state.copyWith(stats: stats, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
