import 'package:freezed_annotation/freezed_annotation.dart';

part 'brand_config.freezed.dart';
part 'brand_config.g.dart';

@freezed
class BrandConfig with _$BrandConfig {
  const factory BrandConfig({
    required String appName,
    required String businessId,
    required String packageName,
    required String primaryColor,
    required String secondaryColor,
    required String accentColor,
    required String businessType,
    required String currency,
    @Default(false) bool mapEnabled,
    @Default(true) bool notificationsEnabled,
    @Default([]) List<String> features,
    String? supportPhone,
    String? logo,
    String? splash,
  }) = _BrandConfig;

  factory BrandConfig.fromJson(Map<String, dynamic> json) =>
      _$BrandConfigFromJson(json);
}
