import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pte_mobile/screens/labmanager/requests_by_user_id.dart';
import 'package:pte_mobile/screens/room/room_reservation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme.dart';

class AssistantSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const AssistantSidebar({
    Key? key,
    required this.currentIndex,
    required this.onTabChange,
  }) : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoomReservationScreen(
              onEventCreated: (event) {}, // Placeholder
              events: [], // Placeholder
            ),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RequestsByUserId()),
        );
        break;
    }
    onTabChange(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = lightColorScheme;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: colorScheme.surface.withOpacity(0.85),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary.withOpacity(0.15), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LineIcons.rocket, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'PTE Hub',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildSidebarItem(
                        context,
                        index: 0,
                        icon: LineIcons.building,
                        text: 'Rooms',
                        isSelected: currentIndex == 0,
                        onTap: () => _navigateToPage(context, 0),
                      ),
                      _buildSidebarItem(
                        context,
                        index: 1,
                        icon: LineIcons.flask,
                        text: 'Labs',
                        isSelected: currentIndex == 1,
                        onTap: () => _navigateToPage(context, 1),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  thickness: 1,
                  height: 1,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: FutureBuilder<Map<String, String?>>(
                    future: _getUserInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final userName = snapshot.data?['userName'] ?? 'User';
                      final userImage = snapshot.data?['userImage'];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.15),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.25),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: userImage != null
                                    ? NetworkImage(userImage)
                                    : null,
                                child: userImage == null
                                    ? Icon(
                                        Icons.person,
                                        size: 24,
                                        color: colorScheme.onSurface.withOpacity(0.6),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = lightColorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.15),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
              ).animate().scale(duration: 200.ms),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(delay: 100.ms * index),
    );
  }

  Future<Map<String, String?>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userName': prefs.getString('userName'),
      'userImage': prefs.getString('userImage'),
    };
  }
}