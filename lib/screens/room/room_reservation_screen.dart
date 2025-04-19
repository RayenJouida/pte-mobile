import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/room.dart';
import 'package:pte_mobile/models/room_event.dart';
import 'package:pte_mobile/services/room_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:quickalert/quickalert.dart';

class RoomReservationScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(RoomEvent) onEventCreated;
  final List<RoomEvent> events;

  RoomReservationScreen({
    this.selectedDate,
    required this.onEventCreated,
    required this.events,
  });

  @override
  _RoomReservationScreenState createState() => _RoomReservationScreenState();
}

class _RoomReservationScreenState extends State<RoomReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final RoomService _roomService = RoomService();
  final UserService _userService = UserService();

  String? _selectedRoomId;
  final TextEditingController _titleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<Room> _rooms = [];
  List<Room> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    if (widget.selectedDate != null) {
      _startDate = widget.selectedDate;
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final rooms = await _roomService.getAllRooms();
      setState(() {
        _rooms = rooms;
        _availableRooms = rooms;
      });
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load rooms: $e',
        confirmBtnColor: Theme.of(context).colorScheme.primary,
      );
    }
  }

  Future<String?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> getCurrentUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      print('Form is valid');

      if (_selectedRoomId == null) {
        print('Room not selected');
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'Missing Selection',
          text: 'Please select a room',
          confirmBtnColor: Theme.of(context).colorScheme.primary,
        );
        return;
      }

      if (_startDate == null || _endDate == null) {
        print('Start or end date not selected');
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'Missing Dates',
          text: 'Please select a start and end date',
          confirmBtnColor: Theme.of(context).colorScheme.primary,
        );
        return;
      }

      final now = DateTime.now();
      if (_startDate!.isBefore(now)) {
        print('Cannot reserve past dates');
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'Invalid Date',
          text: 'Cannot reserve a room for past dates',
          confirmBtnColor: Theme.of(context).colorScheme.primary,
        );
        return;
      }

      final String? applicantId = await getCurrentUserId();
      if (applicantId == null) {
        print('User not authenticated');
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Authentication Error',
          text: 'User not authenticated',
          confirmBtnColor: Theme.of(context).colorScheme.primary,
        );
        return;
      }

      final String? applicantName = await getCurrentUserName();
      if (applicantName == null) {
        print('User name not found');
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Authentication Error',
          text: 'User name not found',
          confirmBtnColor: Theme.of(context).colorScheme.primary,
        );
        return;
      }

      final selectedRoom = _rooms.firstWhere((room) => room.id == _selectedRoomId);
      final roomLabel = selectedRoom.label;

      QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: 'Confirm Reservation',
        text: 'Do you want to submit this room reservation?',
        confirmBtnText: 'Yes',
        cancelBtnText: 'No',
        confirmBtnColor: Theme.of(context).colorScheme.primary,
        onConfirmBtnTap: () async {
          Navigator.pop(context);

          final event = RoomEvent(
            title: _titleController.text,
            start: _startDate!,
            end: _endDate!,
            roomId: _selectedRoomId!,
            applicantId: applicantId,
            roomLabel: roomLabel,
            applicantName: applicantName,
          );

          print('Event to be created: ${event.toJson()}');

          try {
            final createdEvent = await _roomService.createEvent(event);

            print('Event created successfully: $createdEvent');

            widget.onEventCreated(createdEvent);

            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Success!',
              text: 'Reservation created successfully!',
              confirmBtnColor: Theme.of(context).colorScheme.primary,
              onConfirmBtnTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            );
          } catch (e) {
            print('Error creating reservation: $e');

            if (e is DioError) {
              if (e.response?.statusCode == 500 &&
                  e.response?.data != null &&
                  e.response!.data.toString().contains('Dates already reserved')) {
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.warning,
                  title: 'Time Slot Reserved',
                  text: 'The selected time slot is already reserved. Please pick a free time slot.',
                  confirmBtnColor: Theme.of(context).colorScheme.primary,
                );
              } else {
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Error',
                  text: 'Error creating reservation: ${e.response?.data ?? e.message}',
                  confirmBtnColor: Theme.of(context).colorScheme.primary,
                );
              }
            } else {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: 'Error',
                text: 'Error creating reservation: $e',
                confirmBtnColor: Theme.of(context).colorScheme.primary,
              );
            }
          }
        },
      );
    } else {
      print('Form is invalid');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Invalid Form',
        text: 'Please fill in all required fields',
        confirmBtnColor: Theme.of(context).colorScheme.primary,
      );
    }
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)), // 10 years back
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate ?? DateTime.now()),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        final newStartDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _startDate = newStartDate;
        });

        if (_endDate != null) {
          _updateAvailableRooms(newStartDate, _endDate!);
        }
      }
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Missing Start Date',
        text: 'Please select a start date first',
        confirmBtnColor: Theme.of(context).colorScheme.primary,
      );
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime date) {
        return date.isAfter(_startDate!.subtract(const Duration(days: 1)));
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate ?? _startDate!),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final newEndDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _endDate = newEndDate;
        });

        _updateAvailableRooms(_startDate!, newEndDate);
      }
    }
  }

  List<RoomEvent> _getOverlappingEvents(DateTime start, DateTime end) {
    return widget.events.where((event) {
      return (start.isBefore(event.end) && end.isAfter(event.start));
    }).toList();
  }

  void _updateAvailableRooms(DateTime start, DateTime end) {
  final overlappingEvents = _getOverlappingEvents(start, end);
  final bookedRoomIds = overlappingEvents.map((event) => event.roomId).toSet();

  setState(() {
    _availableRooms = _rooms.where((room) => !bookedRoomIds.contains(room.id)).toList();
    if (!_availableRooms.any((room) => room.id == _selectedRoomId)) {
      _selectedRoomId = null;
    }
  });

  if (_availableRooms.isEmpty) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'No Rooms Available',
      text: 'Sorry, all rooms are booked for the selected time slot!',
      confirmBtnText: 'OK',
      confirmBtnColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.background,
      titleColor: Theme.of(context).colorScheme.onSurface,
      textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}

  bool _isFormComplete() {
    final now = DateTime.now();
    return _startDate != null &&
        _endDate != null &&
        _titleController.text.isNotEmpty &&
        _selectedRoomId != null &&
        _startDate!.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    final bool datesSelected = _startDate != null && _endDate != null;
    final bookedRoomIds = _getOverlappingEvents(_startDate ?? DateTime.now(), _endDate ?? DateTime.now().add(const Duration(hours: 1))).map((event) => event.roomId).toSet();

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Text(
                'Reserve a Room',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCard(
                            child: InkWell(
                              onTap: _pickStartDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                  prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                                  border: InputBorder.none,
                                ),
                                child: Text(
                                  _startDate == null
                                      ? 'Select Start Date'
                                      : DateFormat('yyyy-MM-dd HH:mm').format(_startDate!),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCard(
                            child: InkWell(
                              onTap: _pickEndDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date',
                                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                  prefixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                                  border: InputBorder.none,
                                ),
                                child: Text(
                                  _endDate == null
                                      ? 'Select End Date'
                                      : DateFormat('yyyy-MM-dd HH:mm').format(_endDate!),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                        ),
                      ],
                    ),
                    if (datesSelected) ...[
                      const SizedBox(height: 16),
                      _buildCard(
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.title, color: Theme.of(context).colorScheme.primary),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                      const SizedBox(height: 16),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Room',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _rooms.length,
                                itemBuilder: (context, index) {
                                  final room = _rooms[index];
                                  final isBooked = bookedRoomIds.contains(room.id);
                                  final isSelected = _selectedRoomId == room.id;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: isBooked
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedRoomId = room.id;
                                              });
                                            },
                                      child: Container(
                                        width: 150,
                                        decoration: BoxDecoration(
                                          color: isBooked
                                              ? Colors.grey.shade300
                                              : isSelected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.background,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                room.label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isBooked
                                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                                                      : isSelected
                                                          ? Theme.of(context).colorScheme.onPrimary
                                                          : Theme.of(context).colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                room.location,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isBooked
                                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                                                      : isSelected
                                                          ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFormComplete() ? _submitForm : null,
                        child: Text(
                          'Reserve Room',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isFormComplete()
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormComplete()
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 700.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}