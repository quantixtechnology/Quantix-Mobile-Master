import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'features/auth/auth_provider.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await openCartBox();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Route all Flutter errors to Crashlytics in release mode
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Register background message handler before ProviderScope starts
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final brandConfig = await BrandLoader.load(appFlavor);

  runApp(
    ProviderScope(
      overrides: [brandConfigProvider.overrideWithValue(brandConfig)],
      child: const QuantixCustomerApp(),
    ),
  );
}

class QuantixCustomerApp extends ConsumerStatefulWidget {
  const QuantixCustomerApp({super.key});

  @override
  ConsumerState<QuantixCustomerApp> createState() => _QuantixCustomerAppState();
}

class _QuantixCustomerAppState extends ConsumerState<QuantixCustomerApp> {
  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    final fcm = ref.read(fcmServiceProvider);
    await fcm.init(
      router: (route, data) {
        if (route != null) {
          final router = ref.read(routerProvider);
          router.go(route);
        }
      },
    );

    // Register FCM token with backend once user is authenticated
    ref.listenManual<AuthState>(authProvider, (prev, next) async {
      if (next.isAuthenticated && next.user != null) {
        final token = await ref.read(secureStorageProvider).getFcmToken();
        if (token != null) {
          try {
            await ref.read(apiClientProvider).dio.post(
              '/users/fcm-token',
              data: {'token': token},
            );
          } catch (_) {}
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
