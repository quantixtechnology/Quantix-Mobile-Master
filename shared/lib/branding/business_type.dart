enum BusinessType {
  meat,
  grocery,
  salon,
  restaurant,
  generic;

  static BusinessType fromString(String value) => BusinessType.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => BusinessType.generic,
      );
}

class BusinessModuleResolver {
  static List<String> defaultFeaturesFor(BusinessType type) => switch (type) {
        BusinessType.meat => ['catalog', 'cart', 'orders', 'tracking', 'loyalty', 'delivery'],
        BusinessType.grocery => ['catalog', 'cart', 'orders', 'tracking', 'loyalty', 'delivery', 'subscriptions'],
        BusinessType.salon => ['catalog', 'appointments', 'notifications'],
        BusinessType.restaurant => ['catalog', 'cart', 'orders', 'tracking', 'delivery'],
        BusinessType.generic => ['catalog', 'cart', 'orders'],
      };

  static bool supportsTracking(BusinessType type) => type != BusinessType.salon;
  static bool supportsAppointments(BusinessType type) => type == BusinessType.salon;
  static bool supportsCart(BusinessType type) => type != BusinessType.salon;
}
