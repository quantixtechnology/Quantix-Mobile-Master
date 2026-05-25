import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final brandConfig = await BrandLoader.load(appFlavor);

  runApp(
    ProviderScope(
      overrides: [brandConfigProvider.overrideWithValue(brandConfig)],
      child: const QuantixAdminApp(),
    ),
  );
}

class QuantixAdminApp extends ConsumerStatefulWidget {
  const QuantixAdminApp({super.key});

  @override
  ConsumerState<QuantixAdminApp> createState() => _QuantixAdminAppState();
}

class _QuantixAdminAppState extends ConsumerState<QuantixAdminApp> {
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

    ref.listenManual<AuthState>(adminAuthProvider, (prev, next) async {
      if (next.isAuthenticated && next.user != null) {
        final token = await ref.read(secureStorageProvider).getFcmToken();
        if (token != null) {
          try {
            await ref.read(apiClientProvider).dio.post(
              '/users/fcm-token',
              data: {'token': token, 'role': 'admin'},
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
      title: '${brand.appName} Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeFactory.light(brand),
      darkTheme: ThemeFactory.dark(brand),
      routerConfig: router,
    );
  }
}
