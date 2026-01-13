import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_version.dart';

class LegalFooter extends StatefulWidget {
  const LegalFooter({super.key});

  @override
  State<LegalFooter> createState() => _LegalFooterState();
}

class _LegalFooterState extends State<LegalFooter>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = 'https://kwazé-kréyol.fr';
  static const String kofiUrl = 'https://ko-fi.com/kwazekreyol';

  late AnimationController _coffeeController;
  late Animation<double> _coffeeAnimation;

  @override
  void initState() {
    super.initState();
    _coffeeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _coffeeAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _coffeeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _coffeeController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : '$baseUrl$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ligne 1: Version + Ko-fi (badges harmonisés)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Version Beta Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science_outlined, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    AppVersion.fullVersion.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Bouton Ko-fi (bleu/teal pour contraste)
            Tooltip(
              message: 'Soutenez le projet sur Ko-fi !',
              preferBelow: false,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchUrl(kofiUrl),
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(14),
                  hoverColor: Colors.white.withValues(alpha: 0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF29B6F6), Color(0xFF26C6DA)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF29B6F6).withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tasse animée
                        AnimatedBuilder(
                          animation: _coffeeAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _coffeeAnimation.value,
                              child: const Text('☕', style: TextStyle(fontSize: 12)),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Un café ?',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
        const SizedBox(height: 10),

        // Ligne 2: Legal Links + Copyright
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LegalLink(
              text: 'Mentions légales',
              onTap: () => _launchUrl('/mentions-legales'),
            ),
            const _Separator(),
            _LegalLink(
              text: 'Confidentialité',
              onTap: () => _launchUrl('/politique-confidentialite'),
            ),
            const _Separator(),
            _LegalLink(
              text: 'CGU',
              onTap: () => _launchUrl('/cgu'),
            ),
            const _Separator(),
            Text(
              '© 2025 - ${DateTime.now().year} ITMade',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Text(
      '•',
      style: TextStyle(
        fontSize: 10,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _LegalLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.5),
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
