import 'package:flutter/material.dart';
import 'package:pte_mobile/widgets/theme_toggle_button.dart';
import 'package:pte_mobile/widgets/assistant_navbar.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';

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
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: colorScheme.onPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: colorScheme.onPrimary,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: colorScheme.background.withOpacity(0.98),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ListView(
            children: [
              _buildSectionTitle(
                title: 'Account',
                icon: Icons.account_circle,
                colorScheme: colorScheme,
              ),
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

              _buildSectionTitle(
                title: 'Preferences',
                icon: Icons.settings,
                colorScheme: colorScheme,
              ),
              _buildSection(
                title: 'Security',
                icon: Icons.lock,
                onTap: () => Navigator.pushNamed(context, '/update-password'),
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

              _buildSectionTitle(
                title: 'Information',
                icon: Icons.info_outline,
                colorScheme: colorScheme,
              ),
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
      ),
      bottomNavigationBar: AssistantNavbar(
        currentIndex: _currentIndex,
        onTabChange: _onTabChange,
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: colorScheme.onBackground.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onBackground,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithToggle({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const ThemeToggleButton(),
        ],
      ),
    );
  }

  Widget _buildModernSeparator({required ColorScheme colorScheme}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14.0),
      height: 1,
      color: colorScheme.onBackground.withOpacity(0.15),
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
          elevation: 4,
          shadowColor: colorScheme.error.withOpacity(0.3),
        ),
        onPressed: () async {
          await _authService.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: 20,
              color: colorScheme.onError,
            ),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onError,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}