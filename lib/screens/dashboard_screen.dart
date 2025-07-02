import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pte_mobile/screens/feed/feed_screen.dart';
import 'package:pte_mobile/screens/labmanager/home_lab_screen.dart';
import 'package:pte_mobile/screens/users/all_users.dart';
import 'package:pte_mobile/screens/room/all_rooms.dart';
import 'package:pte_mobile/screens/vehicules/all_vehicles.dart';
import 'package:pte_mobile/screens/leave/all_leave_requests.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.12),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.12,
          decoration: const BoxDecoration(
            color: Color(0xFF0632A1),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 25,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    tooltip: 'Go back',
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
                  ),
                ),
                SizedBox(width: 48), // Spacer to balance the layout
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _buildModernCard(
                  context,
                  'Users',
                  LineIcons.users,
                  const AllUsersScreen(),
                  Colors.deepPurple,
                  Icons.arrow_forward_ios,
                ),
                _buildModernCard(
                  context,
                  'Rooms',
                  LineIcons.building,
                  const AllRoomsScreen(),
                  Colors.teal,
                  Icons.arrow_forward_ios,
                ),
                _buildModernCard(
                  context,
                  'Vehicles',
                  LineIcons.car,
                  const AllVehiclesScreen(),
                  Colors.orange,
                  Icons.arrow_forward_ios,
                ),
                _buildModernCard(
                  context,
                  'Leave',
                  LineIcons.calendarCheck,
                  const AllLeaveRequestsScreen(),
                  Colors.green,
                  Icons.arrow_forward_ios,
                ),
                _buildModernCard(
                  context,
                  'Labs',
                  LineIcons.flask,
                  const HomeLabScreen(),
                  Colors.indigo,
                  Icons.arrow_forward_ios,
                ),
                _buildModernCard(
                  context,
                  'Posts',
                  LineIcons.pen,
                  const FeedScreen(),
                  Colors.pink,
                  Icons.arrow_forward_ios,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget destination,
    Color accentColor,
    IconData trailingIcon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Hero(
      tag: title,
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surface.withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => destination,
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeInOutCubic)),
                        ),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 28,
                            color: accentColor,
                          ),
                        ),
                        Icon(
                          trailingIcon,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Show ${title.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}