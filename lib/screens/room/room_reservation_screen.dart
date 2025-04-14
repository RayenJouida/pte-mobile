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
import 'package:quickalert/quickalert.dart'; // For QuickAlert dialogs

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
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  Future<String?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
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
          confirmBtnColor: const Color(0xFF0632A1),
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
          confirmBtnColor: const Color(0xFF0632A1),
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
          confirmBtnColor: const Color(0xFF0632A1),
        );
        return;
      }

      // Show confirmation dialog before submitting
      QuickAlert.show(
        context: context,
        type: QuickAlertType.confirm,
        title: 'Confirm Reservation',
        text: 'Do you want to submit this room reservation?',
        confirmBtnText: 'Yes',
        cancelBtnText: 'No',
        confirmBtnColor: const Color(0xFF0632A1),
        onConfirmBtnTap: () async {
          Navigator.pop(context); // Close confirm dialog

          final event = RoomEvent(
            title: _titleController.text,
            start: _startDate!,
            end: _endDate!,
            roomId: _selectedRoomId!,
            applicantId: applicantId,
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
              confirmBtnColor: const Color(0xFF0632A1),
              onConfirmBtnTap: () {
                Navigator.pop(context); // Close success dialog
                Navigator.pop(context); // Close the form
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
                  confirmBtnColor: const Color(0xFF0632A1),
                );
              } else {
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Error',
                  text: 'Error creating reservation: ${e.response?.data ?? e.message}',
                  confirmBtnColor: const Color(0xFF0632A1),
                );
              }
            } else {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: 'Error',
                text: 'Error creating reservation: $e',
                confirmBtnColor: const Color(0xFF0632A1),
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
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate ?? DateTime.now()),
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
        confirmBtnColor: const Color(0xFF0632A1),
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

        if (newEndDate.isBefore(_startDate!.add(const Duration(minutes: 30)))) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            title: 'Invalid Duration',
            text: 'The event must be at least 30 minutes long',
            confirmBtnColor: const Color(0xFF0632A1),
          );
          return;
        }

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
    });
  }

  bool _isFormComplete() {
    return _startDate != null &&
        _endDate != null &&
        _titleController.text.isNotEmpty &&
        _selectedRoomId != null;
  }

  @override
  Widget build(BuildContext context) {
    final bool datesSelected = _startDate != null && _endDate != null;

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
                        child: DropdownButtonFormField<String>(
                          value: _selectedRoomId,
                          dropdownColor: Theme.of(context).colorScheme.background,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Room',
                            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.meeting_room, color: Theme.of(context).colorScheme.primary),
                            border: InputBorder.none,
                          ),
                          items: _availableRooms.map<DropdownMenuItem<String>>((room) {
                            return DropdownMenuItem<String>(
                              value: room.id,
                              child: Text('${room.label} (${room.location})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoomId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a room';
                            }
                            return null;
                          },
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