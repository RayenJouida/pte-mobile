import 'package:flutter/material.dart';
import 'package:pte_mobile/screens/room/room_reservation_screen.dart';
import 'package:intl/intl.dart';
import 'package:pte_mobile/models/room_event.dart';
import 'package:pte_mobile/services/room_service.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickalert/quickalert.dart';

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
          unavailableDays.add(
              DateTime(startDate.year, startDate.month, startDate.day));
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
      _eventsOnSelectedDate = _events
          .where((event) =>
              event.start.isBefore(date.add(const Duration(days: 1))) &&
              event.end.isAfter(date.subtract(const Duration(days: 1))))
          .toList();
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
  final eventsOnDate = _events.where((event) {
    final eventStartDate =
        DateTime(event.start.year, event.start.month, event.start.day);
    final eventEndDate =
        DateTime(event.end.year, event.end.month, event.end.day);
    final currentDate = DateTime(date.year, date.month, date.day);

    if (eventStartDate == eventEndDate) {
      return eventStartDate == currentDate;
    } else {
      return currentDate
              .isAfter(eventStartDate.subtract(const Duration(days: 1))) &&
          currentDate.isBefore(eventEndDate.add(const Duration(days: 1)));
    }
  }).toList();

  if (eventsOnDate.isNotEmpty) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      barrierDismissible: true,
      showConfirmBtn: false, // Remove default confirm button
      title: 'Date Options',
      text:
          'This date has existing reservations. Would you like to view the events or reserve a room?',
      backgroundColor: Theme.of(context).colorScheme.background,
      titleColor: Theme.of(context).colorScheme.onSurface,
      textColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      barrierColor: Colors.black.withOpacity(0.3),
      widget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateSelectedDate(date);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '📅  See Events',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                            },
                            events: _events,
                          ),
                        ),
                      ).then((_) {
                        _fetchEvents();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '🏨  Reserve Room',
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
  } else {
    _updateSelectedDate(date);
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
          },
          events: _events,
        ),
      ),
    ).then((_) {
      _fetchEvents();
    });
  }
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
                  final eventStartDate =
                      DateTime(event.start.year, event.start.month, event.start.day);
                  final eventEndDate =
                      DateTime(event.end.year, event.end.month, event.end.day);
                  final currentDate = DateTime(date.year, date.month, date.day);

                  if (eventStartDate == eventEndDate) {
                    return eventStartDate == currentDate;
                  } else {
                    return currentDate
                            .isAfter(eventStartDate.subtract(const Duration(days: 1))) &&
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
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4)
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8),
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
          Expanded(
            flex: 4, // Increased calendar size
            child: _buildCalendar(),
          ),
          const SizedBox(height: 12),
          Container(
            height: MediaQuery.of(context).size.height * 0.3, // Fixed event list height
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
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
                Expanded(
                  child: _selectedDate == null
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.05),
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Flexible(
                                        child: Text(
                                          "Pick a date from the calendar above to see events.",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
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
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: _eventsOnSelectedDate
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key;
                                  final event = entry.value;
                                  return _buildEventCard(event, index);
                                }).toList(),
                              ),
                            ),
                ),
              ],
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
                  height: 120,
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
                  minHeight: 120,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${DateFormat('HH:mm').format(event.start.toLocal())} - ${DateFormat('HH:mm').format(event.end.toLocal())}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Room: ${event.roomLabel ?? 'Unknown'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Applicant: ${event.applicantName ?? 'Unknown'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
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