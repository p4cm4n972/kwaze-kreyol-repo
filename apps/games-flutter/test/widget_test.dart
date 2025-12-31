import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/main.dart';
import 'package:kwaze_kreyol_games/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize Supabase and mock shared preferences before running tests
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize(
      url: 'https://mock.supabase.co',
      anonKey: 'mock_anon_key',
    );
  });
  testWidgets('GamesHomeScreen shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KwazeKreyolGamesApp());

    // Verify that the title "Nos jeux" is displayed.
    expect(find.text('Nos jeux'), findsOneWidget);
  });
}
