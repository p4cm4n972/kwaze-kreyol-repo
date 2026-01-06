import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../services/translator_service.dart';
import '../models/dictionary_word.dart';

class TranslatorContributeScreen extends StatefulWidget {
  final String? initialWord;

  const TranslatorContributeScreen({
    super.key,
    this.initialWord,
  });

  @override
  State<TranslatorContributeScreen> createState() =>
      _TranslatorContributeScreenState();
}

class _TranslatorContributeScreenState
    extends State<TranslatorContributeScreen> {
  final TranslatorService _translatorService = TranslatorService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();

  String? _selectedNature;
  bool _isSubmitting = false;
  List<DictionaryContribution> _myContributions = [];
  bool _isLoadingContributions = true;

  final List<String> _natures = [
    'Nom',
    'Verbe',
    'Adjectif',
    'Adverbe',
    'Préposition',
    'Conjonction',
    'Interjection',
    'Pronom',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialWord != null) {
      _wordController.text = widget.initialWord!;
    }
    _loadMyContributions();
  }

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _loadMyContributions() async {
    setState(() {
      _isLoadingContributions = true;
    });

    final userId = _authService.getUserIdOrNull();
    if (userId != null) {
      try {
        final contributions =
            await _translatorService.getUserContributions(userId);
        setState(() {
          _myContributions = contributions;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }

    setState(() {
      _isLoadingContributions = false;
    });
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = _authService.getUserIdOrNull();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour contribuer'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _translatorService.submitContribution(
        userId: userId,
        word: _wordController.text.trim(),
        translation: _translationController.text.trim(),
        nature: _selectedNature,
        example: _exampleController.text.isNotEmpty
            ? _exampleController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contribution envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _wordController.clear();
        _translationController.clear();
        _exampleController.clear();
        setState(() {
          _selectedNature = null;
        });

        // Recharger les contributions
        _loadMyContributions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribuer au dictionnaire'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message d'introduction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aidez à enrichir le dictionnaire kréyol en proposant de nouveaux mots !',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulaire
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mot
                  TextFormField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot en créole',
                      hintText: 'Ex: boukoloshe',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Traduction
                  TextFormField(
                    controller: _translationController,
                    decoration: const InputDecoration(
                      labelText: 'Traduction en français',
                      hintText: 'Ex: désordre, pagaille',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.translate),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une traduction';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nature
                  DropdownButtonFormField<String>(
                    value: _selectedNature,
                    decoration: const InputDecoration(
                      labelText: 'Nature grammaticale (optionnel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _natures.map((nature) {
                      return DropdownMenuItem(
                        value: nature,
                        child: Text(nature),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedNature = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Exemple
                  TextFormField(
                    controller: _exampleController,
                    decoration: const InputDecoration(
                      labelText: 'Exemple d\'utilisation (optionnel)',
                      hintText: 'Ex: I ni an boukoloshe adan sal-la',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_quote),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Bouton de soumission
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitContribution,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSubmitting ? 'Envoi...' : 'Soumettre',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Mes contributions
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Mes contributions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (_isLoadingContributions)
              const Center(child: CircularProgressIndicator())
            else if (_myContributions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.library_add,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune contribution pour le moment',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._myContributions
                  .map((contribution) => _buildContributionCard(contribution)),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard(DictionaryContribution contribution) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (contribution.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approuvée';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejetée';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = contribution.status;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    contribution.word,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              contribution.translation,
              style: const TextStyle(fontSize: 16),
            ),
            if (contribution.nature != null) ...[
              const SizedBox(height: 4),
              Text(
                contribution.nature!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (contribution.reviewNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contribution.reviewNotes!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(contribution.submittedAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
