// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:pte_mobile/widgets/theme_toggle_button.dart';
import 'package:pte_mobile/widgets/assistant_navbar.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'labmanager/request_lab.dart';
import 'labmanager/requests_by_user_id.dart'; // Add this import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 4; // Index 4 for Settings tab

  void _onTabChange(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          title: Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: colorScheme.onPrimary,
            ),
          ),
          backgroundColor: colorScheme.primary,
          elevation: 0,
        ),
      ),
      backgroundColor: colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
        child: ListView(
          children: [
            _buildSectionTitle(title: 'Account', icon: Icons.account_circle, colorScheme: colorScheme),
            _buildSection(
              title: 'Profile',
              icon: Icons.person,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              ),
              colorScheme: colorScheme,
            ),
            _buildModernSeparator(colorScheme: colorScheme),

            _buildSectionTitle(title: 'Preferences', icon: Icons.settings, colorScheme: colorScheme),
            _buildSection(
              title: 'Security',
              icon: Icons.lock,
              onTap: () {},
              colorScheme: colorScheme,
            ),
            _buildSection(
              title: 'Notifications',
              icon: Icons.notifications,
              onTap: () {},
              colorScheme: colorScheme,
            ),
            _buildSectionWithToggle(
              title: 'Theme',
              icon: Icons.brightness_6,
              colorScheme: colorScheme,
            ),
            _buildModernSeparator(colorScheme: colorScheme),

            _buildSectionTitle(title: 'Lab and Virtualisation', icon: Icons.computer, colorScheme: colorScheme),
            _buildSection(
              title: 'Request Lab',
              icon: Icons.science,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RequestLabScreen()),
              ),
              colorScheme: colorScheme,
            ),
            _buildSection(
              title: 'Check My Requests',
              icon: Icons.cloud,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RequestsByUserId()),
              ),
              colorScheme: colorScheme,
            ),
            _buildModernSeparator(colorScheme: colorScheme),

            _buildSectionTitle(title: 'Information', icon: Icons.info_outline, colorScheme: colorScheme),
            _buildSection(
              title: 'Privacy',
              icon: Icons.privacy_tip,
              onTap: () {},
              colorScheme: colorScheme,
            ),
            _buildSection(
              title: 'About',
              icon: Icons.info,
              onTap: () {},
              colorScheme: colorScheme,
            ),
            _buildModernSeparator(colorScheme: colorScheme),

            _buildSignOutButton(context, colorScheme),
          ],
        ),
      ),
      bottomNavigationBar: AssistantNavbar(
        currentIndex: _currentIndex,
        onTabChange: _onTabChange,
      ),
    );
  }

  // [Helper methods unchanged]
  Widget _buildSectionTitle({required String title, required IconData icon, required ColorScheme colorScheme}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.onBackground.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required VoidCallback onTap, required ColorScheme colorScheme}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 30, color: colorScheme.primary),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 20, color: colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionWithToggle({required String title, required IconData icon, required ColorScheme colorScheme}) {
    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: colorScheme.primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            const ThemeToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSeparator({required ColorScheme colorScheme}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, colorScheme.onBackground.withOpacity(0.2), Colors.transparent],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onBackground.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () async {
          await _authService.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
        child: Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onError,
          ),
        ),
      ),
    );
  }
}