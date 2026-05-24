class FeatureFlags {
  final List<String> _features;
  final bool _mapEnabled;

  const FeatureFlags(this._features, {bool mapEnabled = false})
      : _mapEnabled = mapEnabled;

  bool get hasCatalog => _features.contains('catalog');
  bool get hasCart => _features.contains('cart');
  bool get hasOrders => _features.contains('orders');
  bool get hasTracking => _features.contains('tracking');
  bool get hasMaps => _mapEnabled && _features.contains('maps');
  bool get hasLoyalty => _features.contains('loyalty');
  bool get hasAppointments => _features.contains('appointments');
  bool get hasSubscriptions => _features.contains('subscriptions');
  bool get hasDelivery => _features.contains('delivery');
  bool get hasNotifications => _features.contains('notifications');

  bool has(String feature) => _features.contains(feature);
}
