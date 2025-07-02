import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pte_mobile/models/room_event.dart';
import 'package:pte_mobile/screens/room/room_reservation_screen.dart';
import 'package:pte_mobile/services/room_service.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomReservationCalendarScreen extends StatefulWidget {
  final int? currentIndex;

  const RoomReservationCalendarScreen({Key? key, this.currentIndex}) : super(key: key);

  @override
  _RoomReservationCalendarScreenState createState() => _RoomReservationCalendarScreenState();
}

class _RoomReservationCalendarScreenState extends State<RoomReservationCalendarScreen> {
  final RoomService _roomService = RoomService();
  List<RoomEvent> _events = [];
  Set<DateTime> _unavailableDays = {};
  DateTime? _selectedDate;
  List<RoomEvent> _eventsOnSelectedDate = [];
  DateTime _focusedMonth = DateTime.now();
  String? _currentUserRole;
  int _currentIndex = 0;
  bool _isEventListExpanded = false; // New state variable for expansion

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex ?? 0;
    _fetchCurrentUserRole();
    _fetchEvents();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Unknown Role';
    });
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await _roomService.getAllEvents();
      final Set<DateTime> unavailableDays = {};

      for (final event in events) {
        DateTime startDate, endDate;
        try {
          startDate = event.start.toLocal();
          endDate = event.end.toLocal();
        } catch (e) {
          print('Error parsing date: $e');
          continue;
        }

        if (startDate.year == endDate.year &&
            startDate.month == endDate.month &&
            startDate.day == endDate.day) {
          unavailableDays.add(DateTime(startDate.year, startDate.month, startDate.day));
        } else {
          for (var day = startDate;
              day.isBefore(endDate.add(const Duration(days: 1)));
              day = day.add(const Duration(days: 1))) {
            unavailableDays.add(DateTime(day.year, day.month, day.day));
          }
        }
      }

      setState(() {
        _events = events;
        _unavailableDays = unavailableDays;
        if (_selectedDate != null) {
          _updateSelectedDate(_selectedDate!);
        }
      });

      print('Fetched Events: ${_events.length} events');
      print('Unavailable Days: $_unavailableDays');
    } catch (e) {
      print('Error fetching events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    }
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _eventsOnSelectedDate = _events
          .where((event) =>
              event.start.isBefore(date.add(const Duration(days: 1))) &&
              event.end.isAfter(date.subtract(const Duration(days: 1))))
          .toList();
    });
    print('Selected Date: $date');
    print('Events on Selected Date: ${_eventsOnSelectedDate.length} events');
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
    print('Focused Month Changed to: ${DateFormat('MMMM yyyy').format(_focusedMonth)}');
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
    print('Focused Month Changed to: ${DateFormat('MMMM yyyy').format(_focusedMonth)}');
  }

  void _onDateTapped(DateTime date) {
    final eventsOnDate = _events.where((event) {
      final eventStartDate = DateTime(event.start.year, event.start.month, event.start.day);
      final eventEndDate = DateTime(event.end.year, event.end.month, event.end.day);
      final currentDate = DateTime(date.year, date.month, date.day);

      if (eventStartDate == eventEndDate) {
        return eventStartDate == currentDate;
      } else {
        return currentDate.isAfter(eventStartDate.subtract(const Duration(days: 1))) &&
            currentDate.isBefore(eventEndDate.add(const Duration(days: 1)));
      }
    }).toList();

    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: true,
      showConfirmBtn: false,
      title: 'Reservation Options',
      text: 'Choose an option for ${DateFormat('MMM dd, yyyy').format(date)}.',
      backgroundColor: Theme.of(context).colorScheme.background,
      titleColor: Theme.of(context).colorScheme.onSurface,
      textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      barrierColor: Colors.black.withOpacity(0.3),
      widget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (eventsOnDate.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateSelectedDate(date);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        '📅 Show Events',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (eventsOnDate.isNotEmpty) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomReservationScreen(
                            selectedDate: date,
                            onEventCreated: (newEvent) {
                              setState(() {
                                _events.add(newEvent);
                                _unavailableDays.add(DateTime(
                                  newEvent.start.year,
                                  newEvent.start.month,
                                  newEvent.start.day,
                                ));
                              });
                              _fetchEvents();
                            },
                            events: _events,
                            currentIndex: _currentIndex,
                          ),
                        ),
                      ).then((_) {
                        _fetchEvents();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '🏨 Reserve Room',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final weeks = (daysInMonth + firstDayOfWeek + 6) ~/ 7;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final day = entry.value;
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: index == 0 || index == 6
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.9,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: weeks * 7,
              itemBuilder: (context, index) {
                final dayOffset = index - firstDayOfWeek;
                final date = dayOffset < 0 || dayOffset >= daysInMonth
                    ? null
                    : DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset + 1);

                if (date == null) {
                  return const SizedBox.shrink();
                }

                final isToday = date.day == today.day &&
                    date.month == today.month &&
                    date.year == today.year;
                final isPastDate = date.isBefore(today);
                final isUnavailable = _unavailableDays.contains(date);
                final isSelected = _selectedDate != null &&
                    date.day == _selectedDate!.day &&
                    date.month == _selectedDate!.month &&
                    date.year == _selectedDate!.year;
                final eventsOnDate = _events.where((event) {
                  final eventStartDate = DateTime(event.start.year, event.start.month, event.start.day);
                  final eventEndDate = DateTime(event.end.year, event.end.month, event.end.day);
                  final currentDate = DateTime(date.year, date.month, date.day);

                  if (eventStartDate == eventEndDate) {
                    return eventStartDate == currentDate;
                  } else {
                    return currentDate.isAfter(eventStartDate.subtract(const Duration(days: 1))) &&
                        currentDate.isBefore(eventEndDate.add(const Duration(days: 1)));
                  }
                }).toList();

                return GestureDetector(
                  onTap: () => _onDateTapped(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isPastDate
                          ? Colors.grey.shade100
                          : isUnavailable
                              ? const Color(0xFFF5A5A5)
                              : isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                  : Theme.of(context).colorScheme.background,
                      border: Border.all(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        width: isToday ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isPastDate
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                                  : isUnavailable
                                      ? Colors.red.shade900
                                      : isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (eventsOnDate.isNotEmpty)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _calculateDuration(RoomEvent event) {
    final duration = event.end.difference(event.start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? "${hours}h ${minutes}m" : "${hours}h";
    } else {
      return "${minutes}m";
    }
  }

  String _getEventStatus(RoomEvent event) {
    final now = DateTime.now();
    if (now.isAfter(event.end)) {
      return "Past";
    } else if (now.isBefore(event.start)) {
      return "Upcoming";
    } else {
      return "Ongoing";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Past":
        return Colors.grey;
      case "Ongoing":
        return Theme.of(context).colorScheme.primary;
      case "Upcoming":
        return Theme.of(context).colorScheme.secondary;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEventCard(RoomEvent event, int index, bool isSmallScreen) {
    final status = _getEventStatus(event);
    final statusColor = _getStatusColor(status);
    final duration = _calculateDuration(event);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.info,
            title: event.title,
            text: 'Room Reservation Details',
            backgroundColor: Theme.of(context).colorScheme.background,
            titleColor: Theme.of(context).colorScheme.onSurface,
            textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            widget: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: "${DateFormat('HH:mm').format(event.start.toLocal())} - ${DateFormat('HH:mm').format(event.end.toLocal())}",
                          context: context,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.info,
                          label: 'Status',
                          value: status,
                          context: context,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.meeting_room,
                          label: 'Room',
                          value: event.roomLabel ?? 'Unknown',
                          context: context,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          icon: Icons.person,
                          label: 'Applicant',
                          value: event.applicantName ?? 'Unknown',
                          context: context,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index < _eventsOnSelectedDate.length - 1)
                    Container(
                      width: 2,
                      height: isSmallScreen ? 80 : 100,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            size: isSmallScreen ? 15 : 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withOpacity(0.2),
                                  statusColor.withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            size: isSmallScreen ? 13 : 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "${DateFormat('HH:mm').format(event.start.toLocal())} - ${DateFormat('HH:mm').format(event.end.toLocal())}",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              duration,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            size: isSmallScreen ? 13 : 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Room: ${event.roomLabel ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            size: isSmallScreen ? 13 : 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Applicant: ${event.applicantName ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    String? value,
    required BuildContext context,
    double fontSize = 14,
    int maxLines = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: fontSize + 2,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize - 1,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            value ?? 'N/A',
            style: TextStyle(
              fontSize: fontSize,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
    _fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _currentUserRole == 'ADMIN'
          ? AdminSidebar(
              currentIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                  _handleTabChange(index);
                });
              },
            )
          : _currentUserRole == 'LAB-MANAGER'
              ? LabManagerSidebar(
                  currentIndex: _currentIndex,
                  onTabChange: (index) {
                    setState(() {
                      _currentIndex = index;
                      _handleTabChange(index);
                    });
                  },
                )
              : _currentUserRole == 'ENGINEER'
                  ? EngineerSidebar(
                      currentIndex: _currentIndex,
                      onTabChange: (index) {
                        setState(() {
                          _currentIndex = index;
                          _handleTabChange(index);
                        });
                      },
                    )
                  : AssistantSidebar(
                      currentIndex: _currentIndex,
                      onTabChange: (index) {
                        setState(() {
                          _currentIndex = index;
                          _handleTabChange(index);
                        });
                      },
                    ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Center(
          child: Text('Rooms Schedule'),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return Column(
            children: [
              Expanded(
                flex: _isEventListExpanded ? 2 : 4, // Adjust flex when expanded
                child: _buildCalendar(),
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isEventListExpanded
                    ? MediaQuery.of(context).size.height * 0.7
                    : MediaQuery.of(context).size.height * 0.3,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? "Events on ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}"
                                : "Event List",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (_selectedDate != null) ...[
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 18 : 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                                _eventsOnSelectedDate = [];
                                _isEventListExpanded = false; // Reset expansion when clearing date
                              });
                              print('Cleared Selected Date');
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isEventListExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 18 : 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEventListExpanded = !_isEventListExpanded;
                              });
                              print('Event List Expanded: $_isEventListExpanded');
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _selectedDate == null
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: isSmallScreen ? 20 : 24,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "No Date Selected",
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 13 : 14,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Flexible(
                                            child: Text(
                                              "Pick a date from the calendar above to see events.",
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 12 : 14,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _eventsOnSelectedDate.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "No events for this day.",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _eventsOnSelectedDate.length,
                                  itemBuilder: (context, index) {
                                    final event = _eventsOnSelectedDate[index];
                                    return _buildEventCard(event, index, isSmallScreen);
                                  },
                                ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
            ],
          );
        },
      ),
    );
  }
}