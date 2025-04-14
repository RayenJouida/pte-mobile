import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pte_mobile/models/room.dart'; // Import your Room model
import 'package:pte_mobile/screens/room/create_room.dart'; // Import the CreateRoomScreen
import 'package:pte_mobile/screens/room/update_room.dart'; // Import the UpdateRoomScreen
import 'package:pte_mobile/screens/room/room_details.dart'; // Import the RoomDetailsScreen
import 'package:pte_mobile/services/room_service.dart'; // Import your RoomService

class AllRoomsScreen extends StatefulWidget {
  @override
  _AllRoomsScreenState createState() => _AllRoomsScreenState();
}

class _AllRoomsScreenState extends State<AllRoomsScreen> {
  final RoomService _roomService = RoomService();
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final rooms = await _roomService.getAllRooms();
      setState(() {
        _rooms = rooms;
        _filteredRooms = rooms;
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
        _filteredRooms.removeWhere((room) => room.id == roomId);
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

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredRooms = _rooms;
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _filteredRooms = _rooms.where((room) {
        final label = room.label.toLowerCase();
        final location = room.location.toLowerCase();
        return label.contains(query.toLowerCase()) || location.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // Light gray background
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Label or Location...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _performSearch,
              )
            : Text(
                'All Rooms',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0632A1), Color(0xFF3D5AFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchRooms,
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
      body: _isLoading
          ? _buildShimmerLoading()
          : _filteredRooms.isEmpty
              ? Center(child: Text('No rooms found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = _filteredRooms[index];
                    return Dismissible(
                      key: Key(room.id), // Unique key for each item
                      direction: DismissDirection.endToStart, // Swipe from right to left
                      background: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20), // Match card border radius
                        ),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      confirmDismiss: (direction) async {
                        // Show a confirmation dialog with the room's label
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
                        _deleteRoom(room.id); // Delete the room
                      },
                      child: GestureDetector(
                        onDoubleTap: () {
                          // Navigate to RoomDetailsScreen on double tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomDetailsScreen(room: room),
                            ),
                          );
                        },
                        child: Container(
                          height: 150, // Uniform height for all cards
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3), // Translucent background
                            borderRadius: BorderRadius.circular(20), // Rounded corners
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Label with icon
                                    Row(
                                      children: [
                                        Icon(Icons.meeting_room, color: Color(0xFF0632A1), size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          room.label,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0632A1),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Location
                                    Text(
                                      'Location: ${room.location}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold, // Bold label
                                        color: Colors.black87,
                                      ),
                                    ),
                                    // Capacity
                                    Text(
                                      'Capacity: ${room.capacity}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold, // Bold label
                                        color: Colors.black87,
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
                  },
                ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 150,
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[300],
          ),
        );
      },
    );
  }
}