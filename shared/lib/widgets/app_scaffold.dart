import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../branding/brand_provider.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool showBrandLogo;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = true,
    this.showBrandLogo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(brandAssetsProvider);

    Widget titleWidget = showBrandLogo
        ? _BrandLogoTitle(logoPath: assets.logo, fallback: title)
        : Text(title);

    return Scaffold(
      appBar: AppBar(
        title: titleWidget,
        actions: actions,
        automaticallyImplyLeading: showBackButton,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class FeatureGuard extends ConsumerWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;

  const FeatureGuard({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    if (flags.has(feature)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

class _BrandLogoTitle extends StatelessWidget {
  final String logoPath;
  final String fallback;

  const _BrandLogoTitle({required this.logoPath, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      logoPath,
      height: 32,
      errorBuilder: (context, error, stack) => Text(fallback),
    );
  }
}
