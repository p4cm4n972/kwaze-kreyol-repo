import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/games_home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/friends_list_screen.dart';
import 'screens/add_friend_screen.dart';
import 'screens/email_invitation_screen.dart';
import 'games/mots_mawon/mots_mawon_screen.dart';
import 'games/mots_mawon/screens/mots_mawon_leaderboard_screen.dart';
import 'games/skrabb/skrabb_screen.dart';
import 'tools/met_double/screens/met_double_home_screen.dart';
import 'tools/met_double/screens/met_double_general_stats_screen.dart';
import 'tools/translator/screens/translator_screen.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await SupabaseService.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const KwazeKreyolGamesApp());
}

class KwazeKreyolGamesApp extends StatelessWidget {
  const KwazeKreyolGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kwazé Kréyol Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700), // madras-yellow
          primary: const Color(0xFFFFD700),
          secondary: const Color(0xFFFF0000), // madras-red
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const GamesHomeScreen()),
    GoRoute(
      path: '/auth',
      builder: (context, state) => AuthScreen(
        onSuccess: () {
          // Callback après connexion réussie
        },
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => AuthScreen(
        onSuccess: () {
          // Callback après connexion réussie
        },
      ),
    ),
    GoRoute(
      path: '/mots-mawon',
      builder: (context, state) => const MotsMawonScreen(),
    ),
    GoRoute(
      path: '/mots-mawon/leaderboard',
      builder: (context, state) => const MotsMawonLeaderboardScreen(),
    ),
    GoRoute(
      path: '/skrabb',
      builder: (context, state) => const SkrabbScreen(),
    ),
    GoRoute(
      path: '/met-double',
      builder: (context, state) => const MetDoubleHomeScreen(),
    ),
    GoRoute(
      path: '/met-double/stats',
      builder: (context, state) => const MetDoubleGeneralStatsScreen(),
    ),
    GoRoute(
      path: '/koze-kwaze',
      builder: (context, state) => const TranslatorScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendsListScreen(),
    ),
    GoRoute(
      path: '/friends/add',
      builder: (context, state) => const AddFriendScreen(),
    ),
    GoRoute(
      path: '/friends/invite-email',
      builder: (context, state) => const EmailInvitationScreen(),
    ),
  ],
);
