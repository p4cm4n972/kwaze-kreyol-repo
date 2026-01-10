import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/presence_service.dart';
import '../widgets/legal_footer.dart';
import 'auth_screen.dart';

// Couleurs Kwazé Kréyol style FDJ
class KKColors {
  static const Color primary = Color(0xFFE67E22); // Orange KK
  static const Color primaryDark = Color(0xFFD35400);
  static const Color secondary = Color(0xFF1a1a2e); // Bleu foncé
  static const Color secondaryLight = Color(0xFF16213e);
  static const Color accent = Color(0xFFFFD700); // Or
  static const Color background = Color(0xFFF5F5F5); // Gris clair
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1a1a2e);
  static const Color textLight = Color(0xFF666666);
}

class GamesHomeScreen extends StatefulWidget {
  const GamesHomeScreen({super.key});

  @override
  State<GamesHomeScreen> createState() => _GamesHomeScreenState();
}

class _GamesHomeScreenState extends State<GamesHomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final RealtimeService _realtimeService = RealtimeService();
  final PresenceService _presenceService = PresenceService();
  bool _isAuthenticated = false;
  String? _displayName;
  int _pendingRequestsCount = 0;
  int _selectedNavIndex = 0;

  late AnimationController _heroAnimController;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _subscribeToFriendRequests();
    _initPresence();
    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  Future<void> _initPresence() async {
    // Initialiser le tracking de présence pour tous (connectés et visiteurs)
    await _presenceService.initialize();
  }

  @override
  void dispose() {
    _heroAnimController.dispose();
    // NE PAS disposer le PresenceService ici - il doit persister pendant toute la session
    // La présence sera gérée au niveau de l'app (fermeture/déconnexion)
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
      _realtimeService.subscribeToFriendRequests(userId).listen(
        (requests) {
          if (mounted) {
            setState(() {
              _pendingRequestsCount = requests.length;
            });
          }
        },
        onError: (e) {},
      );
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KKColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Banner avec Header intégré
          SliverToBoxAdapter(
            child: _buildHeroWithHeader(),
          ),
          // Contenu des jeux (adaptatif desktop/mobile)
          SliverToBoxAdapter(
            child: _buildGamesContent(),
          ),
          // Footer légal
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              color: KKColors.secondary,
              child: const LegalFooter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroWithHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1024;
        final bannerHeight = isMobile ? 320.0 : (isTablet ? 360.0 : 400.0);
        final titleSize = isMobile ? 32.0 : (isTablet ? 38.0 : 42.0);
        final subtitleSize = isMobile ? 14.0 : 16.0;

        return Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                isMobile
                    ? 'assets/images/bkg-mobile.webp'
                    : 'assets/images/bkg.webp',
              ),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            color: KKColors.secondary,
          ),
          child: Stack(
            children: [
              // Éléments flottants animés
              AnimatedBuilder(
                animation: _heroAnimController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      _buildFloatingElement('K', screenWidth * 0.05, 80, _heroAnimController.value, 0, isMobile ? 32 : 48),
                      if (!isMobile) _buildFloatingElement('W', screenWidth * 0.75, 100, _heroAnimController.value, 0.2, 48),
                      _buildFloatingElement('A', screenWidth * 0.4, bannerHeight * 0.7, _heroAnimController.value, 0.4, isMobile ? 28 : 48),
                      if (!isMobile) _buildFloatingElement('Z', screenWidth * 0.85, bannerHeight * 0.5, _heroAnimController.value, 0.6, 48),
                      _buildFloatingElement('É', screenWidth * 0.15, bannerHeight * 0.5, _heroAnimController.value, 0.8, isMobile ? 28 : 48),
                      _buildFloatingDomino(screenWidth * 0.02, bannerHeight * 0.75, _heroAnimController.value, 0.1),
                      if (!isMobile) _buildFloatingDomino(screenWidth * 0.8, 60, _heroAnimController.value, 0.5),
                      _buildFloatingDomino(screenWidth * 0.7, bannerHeight * 0.8, _heroAnimController.value, 0.3),
                    ],
                  );
                },
              ),
              // Header transparent en haut
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logo-kk.webp',
                          height: 48,
                          width: 48,
                          errorBuilder: (_, __, ___) => const Text('KK', style: TextStyle(fontWeight: FontWeight.bold, color: KKColors.accent, fontSize: 20)),
                        ),
                        const Spacer(),
                        // Cloche notifications
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_isAuthenticated) {
                                  context.go('/friends');
                                } else {
                                  _showAuthScreen();
                                }
                              },
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                            ),
                            if (_pendingRequestsCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text('$_pendingRequestsCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                        // Avatar / Bouton connexion
                        GestureDetector(
                          onTap: _isAuthenticated ? () => _showUserMenu(context) : _showAuthScreen,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: _isAuthenticated
                                ? Text(
                                    (_displayName?.isNotEmpty == true ? _displayName![0] : 'U').toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  )
                                : const Icon(Icons.person_outline, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Contenu central
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(colors: [KKColors.accent, KKColors.primary]).createShader(bounds),
                        child: Text(
                          'Kwazé Kréyol',
                          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: isMobile ? 1 : 2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Valorisons la langue créole à travers le jeu !',
                        style: TextStyle(fontSize: subtitleSize, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Logo KK sans fond
              Image.asset(
                'assets/images/logo-kk.webp',
                height: 48,
                width: 48,
                errorBuilder: (_, __, ___) => const Text(
                  'KK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: KKColors.accent,
                    fontSize: 20,
                  ),
                ),
              ),
              const Spacer(),
              // Cloche notifications
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_isAuthenticated) {
                        context.go('/friends');
                      } else {
                        _showAuthScreen();
                      }
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (_pendingRequestsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
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
              // Avatar utilisateur
              GestureDetector(
                onTap: _isAuthenticated
                    ? () => _showUserMenu(context)
                    : _showAuthScreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: KKColors.primary,
                        child: _isAuthenticated
                            ? Text(
                                (_displayName?.isNotEmpty == true ? _displayName![0] : 'U').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : const Icon(Icons.person_outline, color: Colors.white, size: 16),
                      ),
                      if (_isAuthenticated) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: KKColors.textDark,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: KKColors.primary,
                child: Text(
                  (_displayName?.isNotEmpty == true ? _displayName![0] : 'U').toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                _displayName?.isNotEmpty == true ? _displayName! : 'Utilisateur',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Compte connecté'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mon Profil'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Mes Amis'),
              trailing: _pendingRequestsCount > 0
                  ? Container(
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
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                context.go('/friends');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1024;

        // Ajuster la hauteur selon l'écran
        final bannerHeight = isMobile ? 280.0 : (isTablet ? 320.0 : 350.0);
        final titleSize = isMobile ? 32.0 : (isTablet ? 38.0 : 42.0);
        final subtitleSize = isMobile ? 14.0 : 16.0;

        return Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                isMobile
                    ? 'assets/images/bkg-mobile.webp'
                    : 'assets/images/bkg.webp',
              ),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                KKColors.secondary.withValues(alpha: 0.7),
                BlendMode.darken,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Éléments flottants animés (lettres et dominos) - responsive
              AnimatedBuilder(
                animation: _heroAnimController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Lettres positionnées en pourcentage de la largeur
                      _buildFloatingElement(
                        'K',
                        screenWidth * 0.05,
                        30,
                        _heroAnimController.value,
                        0,
                        isMobile ? 32 : 48,
                      ),
                      if (!isMobile) _buildFloatingElement(
                        'W',
                        screenWidth * 0.75,
                        60,
                        _heroAnimController.value,
                        0.2,
                        48,
                      ),
                      _buildFloatingElement(
                        'A',
                        screenWidth * 0.4,
                        bannerHeight * 0.7,
                        _heroAnimController.value,
                        0.4,
                        isMobile ? 28 : 48,
                      ),
                      if (!isMobile) _buildFloatingElement(
                        'Z',
                        screenWidth * 0.85,
                        bannerHeight * 0.5,
                        _heroAnimController.value,
                        0.6,
                        48,
                      ),
                      _buildFloatingElement(
                        'É',
                        screenWidth * 0.15,
                        bannerHeight * 0.45,
                        _heroAnimController.value,
                        0.8,
                        isMobile ? 28 : 48,
                      ),
                      // Dominos flottants
                      _buildFloatingDomino(
                        screenWidth * 0.02,
                        bannerHeight * 0.75,
                        _heroAnimController.value,
                        0.1,
                      ),
                      if (!isMobile) _buildFloatingDomino(
                        screenWidth * 0.8,
                        20,
                        _heroAnimController.value,
                        0.5,
                      ),
                      _buildFloatingDomino(
                        screenWidth * 0.7,
                        bannerHeight * 0.8,
                        _heroAnimController.value,
                        0.3,
                      ),
                    ],
                  );
                },
              ),
              // Contenu central
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: KKColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'JEUX CRÉOLES',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 10 : 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      // Titre
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [KKColors.accent, KKColors.primary],
                        ).createShader(bounds),
                        child: Text(
                          'Kwazé Kréyol',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: isMobile ? 1 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMobile
                          ? 'Valorisons la langue créole à travers le jeu !'
                          : 'Valorisons la langue créole\nà travers le jeu !',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingElement(
    String letter,
    double left,
    double top,
    double animValue,
    double offset, [
    double fontSize = 48,
  ]) {
    final adjustedValue = (animValue + offset) % 1.0;
    final yOffset = math.sin(adjustedValue * 2 * math.pi) * 15;
    final rotation = math.sin(adjustedValue * 2 * math.pi) * 0.1;

    return Positioned(
      left: left,
      top: top + yOffset,
      child: Transform.rotate(
        angle: rotation,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: KKColors.accent.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingDomino(
    double left,
    double top,
    double animValue,
    double offset,
  ) {
    final adjustedValue = (animValue + offset) % 1.0;
    final yOffset = math.cos(adjustedValue * 2 * math.pi) * 12;
    final rotation = math.cos(adjustedValue * 2 * math.pi) * 0.15;

    return Positioned(
      left: left,
      top: top + yOffset,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 24,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Liste de tous les jeux
  List<_GameData> get _allGames => [
    _GameData(
      id: 'mots-mawon',
      name: 'Mots Mawon',
      subtitle: 'Jeu de mots cachés en créole martiniquais',
      iconPath: 'assets/icons/mots-mawon.png',
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
      available: true,
    ),
    _GameData(
      id: 'skrabb',
      name: 'Skrabb',
      subtitle: 'Scrabble créole ! Forme des mots et marque des points',
      iconPath: 'assets/icons/skrabb.png',
      gradient: [Color(0xFFe53935), Color(0xFFe35d5b)],
      available: true,
    ),
    _GameData(
      id: 'endorlisseur',
      name: 'Endorlisseur',
      subtitle: 'Jeu de stratégie inspiré de la culture créole',
      iconPath: 'assets/icons/endorlisseur.png',
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      available: false,
      badge: 'Bientôt',
    ),
    _GameData(
      id: 'domino',
      name: 'Dominos',
      subtitle: 'Jeu de dominos aux règles martiniquaises',
      iconPath: 'assets/icons/double-siz.png',
      gradient: [Color(0xFFE67E22), Color(0xFFf39c12)],
      available: true,
      badge: 'Populaire',
    ),
    _GameData(
      id: 'koze-kwaze',
      name: 'Kozé Kwazé',
      subtitle: 'Traducteur créole intelligent',
      iconPath: 'assets/icons/koze-kwaze.png',
      gradient: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
      available: true,
    ),
    _GameData(
      id: 'met-double',
      name: 'Mét Double',
      subtitle: 'Outil pour suivre tes parties de dominos',
      iconPath: 'assets/icons/met-double.png',
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      available: true,
      badge: 'Nouveau',
    ),
  ];

  Widget _buildGamesContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Grille pour tous les écrans (mobile et desktop)
        return _buildDesktopGrid(constraints.maxWidth);
      },
    );
  }

  Widget _buildMobileCategories() {
    return Column(
      children: [
        // Section "Notre sélection pour vous"
        _buildCategorySection(
          title: 'Notre sélection pour vous',
          games: [
            _allGames.firstWhere((g) => g.id == 'endorlisseur'),
            _allGames.firstWhere((g) => g.id == 'mots-mawon'),
          ],
        ),
        // Section "Les incontournables"
        _buildCategorySection(
          title: 'Les incontournables',
          games: [
            _allGames.firstWhere((g) => g.id == 'domino'),
            _allGames.firstWhere((g) => g.id == 'skrabb'),
          ],
        ),
        // Section "Les nouveautés"
        _buildCategorySection(
          title: 'Les nouveautés',
          games: [
            _allGames.firstWhere((g) => g.id == 'koze-kwaze'),
            _allGames.firstWhere((g) => g.id == 'met-double'),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(double maxWidth) {
    final isMobile = maxWidth < 600;
    final crossAxisCount = isMobile ? 2 : 3;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KKColors.secondary, KKColors.secondaryLight],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nos jeux',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: KKColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Découvre nos jeux 100% créole ! Joue en ligne ou télécharge les applications.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isMobile ? 10 : 16,
                  mainAxisSpacing: isMobile ? 10 : 16,
                  childAspectRatio: isMobile ? 0.7 : 0.85,
                ),
                itemCount: _allGames.length,
                itemBuilder: (context, index) {
                  final game = _allGames[index];
                  return _DesktopGameCard(
                    name: game.name,
                    description: game.subtitle,
                    iconPath: game.iconPath,
                    gradient: game.gradient,
                    available: game.available,
                    badge: game.badge,
                    isMobile: isMobile,
                    onTap: game.available ? () => context.go('/${game.id}') : null,
                  );
            },
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCards() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KKColors.secondary, KKColors.secondaryLight],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MainGameCard(
                  name: 'Kozé Kwazé',
                  subtitle: 'Traducteur créole intelligent',
                  iconPath: 'assets/icons/koze-kwaze.png',
                  gradient: const [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                  onTap: () => context.go('/koze-kwaze'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MainGameCard(
                  name: 'Skrabb',
                  subtitle: 'Scrabble en créole',
                  iconPath: 'assets/icons/skrabb.png',
                  gradient: const [Color(0xFFe53935), Color(0xFFe35d5b)],
                  onTap: () => context.go('/skrabb'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<_GameData> games,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KKColors.secondary, KKColors.secondaryLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: KKColors.accent,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return Padding(
                  padding: EdgeInsets.only(right: index < games.length - 1 ? 12 : 0),
                  child: _CategoryGameCard(
                    name: game.name,
                    subtitle: game.subtitle,
                    iconPath: game.iconPath,
                    gradient: game.gradient,
                    badge: game.badge,
                    available: game.available,
                    onTap: game.available ? () => context.go('/${game.id}') : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                isSelected: _selectedNavIndex == 0,
                onTap: () => setState(() => _selectedNavIndex = 0),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Catalogue',
                isSelected: _selectedNavIndex == 1,
                onTap: () => setState(() => _selectedNavIndex = 1),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Résultats',
                isSelected: _selectedNavIndex == 2,
                onTap: () => setState(() => _selectedNavIndex = 2),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'Historique',
                isSelected: _selectedNavIndex == 3,
                onTap: () => setState(() => _selectedNavIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Mon espace',
                isSelected: _selectedNavIndex == 4,
                onTap: () {
                  setState(() => _selectedNavIndex = 4);
                  if (_isAuthenticated) {
                    context.go('/profile');
                  } else {
                    _showAuthScreen();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour les cartes de jeux principales (style original)
class _MainGameCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String iconPath;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _MainGameCard({
    required this.name,
    required this.subtitle,
    required this.iconPath,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: KKColors.accent.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône dominante
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    gradient[0].withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Icon
                            Image.asset(
                              iconPath,
                              width: 90,
                              height: 90,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.sports_esports,
                                size: 70,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nom du jeu
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KKColors.accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // Bouton Jouer
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_esports,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Jouer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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

// Widget pour les cartes de jeux mobile - même style que desktop
class _CategoryGameCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String iconPath;
  final List<Color> gradient;
  final String? badge;
  final bool available;
  final VoidCallback? onTap;

  const _CategoryGameCard({
    required this.name,
    required this.subtitle,
    required this.iconPath,
    required this.gradient,
    this.badge,
    required this.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: available ? onTap : null,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Section haute - Fond blanc avec image seulement
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      // Image centrée
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Opacity(
                            opacity: available ? 1.0 : 0.5,
                            child: Image.asset(
                              iconPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.sports_esports,
                                size: 50,
                                color: gradient[0].withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Badge en haut à droite
                      if (badge != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: badge == 'Nouveau'
                                  ? Colors.green
                                  : badge == 'Populaire'
                                      ? KKColors.primary
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Section basse - Fond bleu avec bouton
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: KKColors.secondary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nom du jeu
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: KKColors.accent,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Bouton Jouer
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: available
                            ? LinearGradient(colors: gradient)
                            : null,
                        color: available ? null : Colors.grey.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: available ? onTap : null,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_esports,
                                  size: 14,
                                  color: available ? Colors.white : Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  available ? 'Jouer' : 'Bientôt',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: available ? Colors.white : Colors.white54,
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
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour les items de navigation
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? KKColors.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? KKColors.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les cartes de jeux desktop (grille) - Style avec section blanche + section bleue
class _DesktopGameCard extends StatelessWidget {
  final String name;
  final String description;
  final String iconPath;
  final List<Color> gradient;
  final bool available;
  final String? badge;
  final bool isMobile;
  final VoidCallback? onTap;

  const _DesktopGameCard({
    required this.name,
    required this.description,
    required this.iconPath,
    required this.gradient,
    required this.available,
    this.badge,
    this.isMobile = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: available ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Section haute - Fond blanc avec image seulement
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      // Image centrée (moins de padding sur mobile)
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 6 : 16),
                          child: Opacity(
                            opacity: available ? 1.0 : 0.5,
                            child: Image.asset(
                              iconPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.sports_esports,
                                size: isMobile ? 50 : 100,
                                color: gradient[0].withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Badge en haut à droite
                      if (badge != null)
                        Positioned(
                          top: isMobile ? 4 : 12,
                          right: isMobile ? 4 : 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 6 : 10,
                              vertical: isMobile ? 2 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: badge == 'Nouveau'
                                  ? Colors.green
                                  : badge == 'Populaire'
                                      ? KKColors.primary
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 8 : 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Section basse - Fond bleu foncé avec nom (+ bouton sur desktop)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
                color: KKColors.secondary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nom du jeu (en couleur gradient sur mobile)
                    isMobile
                        ? ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: available ? gradient : [Colors.grey, Colors.grey],
                            ).createShader(bounds),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: KKColors.accent,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    // Bouton Jouer uniquement sur desktop
                    if (!isMobile) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: available
                              ? LinearGradient(colors: gradient)
                              : null,
                          color: available ? null : Colors.grey.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
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
                                    size: 18,
                                    color: available ? Colors.white : Colors.white54,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    available ? 'Jouer' : 'Bientôt',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: available ? Colors.white : Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modèle de données pour les jeux
class _GameData {
  final String id;
  final String name;
  final String subtitle;
  final String iconPath;
  final List<Color> gradient;
  final bool available;
  final String? badge;

  const _GameData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconPath,
    required this.gradient,
    required this.available,
    this.badge,
  });
}
