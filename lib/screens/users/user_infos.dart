import 'package:flutter/material.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/screens/users/update_user.dart';
import '../../theme/theme.dart';
import 'package:pte_mobile/config/env.dart';

class UserInfoScreen extends StatefulWidget {
  final String userId;

  const UserInfoScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final userJson = await _userService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = User.fromJson(userJson);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    try {
      await _userService.deleteUser(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User deleted successfully'),
            backgroundColor: lightColorScheme.primary.withOpacity(0.85),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: lightColorScheme.error),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: lightColorScheme.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser();
            },
            child: Text('Delete', style: TextStyle(color: lightColorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        backgroundColor: lightColorScheme.surface,
        elevation: 0,
        foregroundColor: lightColorScheme.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: lightColorScheme.primary.withOpacity(0.2)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: lightColorScheme.primary))
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: lightColorScheme.error.withOpacity(0.6)),
                      const SizedBox(height: 12),
                      Text('User not found', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            _user!.image != null
                                ? '${Env.userImageBaseUrl}${_user!.image}'
                                : 'https://ui-avatars.com/api/?name=${_user!.firstName}+${_user!.lastName}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${_user!.firstName} ${_user!.lastName}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _user!.email,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoTile('Matricule', _user!.matricule),
                      _buildInfoTile('Roles', _user!.roles.join(', ')),
                      _buildInfoTile('Team Leader', _user!.teamLeader?.toString() ?? 'N/A'),
                      _buildInfoTile('Phone', _user!.phone ?? 'N/A'),
                      _buildInfoTile('Nationality', _user!.nationality ?? 'N/A'),
                      _buildInfoTile('FS', _user!.fs ?? 'N/A'),
                      _buildInfoTile('Bio', _user!.bio ?? 'N/A'),
                      _buildInfoTile('Birth Date', _user!.birthDate?.toString() ?? 'N/A'),
                      _buildInfoTile('Address', _user!.address ?? 'N/A'),
                      _buildInfoTile('Department', _user!.department ?? 'N/A'),
                      _buildInfoTile('Driving License', _user!.drivingLicense?.toString() ?? 'N/A'),
                      _buildInfoTile('Gender', _user!.gender ?? 'N/A'),
                      _buildInfoTile('Status', _user!.isEnabled),
                      _buildInfoTile('Experience', '${_user!.experience} years'),
                      _buildInfoTile('Hiring Date', _user!.hiringDate?.toString() ?? 'N/A'),
                      _buildInfoTile('Title', _user!.title ?? 'N/A'),
                      _buildInfoTile('GitHub', _user!.github ?? 'N/A'),
                      _buildInfoTile('LinkedIn', _user!.linkedin ?? 'N/A'),
                      _buildInfoTile('CV', _user!.cv ?? 'N/A'),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _confirmDelete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightColorScheme.error,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UpdateUserScreen(user: _user!)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightColorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: lightColorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Flexible(child: Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          ],
        ),
      ),
    );
  }
}