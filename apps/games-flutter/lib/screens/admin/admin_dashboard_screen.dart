import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import 'tabs/users_tab.dart';
import 'tabs/domino_tab.dart';
import 'tabs/skrabb_tab.dart';
import 'tabs/mots_mawon_tab.dart';

/// Couleurs de l'application
class KKColors {
  static const Color primary = Color(0xFFE67E22);
  static const Color primaryDark = Color(0xFFD35400);
  static const Color secondary = Color(0xFF1a1a2e);
  static const Color accent = Color(0xFFFFD700);
}

/// Écran principal du dashboard administrateur
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    final isAdmin = await _adminService.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });
      if (!isAdmin) {
        // Rediriger vers l'accueil si pas admin
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: KKColors.primary),
              SizedBox(height: 16),
              Text('Vérification des accès...'),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Accès non autorisé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous devez être administrateur pour accéder à cette page.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KKColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Dashboard Admin'),
          ],
        ),
        backgroundColor: KKColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.casino), text: 'Domino'),
            Tab(icon: Icon(Icons.grid_on), text: 'Skrabb'),
            Tab(icon: Icon(Icons.search), text: 'Mots Mawon'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UsersTab(),
          DominoTab(),
          SkrabbTab(),
          MotsMawonTab(),
        ],
      ),
    );
  }
}
