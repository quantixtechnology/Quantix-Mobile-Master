import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/delivery/delivery_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/provisioning/provisioning_screen.dart';

final _routerListenableProvider = Provider<_AuthListenable>((ref) {
  final listenable = _AuthListenable();
  ref.listen<AuthState>(adminAuthProvider, (_, _) => listenable.notify());
  ref.onDispose(listenable.dispose);
  return listenable;
});

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(_routerListenableProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(adminAuthProvider);
      final loc = state.matchedLocation;
      if (auth.isRestoring) return loc == '/login' ? null : '/login';
      if (!auth.isAuthenticated && loc != '/login') return '/login';
      if (auth.isAuthenticated && loc == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const AdminLoginScreen()),
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/orders', builder: (_, _) => const AdminOrdersScreen()),
      GoRoute(path: '/inventory', builder: (_, _) => const InventoryScreen()),
      GoRoute(path: '/customers', builder: (_, _) => const CustomersScreen()),
      GoRoute(path: '/delivery', builder: (_, _) => const DeliveryManagementScreen()),
      GoRoute(path: '/analytics', builder: (_, _) => const AnalyticsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const AdminSettingsScreen()),
      GoRoute(path: '/mobile', builder: (_, _) => const ProvisioningScreen()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
