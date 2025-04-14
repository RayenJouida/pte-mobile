import 'package:flutter/material.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/models/vehicule_event.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'package:quickalert/quickalert.dart'; // For QuickAlert dialogs

class VehicleReservationScreen extends StatefulWidget {
  final DateTime? selectedDate; // Selected date from the calendar
  final Function(VehicleEvent) onEventCreated; // Callback to pass the new event
  final List<VehicleEvent> events; // List of existing events

  VehicleReservationScreen({
    this.selectedDate,
    required this.onEventCreated,
    required this.events, // Add this parameter
  });

  @override
  _VehicleReservationScreenState createState() => _VehicleReservationScreenState();
}

class _VehicleReservationScreenState extends State<VehicleReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();
  final UserService _userService = UserService();

  // Form fields
  String? _selectedVehicleId;
  String? _selectedDriverId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Dropdown data
  List<Vehicle> _vehicles = [];
  List<dynamic> _drivers = [];
  List<Vehicle> _availableVehicles = []; // Filtered list of available vehicles
  List<dynamic> _availableDrivers = []; // Filtered list of available drivers

  // To track if the form is complete
  bool get isFormComplete {
    return _startDate != null &&
        _endDate != null &&
        _titleController.text.isNotEmpty &&
        _destinationController.text.isNotEmpty &&
        _selectedVehicleId != null &&
        _selectedDriverId != null;
  }

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
    _fetchDrivers();
    // Pre-fill the start date if a selected date is provided
    if (widget.selectedDate != null) {
      _startDate = widget.selectedDate;
    }
    // Add listeners to text controllers to update the button state
    _titleController.addListener(_updateFormState);
    _destinationController.addListener(_updateFormState);
  }

  // Fetch vehicles from the database
  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _availableVehicles = vehicles; // Initialize available vehicles
      });
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load vehicles: $e',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  // Fetch drivers with a valid driving license
  Future<void> _fetchDrivers() async {
    try {
      final drivers = await _userService.fetchDrivers();
      setState(() {
        _drivers = drivers;
        _availableDrivers = drivers; // Initialize available drivers
      });
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load drivers: $e',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  // Get the current user's ID from SharedPreferences
  Future<String?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Submit the form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      print('Form is valid'); // Debug print

      // Check if a vehicle and driver are selected
      if (_selectedVehicleId == null || _selectedDriverId == null) {
        print('Vehicle or driver not selected'); // Debug print
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'Missing Selection',
          text: 'Please select a vehicle and a driver',
          confirmBtnColor: const Color(0xFF0632A1),
        );
        return;
      }

      // Check if start and end dates are selected
      if (_startDate == null || _endDate == null) {
        print('Start or end date not selected'); // Debug print
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'Missing Dates',
          text: 'Please select a start and end date',
          confirmBtnColor: const Color(0xFF0632A1),
        );
        return;
      }

      // Get the current user's ID
      final String? applicantId = await getCurrentUserId();
      if (applicantId == null) {
        print('User not authenticated'); // Debug print
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
        text: 'Do you want to submit this vehicle reservation?',
        confirmBtnText: 'Yes',
        cancelBtnText: 'No',
        confirmBtnColor: const Color(0xFF0632A1),
        onConfirmBtnTap: () async {
          Navigator.pop(context); // Close confirm dialog

          // Create the VehicleEvent object
          final event = VehicleEvent(
            title: _titleController.text,
            start: _startDate!,
            end: _endDate!,
            vehicleId: _selectedVehicleId!,
            driverId: _selectedDriverId!,
            destination: _destinationController.text,
            applicantId: applicantId,
          );

          print('Event to be created: ${event.toJson()}'); // Debug print

          try {
            // Use the VehicleService to create the event
            final createdEvent = await _vehicleService.createEvent(event);

            // Call the callback with the newly created event
            widget.onEventCreated(createdEvent);

            // Show success message
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
            print('Error creating reservation: $e'); // Debug print
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error',
              text: 'Error creating reservation: $e',
              confirmBtnColor: const Color(0xFF0632A1),
            );
          }
        },
      );
    } else {
      print('Form is invalid'); // Debug print
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Invalid Form',
        text: 'Please fill in all required fields',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  // Show date and time picker for start date
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

        // Update available vehicles and drivers based on the selected start time
        if (_endDate != null) {
          _updateAvailableVehiclesAndDrivers(newStartDate, _endDate!);
        }
      }
    }
  }

  // Show date and time picker for end date
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
        return date.isAfter(_startDate!.subtract(Duration(days: 1)));
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

        // Ensure the end date is at least 30 minutes after the start date
        if (newEndDate.isBefore(_startDate!.add(Duration(minutes: 30)))) {
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

        // Update available vehicles and drivers based on the selected time range
        _updateAvailableVehiclesAndDrivers(_startDate!, newEndDate);
      }
    }
  }

  // Get overlapping events for a given time range
  List<VehicleEvent> _getOverlappingEvents(DateTime start, DateTime end) {
    return widget.events.where((event) {
      return (start.isBefore(event.end) && end.isAfter(event.start));
    }).toList();
  }

  // Update available vehicles and drivers based on the selected time range
  void _updateAvailableVehiclesAndDrivers(DateTime start, DateTime end) {
    final overlappingEvents = _getOverlappingEvents(start, end);

    // Get IDs of vehicles and drivers already booked in overlapping events
    final bookedVehicleIds = overlappingEvents.map((event) => event.vehicleId).toSet();
    final bookedDriverIds = overlappingEvents.map((event) => event.driverId).toSet();

    setState(() {
      // Filter vehicles and drivers to exclude booked ones
      _availableVehicles = _vehicles.where((vehicle) => !bookedVehicleIds.contains(vehicle.id)).toList();
      _availableDrivers = _drivers.where((driver) => !bookedDriverIds.contains(driver['_id'])).toList();
    });
  }

  // Update the form state to trigger a rebuild and check if the form is complete
  void _updateFormState() {
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateFormState);
    _destinationController.removeListener(_updateFormState);
    _titleController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if date fields are filled to show other fields
    bool areDatesSelected = _startDate != null && _endDate != null;

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
            child: Center(
              child: Text(
                'Reserve a Vehicle',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),

          // Lower Section (White Background)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Start Date and End Date in the Same Row (Always Visible)
                    Row(
                      children: [
                        Expanded(
                          child: _buildCard(
                            child: InkWell(
                              onTap: _pickStartDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                                child: Text(
                                  _startDate == null
                                      ? 'Select Start Date'
                                      : DateFormat('yyyy-MM-dd HH:mm').format(_startDate!),
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 700.ms),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildCard(
                            child: InkWell(
                              onTap: _pickEndDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                                child: Text(
                                  _endDate == null
                                      ? 'Select End Date'
                                      : DateFormat('yyyy-MM-dd HH:mm').format(_endDate!),
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 800.ms),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Show other fields only if dates are selected
                    if (areDatesSelected) ...[
                      // Title Field
                      _buildCard(
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.title, color: Color(0xFF0632A1)),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                      SizedBox(height: 16),

                      // Destination Field
                      _buildCard(
                        child: TextFormField(
                          controller: _destinationController,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Destination',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.place, color: Color(0xFF0632A1)),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a destination';
                            }
                            return null;
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                      SizedBox(height: 16),

                      // Vehicle Dropdown
                      _buildCard(
                        child: DropdownButtonFormField<String>(
                          value: _selectedVehicleId,
                          dropdownColor: Colors.white,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Vehicle',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.directions_car, color: Color(0xFF0632A1)),
                            border: InputBorder.none,
                          ),
                          items: _availableVehicles.map<DropdownMenuItem<String>>((vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle.id,
                              child: Text('${vehicle.model} (${vehicle.registrationNumber})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVehicleId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a vehicle';
                            }
                            return null;
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                      SizedBox(height: 16),

                      // Driver Dropdown
                      _buildCard(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDriverId,
                          dropdownColor: Colors.white,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Driver',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.person, color: Color(0xFF0632A1)),
                            border: InputBorder.none,
                          ),
                          items: _availableDrivers.map<DropdownMenuItem<String>>((driver) {
                            return DropdownMenuItem<String>(
                              value: driver['_id'] as String,
                              child: Text('${driver['firstName'] as String} ${driver['lastName'] as String}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDriverId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a driver';
                            }
                            return null;
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                      SizedBox(height: 24),
                    ],

                    // Submit Button (Always Visible, Disabled Until Form is Complete)
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isFormComplete ? _submitForm : null,
                        child: Text(
                          'Reserve Vehicle',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0632A1),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // When disabled, make the button grey
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 900.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card Widget
  Widget _buildCard({required Widget child}) {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}