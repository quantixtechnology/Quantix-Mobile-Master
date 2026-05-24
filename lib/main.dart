import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/branding/brand_loader.dart';
import 'core/branding/brand_provider.dart';
import 'core/branding/theme_factory.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Firebase.initializeApp() — add google-services.json / GoogleService-Info.plist before enabling

  final brandConfig = await BrandLoader.load(appFlavor);

  runApp(
    ProviderScope(
      overrides: [
        brandConfigProvider.overrideWithValue(brandConfig),
      ],
      child: const QuantixApp(),
    ),
  );
}

class QuantixApp extends ConsumerWidget {
  const QuantixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    return MaterialApp.router(
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeFactory.light(brand),
      darkTheme: ThemeFactory.dark(brand),
      routerConfig: appRouter,
    );
  }
}
