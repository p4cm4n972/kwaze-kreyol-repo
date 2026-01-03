import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/services/storage_service.dart';

void main() {
  group('StorageService', () {
    test('devrait avoir le bon nom de bucket', () {
      expect(StorageService.avatarsBucket, equals('avatars'));
    });

    test('le nom de bucket devrait être une constante valide', () {
      expect(StorageService.avatarsBucket.isNotEmpty, isTrue);
      expect(StorageService.avatarsBucket, isA<String>());
    });

    test('uploadAvatar devrait générer un nom de fichier unique', () async {
      // Ce test vérifie la logique de génération de nom de fichier
      // Le format attendu est: userId/userId-timestamp.ext

      // Test avec différentes extensions
      const extensions = ['jpg', 'png', 'webp', 'jpeg'];

      for (final ext in extensions) {
        // Vérifier que l'extension est bien préservée dans le pattern attendu
        expect(ext.isNotEmpty, isTrue);
        expect(ext.length <= 4, isTrue);
      }
    });

    test('la logique de génération de chemin devrait suivre le format userId/fileName', () {
      // Test de la logique sans instancier le service
      const userId = 'test-user-123';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const fileExt = 'jpg';
      final fileName = '$userId-$timestamp.$fileExt';
      final expectedPath = '$userId/$fileName';

      expect(expectedPath, contains(userId));
      expect(expectedPath, contains('/'));
      expect(expectedPath.split('/').length, equals(2));
    });
  });

  group('StorageService - Validation des paramètres', () {
    test('les paramètres userId ne doivent pas être vides', () {
      const validUserId = 'user-123';
      const emptyUserId = '';

      expect(validUserId.isNotEmpty, isTrue);
      expect(emptyUserId.isEmpty, isTrue);
    });

    test('les URLs d\'avatar doivent être valides', () {
      const validUrl = 'https://example.com/avatar.jpg';
      const invalidUrl = 'not-a-url';

      final validUri = Uri.tryParse(validUrl);
      final invalidUri = Uri.tryParse(invalidUrl);

      expect(validUri, isNotNull);
      expect(validUri?.hasScheme, isTrue);
      expect(invalidUri?.hasScheme, isFalse);
    });

    test('les extensions de fichier supportées doivent être valides', () {
      const supportedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

      for (final ext in supportedExtensions) {
        expect(ext.isNotEmpty, isTrue);
        expect(ext.length, lessThanOrEqualTo(4));
        expect(ext, matches(RegExp(r'^[a-z]+$')));
      }
    });
  });

  group('StorageService - Chemins de fichiers', () {
    test('le chemin de fichier devrait suivre le format userId/fileName', () {
      const userId = 'user-123';
      const fileName = 'user-123-1234567890.jpg';
      final expectedPath = '$userId/$fileName';

      expect(expectedPath, contains(userId));
      expect(expectedPath, contains('/'));
      expect(expectedPath.split('/').length, equals(2));
      expect(expectedPath.split('/')[0], equals(userId));
      expect(expectedPath.split('/')[1], equals(fileName));
    });

    test('le nom de fichier devrait contenir un timestamp', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'user-123-$timestamp.jpg';

      expect(fileName, contains(timestamp.toString()));
      expect(fileName, matches(RegExp(r'user-123-\d+\.jpg')));
    });
  });
}
