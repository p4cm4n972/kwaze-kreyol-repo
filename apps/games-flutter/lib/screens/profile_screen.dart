import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String _phonePrefix = '+590'; // Guadeloupe/Martinique par défaut

  final List<Map<String, String>> _phonePrefixes = [
    {'code': '+590', 'label': '🇬🇵 +590 (Guadeloupe)'},
    {'code': '+596', 'label': '🇲🇶 +596 (Martinique)'},
    {'code': '+594', 'label': '🇬🇫 +594 (Guyane)'},
    {'code': '+262', 'label': '🇷🇪 +262 (Réunion)'},
    {'code': '+33', 'label': '🇫🇷 +33 (France)'},
    {'code': '+1', 'label': '🇺🇸 +1 (USA/Canada)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _usernameController.text = user.username ?? '';
          _postalCodeController.text = user.postalCode ?? '';

          // Extraire le préfixe et le numéro du téléphone s'il existe
          if (user.phone != null && user.phone!.isNotEmpty) {
            for (final prefix in _phonePrefixes) {
              if (user.phone!.startsWith(prefix['code']!)) {
                _phonePrefix = prefix['code']!;
                _phoneController.text = user.phone!.substring(prefix['code']!.length);
                break;
              }
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation code postal (si rempli)
    if (_postalCodeController.text.trim().isNotEmpty) {
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

    // Validation téléphone (si rempli)
    if (_phoneController.text.trim().isNotEmpty) {
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

    setState(() => _isSaving = true);

    try {
      final phoneNumber = _phoneController.text.trim().isNotEmpty
          ? '$_phonePrefix${_phoneController.text.trim()}'
          : null;

      await SupabaseService.client.from('users').update({
        'username': _usernameController.text.trim(),
        'postal_code': _postalCodeController.text.trim().isNotEmpty
            ? _postalCodeController.text.trim()
            : null,
        'phone': phoneNumber,
      }).eq('id', _currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        // Recharger les données
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      // Demander à l'utilisateur de choisir la source
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Sélectionner l'image
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      try {
        // Uploader l'image
        final avatarUrl = await _storageService.uploadAvatar(
          userId: _currentUser!.id,
          imageFile: File(image.path),
        );

        // Mettre à jour l'URL dans la base de données
        await _storageService.updateUserAvatar(
          userId: _currentUser!.id,
          avatarUrl: avatarUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo de profil mise à jour'),
              backgroundColor: Colors.green,
            ),
          );
          // Recharger les données
          await _loadUserData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
          tooltip: 'Retour aux jeux',
        ),
        title: const Text('Mon Profil'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar
                      Center(
                        child: Stack(
                          children: [
                            _isUploadingImage
                                ? const CircleAvatar(
                                    radius: 60,
                                    child: CircularProgressIndicator(),
                                  )
                                : CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    backgroundImage: _currentUser?.avatarUrl != null
                                        ? NetworkImage(_currentUser!.avatarUrl!)
                                        : null,
                                    child: _currentUser?.avatarUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                            if (!_isUploadingImage)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: _changeProfilePicture,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email (non modifiable)
                      TextFormField(
                        initialValue: _currentUser?.email ?? '',
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // Pseudo
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Pseudo',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le pseudo est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Code postal
                      TextFormField(
                        controller: _postalCodeController,
                        decoration: InputDecoration(
                          labelText: 'Code postal (optionnel)',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                      ),
                      const SizedBox(height: 16),

                      // Téléphone avec sélecteur de préfixe
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
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
                                  labelText: 'Téléphone (optionnel)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
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
                      ),
                      const SizedBox(height: 32),

                      // Code ami
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.qr_code, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Code ami',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentUser?.friendCode ?? 'Non disponible',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Partagez ce code avec vos amis',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton Sauvegarder
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sauvegarder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
