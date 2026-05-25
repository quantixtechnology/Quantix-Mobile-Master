import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login/login_screen.dart';
import '../features/orders/assigned_orders_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/tracking/delivery_map_screen.dart';
import '../features/earnings/earnings_screen.dart';
import '../features/profile/profile_screen.dart';

final _routerListenableProvider = Provider<_AuthListenable>((ref) {
  final listenable = _AuthListenable();
  ref.listen<AuthState>(deliveryAuthProvider, (_, _) => listenable.notify());
  ref.onDispose(listenable.dispose);
  return listenable;
});

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(_routerListenableProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(deliveryAuthProvider);
      final loc = state.matchedLocation;
      if (auth.isRestoring) return loc == '/login' ? null : '/login';
      if (!auth.isAuthenticated && loc != '/login') return '/login';
      if (auth.isAuthenticated && loc == '/login') return '/orders';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const DeliveryLoginScreen()),
      GoRoute(path: '/orders', builder: (_, _) => const AssignedOrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) => DeliveryOrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/map/:orderId',
        builder: (_, state) => DeliveryMapScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(path: '/earnings', builder: (_, _) => const EarningsScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const DeliveryProfileScreen()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
