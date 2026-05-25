import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'tracking_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String trackingId;

  const TrackingScreen({super.key, required this.trackingId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectTracking();
    });
  }

  void _connectTracking() {
    final socket = ref.read(socketServiceProvider);
    socket.subscribe('delivery:location_updated', (data) {
      if (!mounted) return;
      final map = data as Map<String, dynamic>;
      ref.read(trackingProvider.notifier).onLocationUpdated(
            (map['lat'] as num).toDouble(),
            (map['lng'] as num).toDouble(),
          );
    });
    socket.subscribe('tracking:eta_updated', (data) {
      if (!mounted) return;
      final map = data as Map<String, dynamic>;
      ref.read(trackingProvider.notifier).onEtaUpdated(map['eta'] as String);
    });
    socket.subscribe('order:status_changed', (data) {
      if (!mounted) return;
      final map = data as Map<String, dynamic>;
      ref.read(trackingProvider.notifier).onOrderStatusChanged(map['status'] as String);
    });
    socket.send('tracking:subscribe', {'orderId': widget.trackingId});
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(brandConfigProvider);
    final tracking = ref.watch(trackingProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withAlpha(15),
              border: Border.all(color: primary.withAlpha(60)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 12,
                        color: tracking.orderStatus != null
                            ? Colors.green
                            : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      tracking.orderStatus ?? 'Connecting...',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (tracking.eta != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('ETA: ${tracking.eta}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: tracking.driverLocation != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delivery_dining, size: 80, color: primary),
                        const SizedBox(height: 16),
                        Text(
                          'Rider is on the way',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${tracking.driverLocation!.latitude.toStringAsFixed(4)}'
                          '  Lng: ${tracking.driverLocation!.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Waiting for rider location...',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
