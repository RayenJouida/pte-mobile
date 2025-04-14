import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // Import Google Nav Bar
import 'package:line_icons/line_icons.dart'; // Import Line Icons
import 'package:pte_mobile/screens/labmanager/lab_request.dart';
import '../settings_screen.dart'; // Import the SettingsScreen
import 'package:pte_mobile/screens/messaging/home_messages_screen.dart'; // Import the MessagingScreen

class LabManagerBottomNavigationBar extends StatefulWidget {
  const LabManagerBottomNavigationBar({Key? key}) : super(key: key);

  @override
  _LabManagerBottomNavigationBarState createState() =>
      _LabManagerBottomNavigationBarState();
}

class _LabManagerBottomNavigationBarState extends State<LabManagerBottomNavigationBar> {
  int _selectedIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    Center(child: Text('Home Screen')), // Placeholder for Home screen
    Center(child: Text('Virtualization Screen')), // Placeholder for Virtualization screen
    LabRequestsScreen(), // Lab Requests screen
    HomeMessagesScreen(), // Home Messages screen
    SettingsScreen(), // Settings screen
  ];

  // Unique color for the lab manager role
  final Color _labManagerColor = Colors.deepPurple; // Customize this color

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Directly use the selected screen as the body
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface, // Navigation bar background
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GNav(
            rippleColor: Colors.transparent, // No ripple effect
            hoverColor: Colors.transparent, // No hover effect
            haptic: true, // Haptic feedback
            tabBorderRadius: 15, // Border radius for the selected item
            tabActiveBorder: Border.all(color: Colors.transparent), // No border for active tab
            tabBorder: Border.all(color: Colors.transparent), // No border for inactive tabs
            tabShadow: [], // No shadow for tabs
            curve: Curves.easeOutExpo, // Tab animation curves
            duration: Duration(milliseconds: 300), // Faster animation
            gap: 8, // Gap between icon and text
            color: colorScheme.onSurface.withOpacity(0.6), // Unselected icon and text color
            activeColor: Colors.white, // Selected icon and text color
            iconSize: 25, // Tab icon size
            tabBackgroundColor: _labManagerColor, // Background color for selected tab
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Tab padding
            tabs: [
              GButton(
                icon: LineIcons.home, // Line Icons home icon
                text: 'Home',
              ),
              GButton(
                icon: LineIcons.desktop, // Line Icons desktop icon
                text: 'Virtualization',
              ),
              GButton(
                icon: LineIcons.clipboard, // Line Icons clipboard icon
                text: 'Lab Requests',
              ),
              GButton(
                icon: LineIcons.comment, // Line Icons chat icon
                text: 'Chat',
              ),
              GButton(
                icon: LineIcons.cog, // Line Icons cog icon
                text: 'Settings',
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index; // Update the selected tab
              });
            },
          ),
        ),
      ),
    );
  }
}