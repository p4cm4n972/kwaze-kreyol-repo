import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AuthScreen({super.key, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestNameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String _phonePrefix = '+590'; // Guadeloupe/Martinique par défaut

  final List<Map<String, String>> _phonePrefixes = [
    {'code': '+590', 'label': '🇬🇵 +590 (Guadeloupe)'},
    {'code': '+596', 'label': '🇲🇶 +596 (Martinique)'},
    {'code': '+594', 'label': '🇬🇫 +594 (Guyane)'},
    {'code': '+262', 'label': '🇷🇪 +262 (Réunion)'},
    {'code': '+33', 'label': '🇫🇷 +33 (France)'},
    {'code': '+1', 'label': '🇺🇸 +1 (USA/Canada)'},
  ];

  /// Convertit les erreurs Supabase en messages utilisateur
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Erreurs d'email
    if (errorString.contains('email') && errorString.contains('already')) {
      return 'Cet email est déjà utilisé';
    }
    if (errorString.contains('invalid email')) {
      return 'Format d\'email invalide';
    }

    // Erreurs de mot de passe
    if (errorString.contains('password') && errorString.contains('short')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (errorString.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }

    // Erreurs HTTP spécifiques
    if (errorString.contains('400')) {
      return 'Requête invalide. Vérifiez vos informations';
    }
    if (errorString.contains('401')) {
      return 'Email ou mot de passe incorrect';
    }
    if (errorString.contains('403')) {
      return 'Accès refusé';
    }
    if (errorString.contains('404')) {
      return 'Service non disponible';
    }
    if (errorString.contains('406')) {
      return 'Données non acceptables. Contactez le support';
    }
    if (errorString.contains('409')) {
      return 'Cet utilisateur existe déjà';
    }
    if (errorString.contains('422')) {
      return 'Données invalides. Vérifiez tous les champs';
    }
    if (errorString.contains('429')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes';
    }
    if (errorString.contains('500') || errorString.contains('503')) {
      return 'Erreur serveur. Réessayez plus tard';
    }

    // Erreurs réseau
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Erreur de connexion. Vérifiez votre internet';
    }

    // Message générique
    return 'Erreur: ${error.toString()}';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    // Validation côté client
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email et mot de passe requis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation format email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format d\'email invalide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation mot de passe (min 6 caractères)
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation code postal (si inscription)
    if (!_isLogin && _postalCodeController.text.trim().isNotEmpty) {
      if (_postalCodeController.text.trim().length != 5 ||
          !RegExp(r'^\d{5}$').hasMatch(_postalCodeController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le code postal doit contenir exactement 5 chiffres'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Validation téléphone (si inscription)
    if (!_isLogin && _phoneController.text.trim().isNotEmpty) {
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      if (phoneDigits.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le numéro de téléphone doit contenir au moins 10 chiffres'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Connexion
        await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Inscription - Concatener le préfixe au numéro de téléphone
        final phoneNumber = _phoneController.text.trim().isNotEmpty
            ? '$_phonePrefix${_phoneController.text.trim()}'
            : '';

        await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          phone: phoneNumber,
        );
      }

      if (mounted) {
        // Appeler le callback
        widget.onSuccess?.call();

        // Vérifier si on peut faire pop (navigation push)
        // Sinon rediriger vers la page d'accueil (route GoRouter)
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleGuestMode() async {
    if (_guestNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre nom')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInAsGuest(_guestNameController.text.trim());

      if (mounted) {
        // Appeler le callback
        widget.onSuccess?.call();

        // Vérifier si on peut faire pop (navigation push)
        // Sinon rediriger vers la page d'accueil (route GoRouter)
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond avec waves madras
          Positioned.fill(
            child: CustomPaint(
              painter: _MadrasWavesPainter(),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Kwazé Kréyol
                  Image.asset(
                    'assets/images/logo-kk.png',
                    height: 120,
                  ),
                  const SizedBox(height: 16),

                  // Titre
                  Text(
                    _isLogin ? 'Connexion' : 'Inscription',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email
                  _buildStyledTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildStyledTextField(
                    controller: _passwordController,
                    labelText: 'Mot de passe',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  // Username (inscription uniquement)
                  if (!_isLogin) ...[
                    _buildStyledTextField(
                      controller: _usernameController,
                      labelText: 'Nom d\'utilisateur (optionnel)',
                      prefixIcon: Icons.person,
                    ),
                    const SizedBox(height: 16),

                    // Code postal
                    _buildStyledTextField(
                      controller: _postalCodeController,
                      labelText: 'Code postal',
                      prefixIcon: Icons.location_on,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                    ),
                    const SizedBox(height: 16),

                    // Téléphone avec sélecteur de préfixe
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                  ],

                  // Bouton principal
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Se connecter' : 'S\'inscrire',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle connexion/inscription
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Pas encore de compte ? S\'inscrire'
                          : 'Déjà un compte ? Se connecter',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Colors.white54),
                  const SizedBox(height: 16),

                  // Mode invité
                  const Text(
                    'Ou continuer en tant qu\'invité',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  _buildStyledTextField(
                    controller: _guestNameController,
                    labelText: 'Votre nom',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGuestMode,
                    icon: const Icon(Icons.login),
                    label: const Text('Continuer en invité'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un champ de texte stylisé
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(prefixIcon, color: const Color(0xFFE74C3C)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: maxLength != null ? null : '',
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
      ),
    );
  }

  /// Construit le champ téléphone avec sélecteur de préfixe
  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sélecteur de préfixe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _phonePrefix,
              underline: const SizedBox(),
              items: _phonePrefixes.map((prefix) {
                return DropdownMenuItem<String>(
                  value: prefix['code'],
                  child: Text(
                    prefix['label']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _phonePrefix = value;
                  });
                }
              },
            ),
          ),

          // Séparateur
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),

          // Champ de saisie du numéro
          Expanded(
            child: TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Numéro',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter pour dessiner les waves madras
class _MadrasWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Couleurs madras
    final colors = [
      const Color(0xFFE74C3C), // Rouge
      const Color(0xFFF39C12), // Jaune/orange
      const Color(0xFF27AE60), // Vert
      const Color(0xFF3498DB), // Bleu
      const Color(0xFF9B59B6), // Violet
    ];

    // Dessiner plusieurs vagues avec différentes couleurs
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i].withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final path = Path();
      final waveHeight = 40.0;
      final waveLength = size.width / 2;
      final yOffset = size.height * 0.15 + (i * 60.0);

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 1) {
        final y = yOffset +
            waveHeight *
                0.5 *
                (1 +
                    (i % 2 == 0 ? 1 : -1) *
                        (0.5 * math.sin((x / waveLength) * 2 * math.pi) +
                            0.5 * math.sin((x / (waveLength * 1.5)) * 2 * math.pi)));
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
