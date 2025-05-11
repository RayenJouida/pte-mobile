import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/models/user_event.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserReservationScreen extends StatefulWidget {
  const UserReservationScreen({Key? key}) : super(key: key);

  @override
  _UserReservationScreenState createState() => _UserReservationScreenState();
}

class _UserReservationScreenState extends State<UserReservationScreen> {
  final UserService _userService = UserService();
  List<UserEvent> _events = [];
  Set<DateTime> _unavailableDays = {};
  DateTime? _selectedDate;
  List<UserEvent> _eventsOnSelectedDate = [];
  DateTime _focusedMonth = DateTime.now();
  List<User> _technicians = [];
  bool _isLoadingTechnicians = true;
  Map<String, String> _userNameCache = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchTechnicians();
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await _userService.getAllUserEvents();
      final Set<DateTime> unavailableDays = {};

      for (final event in events) {
        DateTime startDate, endDate;
        try {
          startDate = event.start.toLocal();
          endDate = event.end.toLocal();
        } catch (e) {
          print('Error parsing date for event ${event.id}: $e');
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

  Future<void> _fetchTechnicians() async {
    try {
      setState(() {
        _isLoadingTechnicians = true;
      });
      final usersData = await _userService.fetchUsers();
      final technicians = usersData.map((userData) => User.fromJson(userData)).toList();
      setState(() {
        _technicians = technicians;
        _isLoadingTechnicians = false;
      });

      // Cache technician names
      for (var tech in technicians) {
        _userNameCache[tech.id] = '${tech.firstName} ${tech.lastName}';
      }

      print('Fetched Technicians: ${_technicians.length} users');
      print('Technicians: ${_technicians.map((t) => "${t.firstName} ${t.lastName}").toList()}');
    } catch (e) {
      print('Error fetching technicians: $e');
      setState(() {
        _isLoadingTechnicians = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load technicians: $e')),
      );
    }
  }

  Future<String> _fetchUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final userData = await _userService.getUserById(userId);
      final user = User.fromJson(userData);
      final userName = '${user.firstName} ${user.lastName}';
      _userNameCache[userId] = userName;
      return userName;
    } catch (e) {
      print('Error fetching user $userId: $e');
      return userId; // Fallback to ID if fetching fails
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
        showConfirmBtn: false,
        title: 'Date Options',
        text:
            'This date has existing bookings. Would you like to view the events or book a technician?',
        backgroundColor: Theme.of(context).colorScheme.background,
        titleColor: Theme.of(context).colorScheme.onSurface,
        textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                        _showBookingForm(date);
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
                        '👨‍🔧  Book Technician',
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
      _showBookingForm(date);
    }
  }

  void _showBookingForm(DateTime selectedDate) async {
    User? selectedTechnician;
    DateTime startDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      9,
      0,
    ); // Default to 9:00 AM
    DateTime endDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      17,
      0,
    ); // Default to 5:00 PM
    TextEditingController jobController = TextEditingController();
    TextEditingController destinationController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Fetch the current user's ID (applicant)
    final prefs = await SharedPreferences.getInstance();
    final applicantId = prefs.getString('userId');
    if (applicantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please log in again.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.build,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Book a Technician',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Technician Dropdown
                        DropdownButtonFormField<User>(
                          decoration: InputDecoration(
                            labelText: 'Select Technician',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.background,
                          ),
                          items: _technicians.map((technician) {
                            return DropdownMenuItem<User>(
                              value: technician,
                              child: Text('${technician.firstName} ${technician.lastName}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedTechnician = value;
                            });
                            print('Selected Technician: ${value?.firstName} ${value?.lastName}');
                          },
                          validator: (value) =>
                              value == null ? 'Please select a technician' : null,
                        ),
                        const SizedBox(height: 16),
                        // Start Date and Time
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Start Date & Time',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.background,
                          ),
                          controller: TextEditingController(
                            text: DateFormat('MMM dd, yyyy HH:mm').format(startDateTime),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDateTime,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startDateTime),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  startDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                                print('Selected Start DateTime: $startDateTime');
                              }
                            }
                          },
                          validator: (value) =>
                              startDateTime.isBefore(DateTime.now()) ? 'Start time cannot be in the past' : null,
                        ),
                        const SizedBox(height: 16),
                        // End Date and Time
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'End Date & Time',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.background,
                          ),
                          controller: TextEditingController(
                            text: DateFormat('MMM dd, yyyy HH:mm').format(endDateTime),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDateTime,
                              firstDate: startDateTime,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(endDateTime),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  endDateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                                print('Selected End DateTime: $endDateTime');
                              }
                            }
                          },
                          validator: (value) =>
                              endDateTime.isBefore(startDateTime) ? 'End time must be after start time' : null,
                        ),
                        const SizedBox(height: 16),
                        // Job Field
                        TextFormField(
                          controller: jobController,
                          decoration: InputDecoration(
                            labelText: 'Job Description',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.work,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.background,
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter the job description' : null,
                        ),
                        const SizedBox(height: 16),
                        // Destination Field
                        TextFormField(
                          controller: destinationController,
                          decoration: InputDecoration(
                            labelText: 'Destination (Address)',
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.background,
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter the destination' : null,
                        ),
                        const SizedBox(height: 24),
                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  try {
                                    final event = await _userService.createUserEvent(
                                      title: 'Technician Booking - ${jobController.text}',
                                      start: startDateTime,
                                      end: endDateTime,
                                      engineerId: selectedTechnician!.id,
                                      job: jobController.text,
                                      address: destinationController.text,
                                      applicantId: applicantId,
                                    );
                                    print('Event Created: ${event.id}');
                                    print('Event Details: Title=${event.title}, Start=${event.start}, End=${event.end}, Engineer=${event.engineer}, Applicant=${event.applicant}');

                                    // Update state immediately
                                    setState(() {
                                      _events.add(event);

                                      // Update unavailable days
                                      DateTime startDate = event.start.toLocal();
                                      DateTime endDate = event.end.toLocal();
                                      if (startDate.year == endDate.year &&
                                          startDate.month == endDate.month &&
                                          startDate.day == endDate.day) {
                                        _unavailableDays.add(DateTime(
                                            startDate.year, startDate.month, startDate.day));
                                      } else {
                                        for (var day = startDate;
                                            day.isBefore(endDate.add(const Duration(days: 1)));
                                            day = day.add(const Duration(days: 1))) {
                                          _unavailableDays.add(
                                              DateTime(day.year, day.month, day.day));
                                        }
                                      }

                                      // Update events on selected date if applicable
                                      if (_selectedDate != null) {
                                        final selectedDate = DateTime(
                                          _selectedDate!.year,
                                          _selectedDate!.month,
                                          _selectedDate!.day,
                                        );
                                        final eventStartDate = DateTime(
                                          event.start.year,
                                          event.start.month,
                                          event.start.day,
                                        );
                                        final eventEndDate = DateTime(
                                          event.end.year,
                                          event.end.month,
                                          event.end.day,
                                        );
                                        bool overlaps = selectedDate.isAfter(
                                                eventStartDate.subtract(const Duration(days: 1))) &&
                                            selectedDate
                                                .isBefore(eventEndDate.add(const Duration(days: 1)));
                                        if (overlaps) {
                                          _eventsOnSelectedDate.add(event);
                                        }
                                      }
                                    });

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Technician booked successfully!')),
                                    );
                                  } catch (e) {
                                    print('Error creating event: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to book technician: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                              child: const Text(
                                'Book',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
        title: const Text('Book a Technician'),
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
            flex: 4,
            child: _buildCalendar(),
          ),
          const SizedBox(height: 12),
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
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
                          print('Cleared Selected Date');
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

  String _calculateDuration(UserEvent event) {
    final duration = event.end.difference(event.start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? "${hours}h ${minutes}m" : "${hours}h";
    } else {
      return "${minutes}m";
    }
  }

  String _getEventStatus(UserEvent event) {
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

  Widget _buildEventCard(UserEvent event, int index) {
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
                            Icons.person,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          FutureBuilder<String>(
                            future: _fetchUserName(event.engineer),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Text(
                                  'Technician: ${event.engineer}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                );
                              }
                              return Text(
                                'Technician: ${snapshot.data}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              );
                            },
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
                          FutureBuilder<String>(
                            future: _fetchUserName(event.applicant),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Text(
                                  'Applicant: ${event.applicant}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                );
                              }
                              return Text(
                                'Applicant: ${snapshot.data}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Job: ${event.job}",
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
                            Icons.location_on,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Destination: ${event.address}",
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