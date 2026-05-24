import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'brand_config.dart';
import 'brand_assets.dart';
import 'feature_flags.dart';

const appFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'freshmart');

final brandConfigProvider = Provider<BrandConfig>((ref) {
  throw UnimplementedError('brandConfigProvider must be overridden in ProviderScope');
});

final brandFlavorProvider = Provider<String>((ref) => appFlavor);

final brandAssetsProvider = Provider<BrandAssets>((ref) {
  final flavor = ref.watch(brandFlavorProvider);
  return BrandAssets(flavor);
});

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  final brand = ref.watch(brandConfigProvider);
  return FeatureFlags(brand.features, mapEnabled: brand.mapEnabled);
});
