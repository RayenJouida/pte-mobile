import 'package:flutter/material.dart';
import 'package:pte_mobile/services/room_service.dart';
import 'package:pte_mobile/models/room.dart';
import 'package:pte_mobile/models/room_event.dart';
import 'package:pte_mobile/widgets/assistant_navbar.dart'; // Added import
import 'all_rooms.dart';
import 'room_reservation_calendar_screen.dart';

class HomeRoomScreen extends StatefulWidget {
  @override
  _HomeRoomScreenState createState() => _HomeRoomScreenState();
}

class _HomeRoomScreenState extends State<HomeRoomScreen> {
  final RoomService _roomService = RoomService();
  int totalRooms = 0;
  int availableRooms = 0;
  int reservedRooms = 0;
  int upcomingReservations = 0;
  bool isLoading = true;
  int _currentIndex = 2; // Index 2 for Room tab

  void _onTabChange(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRoomStats();
  }

  Future<void> _fetchRoomStats() async {
    try {
      final rooms = await _roomService.getAllRooms();
      final reservations = await _roomService.getAllEvents();
      final now = DateTime.now();
      final upcoming = reservations.where((reservation) => reservation.start.isAfter(now)).toList();

      setState(() {
        totalRooms = rooms.length;
        availableRooms = rooms.where((room) => _isRoomAvailable(room, reservations)).length;
        reservedRooms = totalRooms - availableRooms;
        upcomingReservations = upcoming.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load room stats: $e')),
      );
    }
  }

  bool _isRoomAvailable(Room room, List<RoomEvent> reservations) {
    final now = DateTime.now();
    for (var reservation in reservations) {
      if (reservation.roomId == room.id && 
          reservation.start.isBefore(now) && 
          reservation.end.isAfter(now)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Room Analytics',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        centerTitle: true,
      ),
      backgroundColor: colorScheme.background,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 40,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Rooms Management',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          title: 'Total Rooms',
                          value: totalRooms.toString(),
                          imagePath: 'assets/illustrations/rooms.png',
                          colorScheme: colorScheme,
                        ),
                        _buildStatCard(
                          title: 'Available',
                          value: availableRooms.toString(),
                          imagePath: 'assets/illustrations/available.png',
                          colorScheme: colorScheme,
                        ),
                        _buildStatCard(
                          title: 'Reserved',
                          value: reservedRooms.toString(),
                          imagePath: 'assets/illustrations/reserved.png',
                          colorScheme: colorScheme,
                        ),
                        _buildStatCard(
                          title: 'Upcoming',
                          value: upcomingReservations.toString(),
                          imagePath: 'assets/illustrations/upcoming.png',
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Management Actions',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomReservationCalendarScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Manage Events',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: colorScheme.onPrimary,
                              backgroundColor: colorScheme.primary,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllRoomsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Manage Rooms',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              backgroundColor: colorScheme.surface,
                              side: BorderSide(color: colorScheme.primary),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String imagePath,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 66,
              width: 180,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}