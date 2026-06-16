import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/admin_stats.dart';
import '../../../services/admin_service.dart';

// Seuil en dessous duquel on bascule en mode cartes (mobile)
const double _kMobileBreakpoint = 600;

(Color bg, Color fg, String label, IconData icon) _roleStyle(String role) =>
    switch (role) {
      'admin'       => (Colors.red.shade50,    Colors.red.shade700,   'Admin',      Icons.shield),
      'contributor' => (Colors.green.shade50,  Colors.green.shade700, 'Contrib.',   Icons.edit),
      'register'    => (Colors.grey.shade100,  Colors.grey.shade600,  'En attente', Icons.hourglass_empty),
      _             => (Colors.blue.shade50,   Colors.blue.shade700,  'Utilisateur',Icons.person),
    };

String _initials(String? username, String email) {
  final name = username ?? email;
  final parts = name.trim().split(RegExp(r'[\s_\-\.]+'));
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
}

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/'
    '${dt.month.toString().padLeft(2, '0')}/'
    '${dt.year}';

String _formatRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24)   return 'il y a ${diff.inHours}h';
  if (diff.inDays == 1)    return 'hier';
  if (diff.inDays < 30)    return 'il y a ${diff.inDays} jours';
  if (diff.inDays < 365)   return 'il y a ${(diff.inDays / 30).round()} mois';
  return 'il y a ${(diff.inDays / 365).round()} an(s)';
}

/// Section "Liste des inscrits" du dashboard admin.
/// Bascule automatiquement entre tableau (desktop) et cartes (mobile).
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
        if (_isLoading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _ErrorView(error: _error!, onRetry: _loadUsers)
        else if (_users.isEmpty)
          const _EmptyView()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _kMobileBreakpoint) {
                return _UserCardList(users: _users);
              }
              return Card(
                child: _UserTable(
                  users: _users,
                  sortBy: _sortBy,
                  sortDesc: _sortDesc,
                  onSort: _onSort,
                ),
              );
            },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Liste des inscrits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (totalCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE67E22),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher par pseudo ou email…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: ListenableBuilder(
              listenable: searchController,
              builder: (_, __) => searchController.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: searchController.clear,
                    ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode CARTE — mobile (< 600px)
// ─────────────────────────────────────────────────────────────────────────────

class _UserCardList extends StatelessWidget {
  const _UserCardList({required this.users});

  final List<AdminUserListEntry> users;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _UserCard(user: users[index]),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AdminUserListEntry user;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, roleLabel, roleIcon) = _roleStyle(user.role);
    final initials = _initials(user.username, user.email);
    final displayName = user.username ?? user.email.split('@').first;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar coloré selon le rôle
            CircleAvatar(
              radius: 22,
              backgroundColor: bgColor,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge rôle
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: fgColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 11, color: fgColor),
                            const SizedBox(width: 3),
                            Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: fgColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(user.createdAt),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                      if (user.lastSignInAt != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.access_time,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _formatRelative(user.lastSignInAt!),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode TABLEAU — desktop (≥ 600px)
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
        dataRowMinHeight: 58,
        dataRowMaxHeight: 68,
        columnSpacing: 20,
        dividerThickness: 0.5,
        columns: [
          DataColumn(
            label: const Text('Utilisateur'),
            onSort: (_, __) => onSort('username'),
          ),
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
        rows: users.map(_buildRow).toList(),
      ),
    );
  }

  DataRow _buildRow(AdminUserListEntry u) {
    final (bgColor, fgColor, _, _) = _roleStyle(u.role);
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return bgColor.withValues(alpha: 0.5);
        }
        return null;
      }),
      cells: [
        DataCell(_UsernameCell(
          username: u.username,
          email: u.email,
          avatarBg: bgColor,
          avatarFg: fgColor,
        )),
        DataCell(_RoleBadge(role: u.role)),
        DataCell(
          Text(
            _formatDate(u.createdAt),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            u.lastSignInAt != null ? _formatRelative(u.lastSignInAt!) : '—',
            style: TextStyle(
              fontSize: 13,
              color: u.lastSignInAt != null ? null : Colors.grey,
            ),
          ),
        ),
      ],
    );
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
  const _UsernameCell({
    required this.username,
    required this.email,
    required this.avatarBg,
    required this.avatarFg,
  });

  final String? username;
  final String email;
  final Color avatarBg;
  final Color avatarFg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: avatarBg,
          child: Text(
            _initials(username, email),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: avatarFg,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username ?? email.split('@').first,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            if (username != null)
              Text(
                email,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, label, icon) = _roleStyle(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
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
    return Card(
      child: Padding(
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
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
