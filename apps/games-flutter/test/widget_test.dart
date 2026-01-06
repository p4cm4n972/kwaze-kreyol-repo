import 'package:flutter_test/flutter_test.dart';
import 'package:kwaze_kreyol_games/main.dart';
import 'package:kwaze_kreyol_games/screens/splash_screen.dart';
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
  testWidgets('App renders SplashScreen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KwazeKreyolGamesApp());

    // Verify that the SplashScreen is displayed (app starts at '/')
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
