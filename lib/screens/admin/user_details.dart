import 'package:flutter/material.dart';

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  UserDetailsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '${user['firstName']} ${user['lastName']}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      user['email'],
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Details Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.work, 'Role', user['roles']?.join(', ') ?? 'N/A', colorScheme),
                      Divider(),
                      _buildDetailRow(Icons.verified_user, 'Status', user['isEnabled'] ?? 'N/A', colorScheme),
                      Divider(),
                      _buildDetailRow(Icons.business, 'Department', user['departement'] ?? 'N/A', colorScheme),
                      Divider(),
                      _buildDetailRow(
                        Icons.directions_car,
                        'Driving License',
                        user['drivingLisence'] != null
                            ? (user['drivingLisence'] ? 'Yes' : 'No')
                            : 'N/A',
                        colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Additional Actions
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the update user screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateUserScreen(user: user),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit, color: colorScheme.onPrimary),
                  label: Text(
                    'Edit User',
                    style: TextStyle(fontSize: 16, color: colorScheme.onPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a detail row with an icon
  Widget _buildDetailRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder for UpdateUserScreen
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