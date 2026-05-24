import 'package:go_router/go_router.dart';
import '../features/auth/login/login_screen.dart';
import '../features/orders/assigned_orders_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/tracking/delivery_map_screen.dart';
import '../features/earnings/earnings_screen.dart';
import '../features/profile/profile_screen.dart';

final deliveryRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const DeliveryLoginScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const AssignedOrdersScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) => DeliveryOrderDetailScreen(
        orderId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/map/:orderId',
      builder: (context, state) => DeliveryMapScreen(
        orderId: state.pathParameters['orderId']!,
      ),
    ),
    GoRoute(
      path: '/earnings',
      builder: (context, state) => const EarningsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const DeliveryProfileScreen(),
    ),
  ],
);
