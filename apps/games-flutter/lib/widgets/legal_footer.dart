import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  static const String baseUrl = 'https://kwazé-kréyol.fr';

  Future<void> _launchUrl(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Version
        Text(
          'Version Beta',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Legal Links
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            _LegalLink(
              text: 'Mentions légales',
              onTap: () => _launchUrl('/mentions-legales'),
            ),
            Text(
              '|',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            _LegalLink(
              text: 'Confidentialité',
              onTap: () => _launchUrl('/politique-confidentialite'),
            ),
            Text(
              '|',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            _LegalLink(
              text: 'CGU',
              onTap: () => _launchUrl('/cgu'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Copyright
        Text(
          '© 2025 ITMade Studio',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
