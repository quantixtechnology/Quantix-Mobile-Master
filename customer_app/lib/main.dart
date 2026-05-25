import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Firebase.initializeApp() — add google-services.json before enabling

  final brandConfig = await BrandLoader.load(appFlavor);

  runApp(
    ProviderScope(
      overrides: [brandConfigProvider.overrideWithValue(brandConfig)],
      child: const QuantixCustomerApp(),
    ),
  );
}

class QuantixCustomerApp extends ConsumerWidget {
  const QuantixCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeFactory.light(brand),
      darkTheme: ThemeFactory.dark(brand),
      routerConfig: router,
    );
  }
}
