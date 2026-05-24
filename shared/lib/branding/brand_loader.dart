import 'dart:convert';
import 'package:flutter/services.dart';
import 'brand_config.dart';

class BrandLoader {
  static Future<BrandConfig> load(String flavor) async {
    try {
      final jsonString = await rootBundle.loadString('branding/$flavor/config.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return BrandConfig.fromJson(json);
    } catch (_) {
      return _fallback(flavor);
    }
  }

  static BrandConfig _fallback(String flavor) => BrandConfig(
        appName: 'Quantix App',
        businessId: flavor.toUpperCase(),
        packageName: 'com.quantix.$flavor',
        primaryColor: '#00B14F',
        secondaryColor: '#FFFFFF',
        accentColor: '#FF6B00',
        businessType: 'generic',
        currency: 'PKR',
        mapEnabled: true,
        notificationsEnabled: true,
        features: const ['catalog', 'cart', 'orders'],
      );
}
