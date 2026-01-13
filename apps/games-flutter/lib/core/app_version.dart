/// Version de l'application
class AppVersion {
  static const String version = '1.0.0';
  static const String stage = 'beta.1';

  /// Version complète formatée pour l'affichage
  static String get fullVersion => 'Beta 1.000';

  /// Version courte
  static String get shortVersion => version;

  /// Version sémantique complète
  static String get semver => '$version-$stage';
}
