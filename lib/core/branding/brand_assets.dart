class BrandAssets {
  final String _flavor;

  const BrandAssets(this._flavor);

  String get logo => 'branding/$_flavor/logo.png';
  String get splash => 'branding/$_flavor/splash.png';
  String get configPath => 'branding/$_flavor/config.json';

  @override
  String toString() => 'BrandAssets(flavor: $_flavor)';
}
