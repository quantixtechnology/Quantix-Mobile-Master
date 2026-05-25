import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'live_tracking_provider.dart';

class DeliveryMapScreen extends ConsumerStatefulWidget {
  final String orderId;

  const DeliveryMapScreen({super.key, required this.orderId});

  @override
  ConsumerState<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends ConsumerState<DeliveryMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveTrackingProvider.notifier).startBroadcasting(widget.orderId);
    });
  }

  @override
  void dispose() {
    ref.read(liveTrackingProvider.notifier).stopBroadcasting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(brandConfigProvider);
    final tracking = ref.watch(liveTrackingProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate — #${widget.orderId.substring(0, 8)}'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: tracking.isBroadcasting
                ? Colors.green.shade50
                : Colors.grey.shade100,
            child: Row(
              children: [
                Icon(
                  tracking.isBroadcasting ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: tracking.isBroadcasting ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  tracking.isBroadcasting
                      ? 'Broadcasting location to customer'
                      : 'Location not broadcasting',
                  style: TextStyle(
                    color: tracking.isBroadcasting
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 80, color: primaryColor(primary)),
                    const SizedBox(height: 16),
                    Text(
                      'Map View',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (tracking.currentLocation != null)
                      Text(
                        'Lat: ${tracking.currentLocation!.latitude.toStringAsFixed(4)}'
                        '  Lng: ${tracking.currentLocation!.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      )
                    else
                      const Text('Waiting for GPS signal...',
                          style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: tracking.isBroadcasting
                    ? OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(liveTrackingProvider.notifier).stopBroadcasting(),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Stop Broadcasting'),
                      )
                    : FilledButton.icon(
                        onPressed: () => ref
                            .read(liveTrackingProvider.notifier)
                            .startBroadcasting(widget.orderId),
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('Start Broadcasting'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color primaryColor(Color primary) => primary;
}
