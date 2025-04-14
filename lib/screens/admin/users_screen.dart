import 'package:flutter/material.dart';
import '../../services/user_service.dart'; // Import your UserService
import 'package:shared_preferences/shared_preferences.dart';

class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService(); // Initialize UserService

  List users = []; // List to store fetched users
  bool _isLoading = true; // Loading state
  String? _errorMessage; // Error message
  bool _showSignUpRequests = false; // Toggle between users and sign-up requests

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Fetch users when the screen loads
  }

  // Fetch users or sign-up requests based on the toggle state
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

      // Fetch users or sign-up requests based on the toggle state
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

  // Confirm a sign-up request
  Future<void> _confirmSignUp(String userId) async {
    try {
      bool success = await _userService.confirmSignUp(userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User approved successfully!')),
        );
        _loadUsers(); // Refresh the list after confirmation
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve user: $e')),
      );
      print('Error while confirming sign-up: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showSignUpRequests ? 'Sign-Up Requests' : 'Users'),
        actions: [
          // Toggle button in the app bar
          IconButton(
            icon: Icon(_showSignUpRequests ? Icons.people : Icons.person_add),
            onPressed: () {
              setState(() {
                _showSignUpRequests = !_showSignUpRequests;
              });
              _loadUsers(); // Reload data when toggling
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          var user = users[index];
                          return ListTile(
                            title: Text('${user['firstName']} ${user['lastName']}'),
                            subtitle: Text('Role: ${user['roles'].join(', ')}\nStatus: ${user['isEnabled']}'),
                            trailing: _showSignUpRequests
                                ? IconButton(
                                    icon: Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _confirmSignUp(user['_id']),
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}