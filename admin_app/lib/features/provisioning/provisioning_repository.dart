import 'package:dio/dio.dart';
import 'tenant_provision_model.dart';

// Base URL of the mobile-provision service.
// Override via --dart-define=PROVISION_URL=https://mobile.quantixtechnology.in
const String _provisionBaseUrl = String.fromEnvironment(
  'PROVISION_URL',
  defaultValue: 'http://localhost:3400',
);

const String _apiKey = String.fromEnvironment(
  'PROVISION_API_KEY',
  defaultValue: '',
);

class ProvisioningRepository {
  late final Dio _dio;

  ProvisioningRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: _provisionBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'X-Api-Key': _apiKey,
      },
    ));
  }

  Future<List<TenantProvision>> listTenants() async {
    final res = await _dio.get<Map<String, dynamic>>('/mobile/tenants');
    final raw = (res.data?['tenants'] as List?) ?? [];
    return raw
        .cast<Map<String, dynamic>>()
        .map(TenantProvision.fromJson)
        .toList();
  }

  Future<TenantProvision> getTenant(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/mobile/tenants/$slug');
    return TenantProvision.fromJson(res.data!);
  }

  Future<Map<String, dynamic>> provisionTenant({
    required String businessId,
    required String slug,
    required String name,
    Map<String, dynamic>? theme,
    String? logo,
    String? businessType,
    String? packageId,
    List<String>? features,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/mobile/provision-tenant',
      data: {
        'businessId': businessId,
        'slug': slug,
        'name': name,
        'theme': theme,
        'logo': logo,
        'businessType': businessType,
        'packageId': packageId,
        'features': features,
      }..removeWhere((_, v) => v == null),
    );
    return res.data ?? {};
  }
}
