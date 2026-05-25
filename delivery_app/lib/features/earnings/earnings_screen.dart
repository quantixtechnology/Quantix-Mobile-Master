import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'earnings_provider.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final earnings = ref.watch(earningsProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings')),
      body: earnings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(earningsProvider.notifier).setPeriod(earnings.period),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: primary,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text('Total Earnings',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            'PKR ${earnings.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${earnings.deliveries} deliveries',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: ['today', 'week', 'month'].map((period) {
                      final selected = earnings.period == period;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              period[0].toUpperCase() + period.substring(1),
                              style: TextStyle(
                                color: selected ? Colors.white : null,
                              ),
                            ),
                            selected: selected,
                            selectedColor: primary,
                            onSelected: (_) =>
                                ref.read(earningsProvider.notifier).setPeriod(period),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (earnings.error != null)
                    Center(
                      child: Text(earnings.error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
    );
  }
}
