/// Version de l'application
/// Le numéro correspond au nombre de commits git
/// Mis à jour via le script update_version.sh avant chaque push
class AppVersion {
  static const int commitCount = 200;

  /// Version complète formatée pour l'affichage
  static String get fullVersion => 'Beta 0.$commitCount';

  /// Version courte
  static String get shortVersion => '0.$commitCount';
}
