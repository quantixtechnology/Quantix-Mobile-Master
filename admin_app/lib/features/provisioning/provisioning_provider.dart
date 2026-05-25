import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provisioning_repository.dart';
import 'tenant_provision_model.dart';

// ── Repository singleton ──────────────────────────────────────────────────────
final provisioningRepositoryProvider = Provider<ProvisioningRepository>(
  (_) => ProvisioningRepository(),
);

// ── Tenant list state ─────────────────────────────────────────────────────────
class ProvisioningState {
  final List<TenantProvision> tenants;
  final bool isLoading;
  final String? error;
  final bool serviceAvailable;

  const ProvisioningState({
    this.tenants = const [],
    this.isLoading = false,
    this.error,
    this.serviceAvailable = true,
  });

  ProvisioningState copyWith({
    List<TenantProvision>? tenants,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? serviceAvailable,
  }) =>
      ProvisioningState(
        tenants: tenants ?? this.tenants,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        serviceAvailable: serviceAvailable ?? this.serviceAvailable,
      );
}

class ProvisioningNotifier extends Notifier<ProvisioningState> {
  ProvisioningRepository get _repo => ref.read(provisioningRepositoryProvider);

  @override
  ProvisioningState build() {
    _load();
    return const ProvisioningState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final tenants = await _repo.listTenants();
      state = state.copyWith(
        tenants: tenants,
        isLoading: false,
        clearError: true,
        serviceAvailable: true,
      );
    } catch (e) {
      final msg = e.toString();
      final unavailable = msg.contains('SocketException') ||
          msg.contains('Connection refused') ||
          msg.contains('Failed host lookup');
      state = state.copyWith(
        isLoading: false,
        error: unavailable
            ? 'Provision service unreachable'
            : msg,
        serviceAvailable: !unavailable,
      );
    }
  }

  Future<void> refresh() => _load();

  Future<void> provision({
    required String businessId,
    required String slug,
    required String name,
    String? primaryColor,
    String? accentColor,
    String? businessType,
    String? packageId,
    List<String>? features,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.provisionTenant(
        businessId: businessId,
        slug: slug,
        name: name,
        theme: {
          'primaryColor': primaryColor,
          'accentColor': accentColor,
        }..removeWhere((_, v) => v == null),
        businessType: businessType,
        packageId: packageId,
        features: features,
      );
      await _load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final provisioningProvider =
    NotifierProvider<ProvisioningNotifier, ProvisioningState>(
  ProvisioningNotifier.new,
);
