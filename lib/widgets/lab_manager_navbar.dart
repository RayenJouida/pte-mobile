import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pte_mobile/screens/feed/feed_screen.dart';
import 'package:pte_mobile/screens/messaging/home_messages_screen.dart';
import 'package:pte_mobile/screens/profile_screen.dart';
import 'package:pte_mobile/screens/notifications_screen.dart';

class LabManagerNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;
  final int unreadMessageCount;
  final int unreadNotificationCount;

  const LabManagerNavbar({
    Key? key,
    required this.currentIndex,
    required this.onTabChange,
    this.unreadMessageCount = 0,
    this.unreadNotificationCount = 0,
  }) : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/feed');
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeMessagesScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NotificationsScreen()),
        );
        break;
    }
    onTabChange(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GNav(
          rippleColor: Colors.transparent,
          hoverColor: Colors.transparent,
          haptic: true,
          tabBorderRadius: 15,
          tabActiveBorder: Border.all(color: Colors.transparent),
          tabBorder: Border.all(color: Colors.transparent),
          tabShadow: [],
          curve: Curves.easeOutExpo,
          duration: const Duration(milliseconds: 300),
          gap: 8,
          color: colorScheme.onSurface.withOpacity(0.6),
          activeColor: colorScheme.onPrimary,
          iconSize: 25,
          tabBackgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          tabs: [
            GButton(
              icon: LineIcons.home,
              text: 'Feed',
              leading: Stack(
                children: [
                  const Icon(LineIcons.home, size: 25),
                ],
              ),
            ),
            GButton(
              icon: LineIcons.comment,
              text: 'Chat',
              leading: Stack(
                children: [
                  const Icon(LineIcons.comment, size: 25),
                  if (unreadMessageCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadMessageCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const GButton(
              icon: LineIcons.user,
              text: 'Profile',
            ),
            GButton(
              icon: LineIcons.bell,
              text: 'Notifications',
              leading: Stack(
                children: [
                  const Icon(LineIcons.bell, size: 25),
                  if (unreadNotificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          selectedIndex: currentIndex,
          onTabChange: (index) => _navigateToPage(context, index),
        ),
      ),
    );
  }
}