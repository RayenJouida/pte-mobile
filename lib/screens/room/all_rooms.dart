import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/room.dart';
import 'package:pte_mobile/screens/room/create_room.dart';
import 'package:pte_mobile/screens/room/update_room.dart';
import 'package:pte_mobile/screens/room/room_details.dart';
import 'package:pte_mobile/services/room_service.dart';

class AllRoomsScreen extends StatefulWidget {
  @override
  _AllRoomsScreenState createState() => _AllRoomsScreenState();
}

class _AllRoomsScreenState extends State<AllRoomsScreen> {
  final RoomService _roomService = RoomService();
  List<Room> _rooms = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rooms = await _roomService.getAllRooms();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rooms: $e')),
      );
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    try {
      await _roomService.deleteRoom(roomId);
      setState(() {
        _rooms.removeWhere((room) => room.id == roomId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete room: $e')),
      );
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Room> get _filteredRooms {
    if (_searchQuery.isEmpty) return _rooms;
    return _rooms.where((room) {
      return room.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Upper Section (Primary Color)
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'All Rooms',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
                ),
                Positioned(
                  left: 16,
                  top: MediaQuery.of(context).padding.top + 16,
                  child: IconButton(
                    icon: Icon(Icons.chevron_left, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 16,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: RoomSearchDelegate(_rooms),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.white),
                        onPressed: _fetchRooms,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lower Section (White Background)
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _filteredRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.meeting_room, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No rooms available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchRooms,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredRooms.length,
                          itemBuilder: (context, index) {
                            final room = _filteredRooms[index];
                            return Dismissible(
                              key: Key(room.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Room'),
                                    content: Text('Are you sure you want to delete "${room.label}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                _deleteRoom(room.id);
                              },
                              child: _buildRoomCard(room)
                                  .animate()
                                  .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                                  .slideY(begin: 0.1, delay: (50 * index).ms),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRoomScreen(),
            ),
          ).then((_) => _fetchRooms());
        },
        backgroundColor: Color(0xFF0632A1),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailsScreen(room: room),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateRoomScreen(room: room),
                        ),
                      ).then((_) => _fetchRooms());
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    room.location,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Capacity: ${room.capacity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 120,
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ).animate().shimmer(duration: 1000.ms);
      },
    );
  }
}

class RoomSearchDelegate extends SearchDelegate {
  final List<Room> rooms;

  RoomSearchDelegate(this.rooms);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = rooms.where((room) {
      return room.label.toLowerCase().contains(query.toLowerCase()) ||
          room.location.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  Widget _buildSearchResults(List<Room> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final room = results[index];
        return ListTile(
          title: Text(room.label),
          subtitle: Text(room.location),
          onTap: () {
            close(context, room);
          },
        );
      },
    );
  }
}