import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../models/friend_request.dart';
import 'auth_screen.dart';

class GamesHomeScreen extends StatefulWidget {
  const GamesHomeScreen({super.key});

  @override
  State<GamesHomeScreen> createState() => _GamesHomeScreenState();
}

class _GamesHomeScreenState extends State<GamesHomeScreen> {
  final AuthService _authService = AuthService();
  final RealtimeService _realtimeService = RealtimeService();
  bool _isAuthenticated = false;
  String? _displayName;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _subscribeToFriendRequests();
  }

  @override
  void dispose() {
    final userId = _authService.getUserIdOrNull();
    if (userId != null) {
      _realtimeService.unsubscribeFromFriendRequests(userId);
    }
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    final isGuest = await _authService.isGuestMode();

    setState(() {
      _isAuthenticated = isAuth;
    });

    if (isGuest) {
      _displayName = await _authService.getGuestName();
    } else {
      final user = await _authService.getCurrentUser();
      _displayName = user?.username ?? user?.email;
    }

    setState(() {});
  }

  Future<void> _showAuthScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthScreen(onSuccess: _checkAuth),
      ),
    );

    if (result == true) {
      _checkAuth();
    }
  }

  void _subscribeToFriendRequests() {
    final userId = _authService.getUserIdOrNull();
    if (userId != null) {
      _realtimeService
          .subscribeToFriendRequests(userId)
          .listen(
            (requests) {
              if (mounted) {
                setState(() {
                  _pendingRequestsCount = requests.length;
                });
              }
            },
            onError: (e) {
              // Silently fail for now
            },
          );
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    final games = [
      {
        'id': 'mots-mawon',
        'name': 'Mots Mawon',
        'description':
            'Jeu de mots cachés en créole martiniquais. Retrouve les mots dissimulés dans la grille !',
        'iconPath': 'assets/icons/mots-mawon.png',
        'available': true,
      },
      {
        'id': 'skrabb',
        'name': 'Skrabb',
        'description':
            'Scrabble créole ! Forme des mots en créole et marque un maximum de points.',
        'iconPath': 'assets/icons/skrabb.png',
        'available': true,
      },
      {
        'id': 'endorlisseur',
        'name': 'Endorlisseur',
        'description':
            'Jeu de stratégie inspiré de la culture créole martiniquaise.',
        'iconPath': 'assets/icons/endorlisseur.png',
        'available': false,
      },
      {
        'id': 'double-siz',
        'name': 'Double Siz',
        'description':
            'Jeu de dominos aux règles martiniquaises. Affronte tes adversaires !',
        'iconPath': 'assets/icons/double-siz.png',
        'available': false,
      },
      {
        'id': 'koze-kwaze',
        'name': 'Kozé Kwazé',
        'description':
            'Traducteur créole intelligent. Recherche, traduis et contribue !',
        'iconPath': 'assets/icons/koze-kwaze.png',
        'available': true,
      },
      {
        'id': 'met-double',
        'name': 'Mét Double',
        'description':
            'Outil pour suivre tes parties de dominos et statistiques cochons !',
        'iconPath': 'assets/icons/met-double.png',
        'available': true,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Align(
          alignment: Alignment.topRight,
          child: _isAuthenticated
              ? PopupMenuButton<String>(
                  icon: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFFFD700),
                        child: Text(
                          (_displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_pendingRequestsCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_pendingRequestsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      enabled: false,
                      value: 'username',
                      child: Text(
                        _displayName ?? 'Utilisateur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 8),
                          Text('Mon Profil'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'friends',
                      child: Row(
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 8),
                          const Text('Mes Amis'),
                          if (_pendingRequestsCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_pendingRequestsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Déconnexion'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'logout') {
                      _logout();
                    } else if (value == 'profile') {
                      context.go('/profile');
                    } else if (value == 'friends') {
                      context.go('/friends');
                    }
                  },
                )
              : FloatingActionButton(
                  onPressed: _showAuthScreen,
                  backgroundColor: const Color(0xFFFFD700),
                  child: const Icon(Icons.login, color: Colors.black),
                ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Nos jeux',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Découvre nos jeux 100% créole ! Joue en ligne ou télécharge les applications sur ton téléphone.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Games Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800
                        ? 3
                        : constraints.maxWidth > 500
                        ? 2
                        : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return _GameCard(
                          name: game['name'] as String,
                          description: game['description'] as String,
                          iconPath: game['iconPath'] as String,
                          available: game['available'] as bool,
                          onTap: game['available'] as bool
                              ? () => context.go('/${game['id']}')
                              : null,
                        );
                      },
                    );
                  },
                ),

                // Mobile Apps Section
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.1),
                        const Color(0xFFFF8C00).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Bientôt sur mobile',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nos jeux seront prochainement disponibles sur iOS et Android.\nTélécharge les applications gratuites et joue hors ligne !',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          Opacity(
                            opacity: 0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.apple, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'App Store',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: 0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.android, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Google Play',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Column(
                  children: [
                    Text(
                      'Version Beta',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 ITMade Studio',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String name;
  final String description;
  final String iconPath;
  final bool available;
  final VoidCallback? onTap;

  const _GameCard({
    required this.name,
    required this.description,
    required this.iconPath,
    required this.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: available ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: available ? onTap : null,
              splashColor: available
                  ? const Color(0xFFFFD700).withOpacity(0.2)
                  : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Game Icon - Dominant (70-80% of space)
                    Expanded(
                      flex: 7,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFFD700).withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Icon
                            Image.asset(
                              iconPath,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.sports_esports,
                                  size: 80,
                                  color: Colors.white54,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Game Info - Compact
                    const SizedBox(height: 16),
                    // Game Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: available
                            ? const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                              )
                            : null,
                        color: available ? null : Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: available
                            ? null
                            : Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: available ? onTap : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_esports,
                                  size: 20,
                                  color: available
                                      ? Colors.black
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  available ? 'Jouer' : 'Bientôt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: available
                                        ? Colors.black
                                        : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
