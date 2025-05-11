import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/screens/users/user_infos.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:quickalert/quickalert.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({Key? key}) : super(key: key);

  @override
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final UserService _userService = UserService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedRole;
  String? _userTypeFilter;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _itemsPerPage = 4;
  int _totalPages = 1;
  bool _isSortAscending = true;
  Map<String, bool> _actionLoading = {};

  final List<String> _roles = ['All', 'ADMIN', 'ENGINEER', 'ASSISTANT', 'LAB-MANAGER'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final usersJson = await _userService.fetchUsers();
      if (mounted) {
        setState(() {
          _users = usersJson.map((json) => User.fromJson(json)).toList();
          _filteredUsers = _users;
          _totalPages = (_filteredUsers.length / _itemsPerPage).ceil();
          _isLoading = false;
          _actionLoading = { for (var user in _users) user.id : false };
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = '${user.firstName} ${user.lastName} ${user.email}'
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());

        final matchesRole = _selectedRole == null ||
            _selectedRole == 'All' ||
            user.roles.contains(_selectedRole);

        final matchesUserType = _userTypeFilter == null ||
            (_userTypeFilter == 'Internal' && (user.external ?? false) == false) ||
            (_userTypeFilter == 'External' && (user.external ?? false) == true);

        return matchesSearch && matchesRole && matchesUserType;
      }).toList();

      _sortUsers();
      _totalPages = (_filteredUsers.length / _itemsPerPage).ceil();
      _currentPage = 1;
    });
  }

  void _sortUsers() {
    _filteredUsers.sort((a, b) {
      final nameA = '${a.firstName} ${a.lastName}'.toLowerCase();
      final nameB = '${b.firstName} ${b.lastName}'.toLowerCase();
      return _isSortAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
    });
  }

  void _toggleSortOrder() {
    setState(() {
      _isSortAscending = !_isSortAscending;
      _sortUsers();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Infinite scroll could be implemented here if needed
    }
  }

  List<User> _getPaginatedUsers() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }

  void _deleteUser(String userId) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Delete User',
      text: 'Are you sure you want to delete this user?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: Colors.redAccent,
      onConfirmBtnTap: () async {
        Navigator.of(context).pop();
        setState(() {
          _actionLoading[userId] = true;
        });
        try {
          await _userService.deleteUser(userId);
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Success',
            text: 'User deleted successfully!',
          );
          await _fetchUsers();
        } catch (e) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: 'Failed to delete user: $e',
          );
        } finally {
          setState(() {
            _actionLoading[userId] = false;
          });
        }
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  void _switchToExternal(String userId) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Switch to External',
      text: 'Are you sure you want to switch this user to external?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: Colors.blueAccent,
      onConfirmBtnTap: () async {
        Navigator.of(context).pop();
        setState(() {
          _actionLoading[userId] = true;
        });
        try {
          await _userService.switchUserToExternal(userId);
          // Update the user's external status in the local list
          final userIndex = _users.indexWhere((u) => u.id == userId);
          if (userIndex != -1) {
            _users[userIndex] = _users[userIndex].copyWith(external: true);
            _filterUsers(); // Reapply filters to update _filteredUsers
          }
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Success',
            text: 'User switched to external successfully!',
          );
        } catch (e) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: 'Failed to switch user: $e',
          );
        } finally {
          setState(() {
            _actionLoading[userId] = false;
          });
        }
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginatedUsers = _getPaginatedUsers();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilterRow(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: paginatedUsers.length,
                                itemBuilder: (context, index) {
                                  final user = paginatedUsers[index];
                                  return _buildUserCard(user)
                                      .animate()
                                      .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                                      .slideY(begin: 0.1, delay: (50 * index).ms);
                                },
                              ),
                            ),
                            _buildPaginationControls(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Text(
                'All Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchUsers,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have ${_filteredUsers.length} users',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedRole,
                hint: const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role == 'All' ? null : role,
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                    _filterUsers();
                  });
                },
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                isExpanded: true,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _buildFilterButton(
                    title: 'Internal',
                    onTap: () {
                      setState(() {
                        _userTypeFilter = 'Internal';
                        _filterUsers();
                      });
                    },
                    isSelected: _userTypeFilter == 'Internal',
                    icon: Icons.person,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    title: 'External',
                    onTap: () {
                      setState(() {
                        _userTypeFilter = 'External';
                        _filterUsers();
                      });
                    },
                    isSelected: _userTypeFilter == 'External',
                    icon: Icons.public,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildFilterButton(
                    title: 'A-Z',
                    onTap: _isSortAscending ? null : _toggleSortOrder,
                    isSelected: _isSortAscending,
                    icon: Icons.sort_by_alpha,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    title: 'Z-A',
                    onTap: !_isSortAscending ? null : _toggleSortOrder,
                    isSelected: !_isSortAscending,
                    icon: Icons.sort_by_alpha,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String title,
    required VoidCallback? onTap,
    bool isSelected = false,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ]
                : [
                    Colors.grey[100]!,
                    Colors.grey[200]!,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search users...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterUsers();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _filterUsers();
            });
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final isExternal = user.external ?? false; // Treat null as false

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isExternal
                  ? [Colors.grey[400]!, Colors.grey[500]!]
                  : [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Status Indicator
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(
                              user.image != null
                                  ? '${Env.userImageBaseUrl}${user.image}'
                                  : 'https://ui-avatars.com/api/?name=${user.firstName}+${user.lastName}&background=${Theme.of(context).colorScheme.primary.value.toRadixString(16).substring(2)}&color=fff',
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user.isEnabled == 'Active' ? Colors.green : Colors.red,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              user.isEnabled == 'Active' ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isExternal ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.roles.isNotEmpty)
                                Chip(
                                  label: Text(
                                    user.roles.first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: _getRoleColor(user.roles.first),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: isExternal ? Colors.white70 : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Additional Info Section
                Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 18,
                      color: isExternal ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.department ?? 'No Department',
                        style: TextStyle(
                          fontSize: 14,
                          color: isExternal ? Colors.white : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 18,
                      color: isExternal ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.phone ?? 'No Phone Number',
                        style: TextStyle(
                          fontSize: 14,
                          color: isExternal ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (user.roles.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.badge,
                        size: 18,
                        color: isExternal ? Colors.white : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Other Roles: ${user.roles.sublist(1).join(', ')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isExternal ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: isExternal ? Colors.white30 : Colors.grey),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: (_actionLoading[user.id] ?? false) || isExternal
                          ? null
                          : () => _switchToExternal(user.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExternal
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _actionLoading[user.id] ?? false
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz,
                                  size: 18,
                                  color: isExternal ? Colors.white70 : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isExternal ? 'Already External' : 'Switch to External',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isExternal ? Colors.white70 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _actionLoading[user.id] ?? false
                          ? null
                          : () => _deleteUser(user.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _actionLoading[user.id] ?? false
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.redAccent;
      case 'engineer':
        return Colors.blueAccent;
      case 'assistant':
        return Colors.green;
      case 'lab-manager':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 20,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 200,
                            height: 14,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 160,
                  height: 14,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 14,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ).animate().shimmer(duration: 1.seconds);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No Users Found' : 'No Matching Users',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchQuery.isEmpty
                  ? 'There are no users available yet.'
                  : 'No users match your search criteria.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          ...List.generate(_totalPages, (index) {
            final pageNumber = index + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentPage = pageNumber;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _currentPage == pageNumber
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$pageNumber',
                    style: TextStyle(
                      color: _currentPage == pageNumber
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: _currentPage == pageNumber
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}