import 'package:flutter/material.dart';
import 'package:pte_mobile/screens/admin/admin_sidebar.dart';
import 'package:pte_mobile/screens/admin/user_details.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final UserService _userService = UserService();

  List users = [];
  List drivers = [];
  List signUpRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showSignUpRequests = false;
  bool _showDrivers = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('authToken');

      if (token == null) {
        setState(() {
          _errorMessage = 'Token not available. Please login again.';
          _isLoading = false;
        });
        return;
      }

      List fetchedUsers = _showSignUpRequests
          ? await _userService.fetchSignUpRequests()
          : await _userService.fetchUsers();

      setState(() {
        users = fetchedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching users: $e';
      });
    }
  }

  Future<void> _confirmSignUp(String userId) async {
    try {
      bool success = await _userService.confirmSignUp(userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User approved successfully!')),
        );
        _loadUsers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve user: $e')),
      );
      print('Error while confirming sign-up: $e');
    }
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      drivers = await _userService.fetchDrivers();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching drivers: $e';
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      bool success = await _userService.deleteUser(userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted successfully!')),
        );
        _loadUsers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
      print('Error while deleting user: $e');
    }
  }

  void _openAddExternalUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String fname = '';
        String lname = '';
        String departement = '';
        List<String> filePaths = [];

        return AlertDialog(
          title: Text('Add External User', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'First Name'),
                  onChanged: (value) => fname = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Last Name'),
                  onChanged: (value) => lname = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Department'),
                  onChanged: (value) => departement = value,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // TODO: Implement file picker for PDFs and images
                    filePaths = ['/path/to/file1.pdf', '/path/to/file2.png'];
                  },
                  child: Text('Upload Files'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fname.isEmpty || lname.isEmpty || departement.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                Map<String, dynamic> userData = {
                  'fname': fname,
                  'lname': lname,
                  'departement': departement,
                };

                await _userService.addExternalUser(userData, filePaths);
                Navigator.pop(context);
              },
              child: Text('Add User'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Admin Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.blueGrey.withOpacity(0.2),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blueGrey),
            onPressed: _loadUsers,
          ),
        ],
      ),
      drawer: AdminSidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            SizedBox(height: 20),

            // Toggle Buttons
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
                ],
              ),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(30),
                isSelected: [
                  !_showSignUpRequests && !_showDrivers,
                  _showSignUpRequests,
                  _showDrivers,
                ],
                fillColor: Colors.blue,
                selectedColor: Colors.white,
                color: Colors.blueGrey,
                borderWidth: 0,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("Users", style: TextStyle(fontSize: 16)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("Sign-Up Requests", style: TextStyle(fontSize: 16)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text("Drivers", style: TextStyle(fontSize: 16)),
                  ),
                ],
                onPressed: (int index) {
                  setState(() {
                    _showSignUpRequests = index == 1;
                    _showDrivers = index == 2;
                  });
                  if (_showDrivers) {
                    _loadDrivers();
                  } else {
                    _loadUsers();
                  }
                },
              ),
            ),
            SizedBox(height: 20),

            // User List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16)))
                      : ListView.separated(
                          itemCount: _showDrivers ? drivers.length : users.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            var user = _showDrivers ? drivers[index] : users[index];

                            // Filter users based on search query
                            if (_searchQuery.isNotEmpty &&
                                !user['firstName'].toLowerCase().contains(_searchQuery) &&
                                !user['lastName'].toLowerCase().contains(_searchQuery) &&
                                !user['email'].toLowerCase().contains(_searchQuery) &&
                                !user['roles'].join(', ').toLowerCase().contains(_searchQuery)) {
                              return SizedBox.shrink(); // Hide non-matching items
                            }

                            return Dismissible(
                              key: Key(user['_id']),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Confirm Delete'),
                                      content: Text('Are you sure you want to delete this user?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('Cancel', style: TextStyle(color: Colors.red)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) {
                                _deleteUser(user['_id']);
                              },
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Text(user['firstName'][0], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text('${user['firstName']} ${user['lastName']}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                                  subtitle: Text(
                                      _showDrivers
                                          ? 'Driving License: ${user['drivingLisence']}'
                                          : 'Role: ${user['roles'].join(', ')} | Status: ${user['isEnabled']}',
                                      style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.info, color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
        builder: (context) => UserDetailsScreen(user: user),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => UpdateUserScreen(user: user),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.swap_horiz, color: Colors.green),
                                        onPressed: () {
                                          _userService.switchUserToExternal(user['_id']);
                                          _loadUsers();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExternalUserDialog,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blueAccent,
        elevation: 6,
      ),
    );
  }
}

class UpdateUserScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  UpdateUserScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update user details here'),
            // Add form fields for updating user details
          ],
        ),
      ),
    );
  }
}