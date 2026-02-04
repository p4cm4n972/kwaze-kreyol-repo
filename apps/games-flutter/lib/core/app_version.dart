/// Version de l'application
/// Mis à jour automatiquement via le hook pre-push
class AppVersion {
  static const String version = '1.0.0';
  static const String stage = 'beta.1';
  static const int patchNumber = 4;

  /// Version complète formatée pour l'affichage
  static String get fullVersion => 'Beta 1.004';

  /// Version courte
  static String get shortVersion => version;

  /// Version sémantique complète
  static String get semver => '$version-$stage+$patchNumber';
}
