import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/models/user_event.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/models/vehicule_event.dart';
import 'package:pte_mobile/screens/users/project_reservation_screen.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/screens/vehicules/vehicle_reservation_screen.dart';

// Unified event model to handle both UserEvent and VehicleEvent
class UnifiedEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String type; // 'user' or 'vehicle'
  final String? engineer; // For UserEvent
  final String? applicant; // For both
  final String? job; // For UserEvent
  final String? address; // For both (destination for VehicleEvent)
  final bool? isAccepted; // For both
  final String? vehicleId; // For VehicleEvent
  final String? registrationNumber; // For VehicleEvent
  final String? driverId; // For VehicleEvent
  final String? departure; // For VehicleEvent
  final String? driverName; // For VehicleEvent
  final String? applicantName; // For VehicleEvent

  UnifiedEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.type,
    this.engineer,
    this.applicant,
    this.job,
    this.address,
    this.isAccepted,
    this.vehicleId,
    this.registrationNumber,
    this.driverId,
    this.departure,
    this.driverName,
    this.applicantName,
  });

  factory UnifiedEvent.fromUserEvent(UserEvent event) {
    return UnifiedEvent(
      id: event.id,
      title: event.title,
      start: event.start,
      end: event.end,
      type: 'user',
      engineer: event.engineer,
      applicant: event.applicant,
      job: event.job,
      address: event.address,
      isAccepted: event.isAccepted,
    );
  }

  factory UnifiedEvent.fromVehicleEvent(VehicleEvent event, Vehicle? vehicle) {
    return UnifiedEvent(
      id: event.id ?? 'vehicle-${DateTime.now().millisecondsSinceEpoch}',
      title: event.title ?? 'Vehicle Reservation',
      start: event.start ?? DateTime.now(),
      end: event.end ?? DateTime.now().add(Duration(hours: 1)),
      type: 'vehicle',
      applicant: event.applicantId,
      address: event.destination,
      isAccepted: event.isAccepted,
      vehicleId: event.vehicleId,
      registrationNumber: vehicle?.registrationNumber,
      driverId: event.driverId,
      departure: event.departure,
      driverName: event.driverFirstName != null && event.driverLastName != null
          ? '${event.driverFirstName} ${event.driverLastName}'
          : null,
      applicantName: event.applicantFirstName != null && event.applicantLastName != null
          ? '${event.applicantFirstName} ${event.applicantLastName}'
          : null,
    );
  }
}

class UserReservationScreen extends StatefulWidget {
  const UserReservationScreen({Key? key}) : super(key: key);

  @override
  _UserReservationScreenState createState() => _UserReservationScreenState();
}

class _UserReservationScreenState extends State<UserReservationScreen> {
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();
  List<UnifiedEvent> _events = [];
  Set<DateTime> _unavailableDays = {};
  DateTime? _selectedDate;
  List<UnifiedEvent> _eventsOnSelectedDate = [];
  DateTime _focusedMonth = DateTime.now();
  List<User> _technicians = [];
  bool _isLoadingTechnicians = true;
  Map<String, String> _userNameCache = {};
  String? _currentUserRole;
  List<Vehicle> _vehicles = [];
  bool _isEventListExpanded = false; // New state variable for expansion

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
    _fetchEvents();
    _fetchTechnicians();
    _fetchVehicles();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Unknown Role';
    });
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
      });
    } catch (e) {
      print('Error fetching vehicles: $e');
    }
  }

  Future<void> _fetchEvents() async {
    try {
      // Fetch UserEvents
      final userEvents = await _userService.getAllUserEvents();
      final vehicleEvents = await _vehicleService.getAllEvents();
      final Set<DateTime> unavailableDays = {};

      // Get vehicles for registration numbers
      final vehicles = await _vehicleService.getVehicles();

      // Convert to UnifiedEvent
      final unifiedEvents = [
        ...userEvents.map((e) => UnifiedEvent.fromUserEvent(e)),
        ...vehicleEvents.map((e) {
          final vehicle = vehicles.firstWhere(
            (v) => v.id == e.vehicleId,
            orElse: () => Vehicle(),
          );
          return UnifiedEvent.fromVehicleEvent(e, vehicle);
        }),
      ];

      for (final event in unifiedEvents) {
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
        _events = unifiedEvents;
        _unavailableDays = unavailableDays;
        if (_selectedDate != null) {
          _updateSelectedDate(_selectedDate!);
        }
      });

      print('Fetched Events: ${_events.length} events (User: ${userEvents.length}, Vehicle: ${vehicleEvents.length})');
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
      return userId;
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
    final hasEvents = _events.any((event) =>
        event.start.isBefore(date.add(const Duration(days: 1))) &&
        event.end.isAfter(date.subtract(const Duration(days: 1))));
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
            if (hasEvents)
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
            if (hasEvents) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleReservationScreen(
                            selectedDate: date,
                            onEventCreated: (dynamic event) {
                              setState(() {
                                if (event is VehicleEvent) {
                                  _events.add(UnifiedEvent.fromVehicleEvent(event, null));
                                } else if (event is UserEvent) {
                                  _events.add(UnifiedEvent.fromUserEvent(event));
                                }
                              });
                              _fetchEvents(); // Refresh all events
                            },
                            events: _events
                                .where((e) => e.type == 'user')
                                .map((e) => UserEvent(
                                      id: e.id,
                                      title: e.title,
                                      start: e.start,
                                      end: e.end,
                                      engineer: e.engineer ?? '',
                                      applicant: e.applicant ?? '',
                                      job: e.job ?? '',
                                      address: e.address ?? '',
                                      isAccepted: e.isAccepted ?? false,
                                    ))
                                .toList(),
                          ),
                        ),
                      ).then((_) {
                        _fetchEvents();
                      });
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
                      '🎫 Ticket Reservation',
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
                          builder: (context) => ProjectReservationScreen(
                            selectedDate: date,
                            onEventCreated: (dynamic event) {
                              setState(() {
                                if (event is VehicleEvent) {
                                  _events.add(UnifiedEvent.fromVehicleEvent(event, null));
                                } else if (event is UserEvent) {
                                  _events.add(UnifiedEvent.fromUserEvent(event));
                                }
                              });
                              _fetchEvents(); // Refresh all events
                            },
                            events: _events
                                .where((e) => e.type == 'user')
                                .map((e) => UserEvent(
                                      id: e.id,
                                      title: e.title,
                                      start: e.start,
                                      end: e.end,
                                      engineer: e.engineer ?? '',
                                      applicant: e.applicant ?? '',
                                      job: e.job ?? '',
                                      address: e.address ?? '',
                                      isAccepted: e.isAccepted ?? false,
                                    ))
                                .toList(),
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
                      '📋 Project Reservation',
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

  void _showEventDetails(UnifiedEvent event) {
    final status = _getEventStatus(event);
    final duration = _calculateDuration(event);
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: event.title,
      text: event.type == 'user' ? 'Technician Event Details' : 'Vehicle Reservation Details',
      backgroundColor: Theme.of(context).colorScheme.background,
      titleColor: Theme.of(context).colorScheme.onSurface,
      textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      widget: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: event.type == 'user'
            ? _buildTechnicianEventDetails(event, status, duration)
            : _buildVehicleEventDetails(event, status, duration),
      ),
    );
  }

  Widget _buildTechnicianEventDetails(UnifiedEvent event, String status, String duration) {
    return Column(
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
              ),
            ),
            Expanded(
              child: _buildDetailRow(
                icon: Icons.info,
                label: 'Status',
                value: status,
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailRow(
                icon: Icons.person,
                label: 'Technician',
                valueWidget: FutureBuilder<String>(
                  future: _fetchUserName(event.engineer ?? ''),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? event.engineer ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                context: context,
              ),
            ),
            Expanded(
              child: _buildDetailRow(
                icon: Icons.person_outline,
                label: 'Applicant',
                valueWidget: FutureBuilder<String>(
                  future: _fetchUserName(event.applicant ?? ''),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? event.applicant ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailRow(
                icon: Icons.work,
                label: 'Job',
                value: event.job ?? 'N/A',
                context: context,
              ),
            ),
            Expanded(
              child: _buildDetailRow(
                icon: Icons.location_on,
                label: 'Destination',
                value: event.address ?? 'N/A',
                context: context,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleEventDetails(UnifiedEvent event, String status, String duration) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final maxDestinationLength = isSmallScreen ? 20 : 30;
    final destination = event.address != null && event.address!.length > maxDestinationLength
        ? '${event.address!.substring(0, maxDestinationLength)}...'
        : event.address ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).colorScheme.primary,
                  size: isSmallScreen ? 20 : 24,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.directions_car,
                        label: 'Vehicle',
                        value: event.registrationNumber ?? 'N/A',
                        context: context,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.person,
                        label: 'Driver',
                        value: event.driverName ?? event.driverId ?? 'Unknown',
                        context: context,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.person_outline,
                        label: 'Applicant',
                        valueWidget: FutureBuilder<String>(
                          future: _fetchUserName(event.applicant ?? ''),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? event.applicant ?? 'Unknown',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        context: context,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Departure',
                        value: event.departure ?? 'N/A',
                        context: context,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.location_on,
                        label: 'Destination',
                        value: destination,
                        context: context,
                        fontSize: isSmallScreen ? 13 : 14,
                        maxLines: 1,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
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
          child: valueWidget ??
              Text(
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
  child: Row(
    children: eventsOnDate.map((event) {
      return Container(
        margin: const EdgeInsets.only(left: 2),
        child: event.type == 'user'
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              )
            : Icon(
                Icons.directions_car,
                size: 12,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
      );
    }).toList(),
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
      drawer: _currentUserRole == 'ADMIN'
          ? AdminSidebar(
              currentIndex: 1,
              onTabChange: (index) {
                setState(() {});
              },
            )
          : _currentUserRole == 'LAB-MANAGER'
              ? LabManagerSidebar(
                  currentIndex: 0,
                  onTabChange: (index) {
                    setState(() {});
                  },
                )
              : _currentUserRole == 'ENGINEER'
                  ? EngineerSidebar(
                      currentIndex: 1,
                      onTabChange: (index) {
                        setState(() {});
                      },
                    )
                  : AssistantSidebar(
                      currentIndex: 1,
                      onTabChange: (index) {
                        setState(() {});
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
          child: Text('Missions Schedule'),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
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
                                                fontSize: isSmallScreen ? 12 : 14,
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
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
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

  String _calculateDuration(UnifiedEvent event) {
    final duration = event.end.difference(event.start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? "${hours}h ${minutes}m" : "${hours}h";
    } else {
      return "${minutes}m";
    }
  }

  String _getEventStatus(UnifiedEvent event) {
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

  Widget _buildEventCard(UnifiedEvent event, int index, bool isSmallScreen) {
    final status = _getEventStatus(event);
    final statusColor = _getStatusColor(status);
    final duration = _calculateDuration(event);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _showEventDetails(event),
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
                      color: event.type == 'user'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
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
                            event.type == 'user' ? Icons.person : Icons.directions_car,
                            size: isSmallScreen ? 15 : 16,
                            color: event.type == 'user'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
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
                      if (event.type == 'user') ...[
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 13 : 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FutureBuilder<String>(
                                future: _fetchUserName(event.engineer ?? ''),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    );
                                  }
                                  return Text(
                                    'Technician: ${snapshot.data ?? event.engineer ?? 'Unknown'}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 13 : 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FutureBuilder<String>(
                                future: _fetchUserName(event.applicant ?? ''),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    );
                                  }
                                  return Text(
                                    'Applicant: ${snapshot.data ?? event.applicant ?? 'Unknown'}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 13 : 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Job: ${event.job ?? 'N/A'}',
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
                      if (event.type == 'vehicle') ...[
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 13 : 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Vehicle: ${event.registrationNumber ?? 'N/A'}',
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
                                'Driver: ${event.driverName ?? event.driverId ?? 'Unknown'}',
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
                              Icons.person_outline,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 13 : 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FutureBuilder<String>(
                                future: _fetchUserName(event.applicant ?? ''),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text(
                                      'Loading...',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    );
                                  }
                                  return Text(
                                    'Applicant: ${snapshot.data ?? event.applicant ?? 'Unknown'}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              size: isSmallScreen ? 13 : 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Departure: ${event.departure ?? 'N/A'}',
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            size: isSmallScreen ? 13 : 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Destination: ${event.address ?? 'N/A'}',
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
    ).animate().scale(
          duration: const Duration(milliseconds: 100),
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.02, 1.02),
          curve: Curves.easeInOut,
        );
  }
}