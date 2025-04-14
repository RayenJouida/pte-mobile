import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pte_mobile/screens/admin/post_panel.dart';
import 'package:pte_mobile/screens/admin/room_panel.dart';
import 'package:pte_mobile/screens/admin/vehicle_panel.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Colors.grey),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: FontAwesomeIcons.users,
                    title: 'Manage Users',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/users');
                    },
                  ),
                  _buildMenuItem(
                    icon: FontAwesomeIcons.pen,
                    title: 'Posts Panel',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PostPanel()));
                    },
                  ),
                  _buildMenuItem(
                    icon: FontAwesomeIcons.chartPie,
                    title: 'Room Panel',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomPanel()));
                    },
                  ),
                  _buildMenuItem(
                    icon: FontAwesomeIcons.car,
                    title: 'Vehicle Panel',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclePanel()));
                    },
                  ),
                  _buildMenuItem(
                    icon: FontAwesomeIcons.cogs,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  _buildMenuItem(
                    icon: FontAwesomeIcons.signOutAlt,
                    title: 'Logout',
                    isLogout: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(FontAwesomeIcons.userShield, size: 30, color: Colors.blue),
          ),
          const SizedBox(height: 12),
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage Prologic',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: FaIcon(icon, color: isLogout ? Colors.red.shade600 : Colors.blue.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red.shade600 : Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}