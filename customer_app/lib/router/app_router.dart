import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/otp/otp_screen.dart';
import '../features/auth/register/register_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/dashboard/home_screen.dart';
import '../features/catalog/categories/categories_screen.dart';
import '../features/catalog/product_detail/product_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/history/orders_screen.dart';
import '../features/orders/details/order_detail_screen.dart';
import '../features/orders/tracking/tracking_screen.dart';
import '../features/profile/account/account_screen.dart';
import '../features/profile/addresses/addresses_screen.dart';
import '../features/notifications/notifications_screen.dart';

final _routerListenableProvider = Provider<_AuthListenable>((ref) {
  final listenable = _AuthListenable();
  ref.listen<AuthState>(authProvider, (_, _) => listenable.notify());
  ref.onDispose(listenable.dispose);
  return listenable;
});

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(_routerListenableProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (auth.isRestoring) {
        return loc == '/splash' ? null : '/splash';
      }
      final publicRoutes = {'/splash', '/login', '/otp', '/register'};
      if (!auth.isAuthenticated && !publicRoutes.contains(loc)) return '/login';
      if (auth.requiresOtp && loc != '/otp') return '/otp';
      if (auth.isAuthenticated && publicRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/catalog', builder: (_, _) => const CategoriesScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (_, state) => TrackingScreen(trackingId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/addresses', builder: (_, _) => const AddressesScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
