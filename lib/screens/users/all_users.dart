import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/users/update_user.dart';
import 'package:pte_mobile/screens/cv/cv_management_screen.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:pte_mobile/screens/users/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({Key? key}) : super(key: key);

  @override
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  List<User> _signupRequests = [];
  List<User> _filteredSignupRequests = [];
  bool _isLoadingUsers = true;
  bool _isLoadingSignupRequests = true;
  String _searchQuery = '';
  String? _selectedRole;
  String? _userTypeFilter;
  int _currentUsersPage = 1;
  int _currentSignupPage = 1;
  final int _itemsPerPage = 6; // 2 rows of 3 images
  int _totalUsersPages = 1;
  int _totalSignupPages = 1;
  bool _isSortAscending = true;
  Map<String, bool> _actionLoading = {};
  late TabController _tabController;
  String? _currentUserRole;
  int _currentIndex = 0;

  final List<String> _roles = ['All', 'ENGINEER', 'ASSISTANT', 'LAB-MANAGER'];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
    _fetchUsers();
    _fetchSignupRequests();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Unknown Role';
      _tabController = TabController(length: _currentUserRole == 'ADMIN' ? 2 : 1, vsync: this);
    });
  }

Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');
      final usersJson = await _userService.fetchUsers();
      if (mounted) {
        setState(() {
          _users = usersJson
              .map((json) => User.fromJson(json))
              .where((user) => user.id != currentUserId)
              .toList();
          _filteredUsers = _users;
          _totalUsersPages = (_filteredUsers.length / _itemsPerPage).ceil();
          _isLoadingUsers = false;
          _actionLoading = {for (var user in _users) user.id: false};
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    }
  }

 
  Future<void> _fetchSignupRequests() async {
    try {
      final requestsJson = await _userService.fetchSignUpRequests();
      if (mounted) {
        setState(() {
          _signupRequests = requestsJson.map((json) => User.fromJson(json)).toList();
          _filteredSignupRequests = _signupRequests;
          _totalSignupPages = (_filteredSignupRequests.length / _itemsPerPage).ceil();
          _isLoadingSignupRequests = false;
          _actionLoading.addAll({for (var user in _signupRequests) user.id: false});
        });
      }
    } catch (e) {
      debugPrint('Error fetching signup requests: $e');
      if (mounted) {
        setState(() => _isLoadingSignupRequests = false);
      }
    }
  }

 void _filterUsers() {
    setState(() {
      final prefs = SharedPreferences.getInstance();
      String? currentUserId;
      prefs.then((p) => currentUserId = p.getString('userId'));
      
      _filteredUsers = _users.where((user) {
        final matchesSearch = '${user.firstName} ${user.lastName} ${user.email}'
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final matchesRole = _selectedRole == null || _selectedRole == 'All' || user.roles.contains(_selectedRole);
        final matchesUserType = _userTypeFilter == null ||
            (_userTypeFilter == 'Internal' && (user.external ?? false) == false) ||
            (_userTypeFilter == 'External' && (user.external ?? false) == true);
        final isNotCurrentUser = user.id != currentUserId;
        return matchesSearch && matchesRole && matchesUserType && isNotCurrentUser;
      }).toList();
      _sortUsers();
      _totalUsersPages = (_filteredUsers.length / _itemsPerPage).ceil();
      _currentUsersPage = 1;
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

  List<User> _getPaginatedUsers() {
    final startIndex = (_currentUsersPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }

  List<User> _getPaginatedSignupRequests() {
    final startIndex = (_currentSignupPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredSignupRequests.sublist(
      startIndex,
      endIndex > _filteredSignupRequests.length ? _filteredSignupRequests.length : endIndex,
    );
  }

  void _deleteUser(String userId, {bool isSignupRequest = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _actionLoading[userId] = true);
      try {
        await _userService.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted successfully!')));
        if (isSignupRequest) {
          await _fetchSignupRequests();
        } else {
          await _fetchUsers();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
      } finally {
        setState(() => _actionLoading[userId] = false);
      }
    }
  }

  void _switchToExternal(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch to External'),
        content: const Text('Are you sure you want to switch this user to external?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _actionLoading[userId] = true);
      try {
        await _userService.switchUserToExternal(userId);
        final userIndex = _users.indexWhere((u) => u.id == userId);
        if (userIndex != -1) {
          setState(() {
            _users[userIndex] = _users[userIndex].copyWith(external: true);
            _filterUsers();
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User switched to external successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to switch user: $e')));
      } finally {
        setState(() => _actionLoading[userId] = false);
      }
    }
  }

  void _confirmSignup(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Signup'),
        content: const Text('Are you sure you want to confirm this signup request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _actionLoading[userId] = true);
      try {
        await _userService.confirmSignUp(userId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User signup confirmed successfully!')));
        await _fetchSignupRequests();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to confirm signup: $e')));
      } finally {
        setState(() => _actionLoading[userId] = false);
      }
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _fetchUsers();
    } else {
      _fetchSignupRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _currentUserRole == 'ADMIN' ? 2 : 1,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        drawer: _currentUserRole == 'ADMIN'
            ? AdminSidebar(
                currentIndex: _currentIndex,
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                    _handleTabChange(index);
                  });
                },
              )
            : _currentUserRole == 'LAB-MANAGER'
                ? LabManagerSidebar(
                    currentIndex: _currentIndex,
                    onTabChange: (index) {
                      setState(() {
                        _currentIndex = index;
                        _handleTabChange(index);
                      });
                    },
                  )
                : _currentUserRole == 'ENGINEER'
                    ? EngineerSidebar(
                        currentIndex: _currentIndex,
                        onTabChange: (index) {
                          setState(() {
                            _currentIndex = index;
                            _handleTabChange(index);
                          });
                        },
                      )
                    : AssistantSidebar(
                        currentIndex: _currentIndex,
                        onTabChange: (index) {
                          setState(() {
                            _currentIndex = index;
                            _handleTabChange(index);
                          });
                        },
                      ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Column(
              children: [
                _buildHeader(context),
                TabBar(
                  controller: _tabController,
                  tabs: _currentUserRole == 'ADMIN'
                      ? const [Tab(text: 'All Users'), Tab(text: 'Signup Requests')]
                      : const [Tab(text: 'All Users')],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600),
                  onTap: (index) {
                    _handleTabChange(index);
                  },
                ),
                if (_tabController.index == 0) ...[
                  _buildFilterRow(),
                  _buildSearchBar(),
                ],
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _isLoadingUsers
                          ? _buildSkeletonLoader(isSmallScreen)
                          : _filteredUsers.isEmpty
                              ? _buildEmptyState(isSignupTab: false)
                              : RefreshIndicator(
                                  onRefresh: _fetchUsers,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isSmallScreen ? 2 : 3,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _getPaginatedUsers().length,
                                    itemBuilder: (context, index) {
                                      final user = _getPaginatedUsers()[index];
                                      return _buildUserCard(user, isSignupRequest: false)
                                          .animate()
                                          .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                                          .slideY(begin: 0.1, delay: (50 * index).ms);
                                    },
                                  ),
                                ),
                      if (_currentUserRole == 'ADMIN')
                        _isLoadingSignupRequests
                            ? _buildSkeletonLoader(isSmallScreen)
                            : _filteredSignupRequests.isEmpty
                                ? _buildEmptyState(isSignupTab: true)
                                : RefreshIndicator(
                                    onRefresh: _fetchSignupRequests,
                                    child: GridView.builder(
                                      padding: const EdgeInsets.all(16),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isSmallScreen ? 2 : 3,
                                        childAspectRatio: 0.75,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      itemCount: _getPaginatedSignupRequests().length,
                                      itemBuilder: (context, index) {
                                        final user = _getPaginatedSignupRequests()[index];
                                        return _buildUserCard(user, isSignupRequest: true)
                                            .animate()
                                            .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                                            .slideY(begin: 0.1);
                                      },
                                    ),
                                  ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const Spacer(),
              const Text(
                'User Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  if (_tabController.index == 0) _fetchUsers();
                  else _fetchSignupRequests();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _tabController.index == 0
                ? 'You have ${_filteredUsers.length} users'
                : 'You have ${_filteredSignupRequests.length} signup requests',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                hint: const Text('Role', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                    _filterUsers();
                  });
                },
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: Icon(Icons.arrow_drop_down, size: 24, color: Theme.of(context).colorScheme.primary),
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
                    onTap: () => setState(() {
                      _userTypeFilter = 'Internal';
                      _filterUsers();
                    }), 
                    isSelected: _userTypeFilter == 'Internal', 
                    icon: Icons.person
                  ),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    title: 'External', 
                    onTap: () => setState(() {
                      _userTypeFilter = 'External';
                      _filterUsers();
                    }), 
                    isSelected: _userTypeFilter == 'External', 
                    icon: Icons.public
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

  Widget _buildFilterButton({required String title, required VoidCallback? onTap, bool isSelected = false, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)]
                : [Colors.grey[100]!, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search users...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filterUsers();
                      });
                    })
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

  Widget _buildUserCard(User user, {required bool isSignupRequest}) {
    final isExternal = user.external ?? false;
    final isAdmin = _currentUserRole == 'ADMIN';
    final isRestrictedRole = _currentUserRole != null && ['LAB-MANAGER', 'ENGINEER', 'ASSISTANT'].contains(_currentUserRole);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).colorScheme.background,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.background,
                    Theme.of(context).colorScheme.background.withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header with avatar and name
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          user.image != null
                              ? '${Env.userImageBaseUrl}${user.image}'
                              : 'https://ui-avatars.com/api/?name=${user.firstName}+${user.lastName}&background=${Theme.of(context).colorScheme.primary.value.toRadixString(16).substring(2)}&color=fff',
                        ),
                        backgroundColor: Colors.white,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.roles.first),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _getRoleIcon(user.roles.first),
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${user.firstName} ${user.lastName}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.roles.isNotEmpty && !isRestrictedRole) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.roles.first),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.roles.first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User details
                  _buildDetailRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: user.email,
                    context: context,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.apartment,
                    label: 'Department',
                    value: user.departement ?? 'No department',
                    context: context,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: user.phone ?? 'No phone number',
                    context: context,
                  ),
                  if (user.roles.length > 1 && !isRestrictedRole) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.badge,
                      label: 'Other Roles',
                      value: user.roles.sublist(1).join(', '),
                      context: context,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Action buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: _buildActionButton(
                              icon: Icons.person_outline,
                              label: 'Profile',
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => UserProfileScreen(userId: user.id)),
                                );
                              },
                            ),
                          ),
                          if (isAdmin && !isSignupRequest && !isExternal) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: _buildActionButton(
                                icon: _actionLoading[user.id] ?? false ? Icons.hourglass_empty : Icons.swap_horiz,
                                label: 'Switch',
                                color: Colors.blueAccent,
                                onPressed: _actionLoading[user.id] ?? false ? null : () => _switchToExternal(user.id),
                                isLoading: _actionLoading[user.id] ?? false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _buildActionButton(
                                icon: _actionLoading[user.id] ?? false ? Icons.hourglass_empty : Icons.edit,
                                label: 'Update',
                                color: Colors.orange,
                                onPressed: _actionLoading[user.id] ?? false
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => UpdateUserScreen(user: user)),
                                        );
                                      },
                                isLoading: _actionLoading[user.id] ?? false,
                              ),
                            ),
                          ],
                          if (isSignupRequest && isAdmin) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: _buildActionButton(
                                icon: _actionLoading[user.id] ?? false ? Icons.hourglass_empty : Icons.check,
                                label: 'Confirm',
                                color: Colors.green,
                                onPressed: _actionLoading[user.id] ?? false ? null : () => _confirmSignup(user.id),
                                isLoading: _actionLoading[user.id] ?? false,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.background.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    user.image != null
                        ? '${Env.userImageBaseUrl}${user.image}'
                        : 'https://ui-avatars.com/api/?name=${user.firstName}+${user.lastName}&background=${Theme.of(context).colorScheme.primary.value.toRadixString(16).substring(2)}&color=fff',
                  ),
                  backgroundColor: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    String? value,
    required BuildContext context,
    double fontSize = 14,
    int maxLines = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: fontSize + 4,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    value ?? 'N/A',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        minimumSize: const Size(0, 40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
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

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.security;
      case 'engineer':
        return Icons.build;
      case 'assistant':
        return Icons.support_agent;
      case 'lab-manager':
        return Icons.science;
      default:
        return Icons.person;
    }
  }

  Widget _buildSkeletonLoader(bool isSmallScreen) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 80,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
        ).animate().shimmer(duration: 1.seconds);
      },
    );
  }

  Widget _buildEmptyState({required bool isSignupTab}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isSignupTab ? 'No Signup Requests Found' : 'No Users Found',
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
              isSignupTab
                  ? 'There are no pending signup requests.'
                  : _searchQuery.isEmpty
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}