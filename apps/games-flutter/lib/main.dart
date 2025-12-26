import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/games_home_screen.dart';
import 'games/mots_mawon/mots_mawon_screen.dart';

void main() {
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
    GoRoute(
      path: '/',
      builder: (context, state) => const GamesHomeScreen(),
    ),
    GoRoute(
      path: '/mots-mawon',
      builder: (context, state) => const MotsMawonScreen(),
    ),
    // Autres jeux à ajouter ici
  ],
);
