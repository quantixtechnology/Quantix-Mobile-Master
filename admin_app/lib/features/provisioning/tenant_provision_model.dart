enum BuildStatus {
  pending,
  provisioning,
  building,
  ready,
  failed;

  static BuildStatus fromString(String s) => BuildStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == s.toUpperCase(),
        orElse: () => BuildStatus.pending,
      );

  String get label => switch (this) {
        BuildStatus.pending => 'Pending',
        BuildStatus.provisioning => 'Provisioning',
        BuildStatus.building => 'Building',
        BuildStatus.ready => 'Ready',
        BuildStatus.failed => 'Failed',
      };
}

class TenantProvision {
  final String slug;
  final String businessId;
  final String name;
  final String packageId;
  final BuildStatus status;
  final String brandingStatus;
  final String firebaseStatus;
  final String? repoUrl;
  final String? apkUrl;
  final String? aabUrl;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TenantProvision({
    required this.slug,
    required this.businessId,
    required this.name,
    required this.packageId,
    required this.status,
    required this.brandingStatus,
    required this.firebaseStatus,
    required this.createdAt,
    required this.updatedAt,
    this.repoUrl,
    this.apkUrl,
    this.aabUrl,
    this.error,
  });

  factory TenantProvision.fromJson(Map<String, dynamic> j) => TenantProvision(
        slug: j['slug'] as String,
        businessId: j['businessId'] as String? ?? '',
        name: j['name'] as String? ?? j['slug'] as String,
        packageId: j['packageId'] as String? ?? '',
        status: BuildStatus.fromString(j['status'] as String? ?? 'PENDING'),
        brandingStatus: j['brandingStatus'] as String? ?? 'PENDING',
        firebaseStatus: j['firebaseStatus'] as String? ?? 'STUB',
        repoUrl: j['repoUrl'] as String?,
        apkUrl: j['apkUrl'] as String?,
        aabUrl: j['aabUrl'] as String?,
        error: j['error'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
