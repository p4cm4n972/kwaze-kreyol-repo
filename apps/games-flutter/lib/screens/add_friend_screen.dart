import 'package:flutter/material.dart';
import '../models/user_search_result.dart';
import '../services/friends_service.dart';
import '../services/auth_service.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen>
    with SingleTickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  List<UserSearchResult> _searchResults = [];
  UserSearchResult? _codeSearchResult;
  bool _isSearching = false;
  String? _myFriendCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyFriendCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyFriendCode() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _myFriendCode = user?.friendCode;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _searchByUsername() async {
    final query = _usernameController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _friendsService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _searchByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le code doit contenir 6 caractères')),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final result = await _friendsService.searchByFriendCode(code);
      if (mounted) {
        setState(() {
          _codeSearchResult = result;
          _isSearching = false;
        });

        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun utilisateur trouvé avec ce code'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _sendRequest(String userId, String username) async {
    try {
      await _friendsService.sendFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Demande envoyée à $username')));
        // Refresh search
        if (_tabController.index == 0) {
          _searchByUsername();
        } else {
          _searchByCode();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un ami'),
        backgroundColor: const Color(0xFFFFD700),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Par nom', icon: Icon(Icons.search)),
            Tab(text: 'Par code', icon: Icon(Icons.qr_code)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUsernameSearch(), _buildCodeSearch()],
      ),
    );
  }

  Widget _buildUsernameSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Nom d\'utilisateur...',
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchByUsername,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onSubmitted: (_) => _searchByUsername(),
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? _buildEmptySearchState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) =>
                      _buildUserCard(_searchResults[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildCodeSearch() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // My friend code
          if (_myFriendCode != null) ...[
            Card(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Mon code ami',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _myFriendCode!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Partagez ce code avec vos amis',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Search by code
          const Text(
            'Rechercher par code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: 'Entrez le code à 6 caractères',
              prefixIcon: const Icon(Icons.qr_code),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _searchByCode(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _searchByCode,
            icon: const Icon(Icons.search),
            label: const Text('Rechercher'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_codeSearchResult != null)
            _buildUserCard(_codeSearchResult!),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Recherchez des amis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Entrez un nom d\'utilisateur pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserSearchResult user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(user.username[0].toUpperCase())
              : null,
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: user.friendCode != null
            ? Text('Code: ${user.friendCode}')
            : null,
        trailing: _buildTrailingButton(user),
      ),
    );
  }

  Widget _buildTrailingButton(UserSearchResult user) {
    if (user.isFriend) {
      return const Chip(
        label: Text('Ami'),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    if (user.hasPendingRequest) {
      return const Chip(
        label: Text('En attente'),
        backgroundColor: Colors.orange,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _sendRequest(user.userId, user.username),
      icon: const Icon(Icons.person_add, size: 16),
      label: const Text('Ajouter'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
