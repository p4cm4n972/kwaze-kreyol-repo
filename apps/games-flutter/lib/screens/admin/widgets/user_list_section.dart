import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/admin_stats.dart';
import '../../../services/admin_service.dart';

/// Section "Liste des inscrits" du dashboard admin.
///
/// Affiche un tableau paginé avec recherche en temps réel :
/// pseudo, email, rôle, date d'inscription, dernière connexion.
class UserListSection extends StatefulWidget {
  const UserListSection({super.key});

  @override
  State<UserListSection> createState() => _UserListSectionState();
}

class _UserListSectionState extends State<UserListSection> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<AdminUserListEntry> _users = [];
  int _totalCount = 0;
  bool _isLoading = true;
  String? _error;

  String _sortBy = 'created_at';
  bool _sortDesc = true;

  static const int _pageSize = 50;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    // Debounce (retarder) de 400ms pour éviter une requête à chaque frappe
    _debounce = Timer(const Duration(milliseconds: 400), _loadUsers);
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _adminService.getUserList(
        searchQuery: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        limit: _pageSize,
        sortBy: _sortBy,
        sortDesc: _sortDesc,
      );
      if (mounted) {
        setState(() {
          _users = result.users;
          _totalCount = result.totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortDesc = !_sortDesc;
      } else {
        _sortBy = column;
        _sortDesc = true;
      }
    });
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          totalCount: _totalCount,
          searchController: _searchController,
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: _isLoading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _loadUsers)
                  : _users.isEmpty
                      ? const _EmptyView()
                      : _UserTable(
                          users: _users,
                          sortBy: _sortBy,
                          sortDesc: _sortDesc,
                          onSort: _onSort,
                        ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.totalCount,
    required this.searchController,
  });

  final int totalCount;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Liste des inscrits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (totalCount > 0)
                Text(
                  '$totalCount inscrit${totalCount > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 240,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UserTable extends StatelessWidget {
  const _UserTable({
    required this.users,
    required this.sortBy,
    required this.sortDesc,
    required this.onSort,
  });

  final List<AdminUserListEntry> users;
  final String sortBy;
  final bool sortDesc;
  final void Function(String column) onSort;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columnSpacing: 24,
        columns: [
          DataColumn(label: const Text('Pseudo'), onSort: (_, __) => onSort('username')),
          const DataColumn(label: Text('Email')),
          const DataColumn(label: Text('Rôle')),
          DataColumn(
            label: _SortableHeader(
              label: 'Inscription',
              active: sortBy == 'created_at',
              descending: sortDesc,
            ),
            onSort: (_, __) => onSort('created_at'),
          ),
          DataColumn(
            label: _SortableHeader(
              label: 'Dernière activité',
              active: sortBy == 'last_sign_in_at',
              descending: sortDesc,
            ),
            onSort: (_, __) => onSort('last_sign_in_at'),
          ),
        ],
        rows: users.map((u) => _buildRow(u)).toList(),
      ),
    );
  }

  DataRow _buildRow(AdminUserListEntry u) {
    return DataRow(
      cells: [
        DataCell(_UsernameCell(username: u.username, email: u.email)),
        DataCell(
          Text(
            u.email,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(_RoleBadge(role: u.role)),
        DataCell(
          Text(
            _formatDate(u.createdAt),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            u.lastSignInAt != null
                ? _formatRelative(u.lastSignInAt!)
                : '—',
            style: TextStyle(
              fontSize: 13,
              color: u.lastSignInAt != null ? null : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 30) return 'il y a ${diff.inDays} jours';
    if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).round()} mois';
    return 'il y a ${(diff.inDays / 365).round()} an(s)';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.active,
    required this.descending,
  });

  final String label;
  final bool active;
  final bool descending;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (active) ...[
          const SizedBox(width: 4),
          Icon(
            descending ? Icons.arrow_downward : Icons.arrow_upward,
            size: 14,
            color: const Color(0xFFE67E22),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UsernameCell extends StatelessWidget {
  const _UsernameCell({required this.username, required this.email});

  final String? username;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initials = _initials();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE67E22).withValues(alpha: 0.15),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE67E22),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          username ?? email.split('@').first,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _initials() {
    final name = username ?? email;
    final parts = name.trim().split(RegExp(r'[\s_\-\.]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'admin'       => ('Admin', Colors.red.shade700),
      'contributor' => ('Contrib.', Colors.green.shade700),
      'register'    => ('En attente', Colors.grey.shade600),
      _             => ('Utilisateur', Colors.blue.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text(
          'Aucun utilisateur trouvé',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
