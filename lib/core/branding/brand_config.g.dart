// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BrandConfigImpl _$$BrandConfigImplFromJson(Map<String, dynamic> json) =>
    _$BrandConfigImpl(
      appName: json['appName'] as String,
      businessId: json['businessId'] as String,
      packageName: json['packageName'] as String,
      primaryColor: json['primaryColor'] as String,
      secondaryColor: json['secondaryColor'] as String,
      accentColor: json['accentColor'] as String,
      businessType: json['businessType'] as String,
      currency: json['currency'] as String,
      mapEnabled: json['mapEnabled'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      supportPhone: json['supportPhone'] as String?,
      logo: json['logo'] as String?,
      splash: json['splash'] as String?,
    );

Map<String, dynamic> _$$BrandConfigImplToJson(_$BrandConfigImpl instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'businessId': instance.businessId,
      'packageName': instance.packageName,
      'primaryColor': instance.primaryColor,
      'secondaryColor': instance.secondaryColor,
      'accentColor': instance.accentColor,
      'businessType': instance.businessType,
      'currency': instance.currency,
      'mapEnabled': instance.mapEnabled,
      'notificationsEnabled': instance.notificationsEnabled,
      'features': instance.features,
      'supportPhone': instance.supportPhone,
      'logo': instance.logo,
      'splash': instance.splash,
    };
