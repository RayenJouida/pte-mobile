import 'package:flutter/material.dart';
import 'package:pte_mobile/screens/room/room_reservation_screen.dart';
import 'package:intl/intl.dart';
import 'package:pte_mobile/models/room_event.dart';
import 'package:pte_mobile/services/room_service.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoomReservationCalendarScreen extends StatefulWidget {
  @override
  _RoomReservationCalendarScreenState createState() =>
      _RoomReservationCalendarScreenState();
}

class _RoomReservationCalendarScreenState
    extends State<RoomReservationCalendarScreen> {
  final RoomService _roomService = RoomService();
  List<RoomEvent> _events = [];
  Set<DateTime> _unavailableDays = {};
  DateTime? _selectedDate;
  List<RoomEvent> _eventsOnSelectedDate = [];
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
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
      });

      print('Unavailable Days: $_unavailableDays');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    }
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _eventsOnSelectedDate = _events.where((event) =>
          event.start.isBefore(date.add(const Duration(days: 1))) &&
          event.end.isAfter(date.subtract(const Duration(days: 1)))).toList();
    });
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _onDateTapped(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final isPastDate = date.isBefore(today);
    final isUnavailable = _unavailableDays.contains(date);

    print("Tapped on date: $date");

    if (isUnavailable || isPastDate) {
      print("Date is unavailable or past");
      final eventsOnDate = _events.where((event) =>
          event.start.isBefore(date.add(const Duration(days: 1))) &&
          event.end.isAfter(date.subtract(const Duration(days: 1)))).toList();

      if (eventsOnDate.isNotEmpty) {
        _showEventDetailsPopup(eventsOnDate.first, date, isPastDate: isPastDate);
      } else if (isPastDate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No events on this past date')),
        );
      }
    } else {
      print("Date is available");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomReservationScreen(
            selectedDate: date,
            onEventCreated: (newEvent) {
              setState(() {
                _events.add(newEvent);
                _unavailableDays.add(DateTime(newEvent.start.year, newEvent.start.month, newEvent.start.day));
              });
            },
            events: _events,
          ),
        ),
      ).then((_) {
        _fetchEvents();
      });
    }

    _updateSelectedDate(date);
  }

  void _showEventDetailsPopup(RoomEvent event, DateTime selectedDate, {required bool isPastDate}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.meeting_room,
                  label: "Room ID",
                  value: event.roomId,
                ),
                _buildDetailRow(
                  icon: Icons.person,
                  label: "Applicant",
                  value: event.applicantId,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(event.start.toLocal()),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "End",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(event.end.toLocal()),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Close",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (!isPastDate) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomReservationScreen(
                                selectedDate: selectedDate,
                                onEventCreated: (newEvent) {
                                  setState(() {
                                    _events.add(newEvent);
                                    _unavailableDays.add(DateTime(newEvent.start.year, newEvent.start.month, newEvent.start.day));
                                  });
                                },
                                events: _events,
                              ),
                            ),
                          ).then((_) {
                            _fetchEvents();
                          });
                        },
                        child: Text(
                          'Reserve Room',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 200.ms);
      },
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; // 0 = Sunday, 6 = Saturday
    final weeks = (daysInMonth + firstDayOfWeek + 6) ~/ 7;

    return Column(
      children: [
        // Month Header
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
        // Weekday Headers
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
        // Calendar Grid
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
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
                              ? const Color(0xFFF5A5A5) // Muted red for unavailable
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
                        // Day Number
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
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
                        // Event Indicator
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Reservation Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        children: [
          // Calendar Section
          Expanded(
            flex: _selectedDate == null ? 4 : 3,
            child: _buildCalendar(),
          ),
          // Gap between calendar and event list
          const SizedBox(height: 12),
          // Event List Section
          Expanded(
            flex: _selectedDate == null || _eventsOnSelectedDate.isEmpty ? 1 : 2,
            child: Container(
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? "Events on ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}"
                              : "Event List",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                              _eventsOnSelectedDate = [];
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedDate == null)
                    Expanded(
                      child: Center(
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
                                size: 24,
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Flexible(
                                      child: Text(
                                        "Pick a date from the calendar above to see events.",
                                        style: TextStyle(
                                          fontSize: 14,
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
                      ),
                    ),
                  if (_selectedDate != null && _eventsOnSelectedDate.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "No events for this day.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  if (_selectedDate != null && _eventsOnSelectedDate.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: _eventsOnSelectedDate.asMap().entries.map((entry) {
                            final index = entry.key;
                            final event = entry.value;
                            return _buildEventCard(event, index);
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ),
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

  Widget _buildEventCard(RoomEvent event, int index) {
    final status = _getEventStatus(event);
    final statusColor = _getStatusColor(status);
    final duration = _calculateDuration(event);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (index < _eventsOnSelectedDate.length - 1)
                Container(
                  width: 2,
                  height: 100,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Event Details
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 100, // Ensure a minimum height for the card
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
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
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${DateFormat('HH:mm').format(event.start.toLocal())} - ${DateFormat('HH:mm').format(event.end.toLocal())}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              duration,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Room ID: ${event.roomId}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Applicant ID: ${event.applicantId}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}