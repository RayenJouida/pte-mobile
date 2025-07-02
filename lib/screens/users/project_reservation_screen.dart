import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import 'package:pte_mobile/models/vehicule_event.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/services/task_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/models/user_event.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ProjectReservationScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Function(dynamic) onEventCreated;
  final List<UserEvent> events;

  const ProjectReservationScreen({
    Key? key,
    required this.selectedDate,
    required this.onEventCreated,
    required this.events,
  }) : super(key: key);

  @override
  _ProjectReservationScreenState createState() => _ProjectReservationScreenState();
}

class _ProjectReservationScreenState extends State<ProjectReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  Map<String, dynamic>? _taskDetails;
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  bool _isLoadingVehicles = false;
  List<User> _users = [];
  User? _selectedUser;
  String? _selectedUserEmail;
  List<Vehicle> _availableVehicles = [];
  Vehicle? _selectedVehicle;
  String? _needRide;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _destination;
  LatLngBounds? _routeBounds;
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  static const LatLng _startLocation = LatLng(36.8289426, 10.2032308);

  @override
  void initState() {
    super.initState();
    _loadUsersAndEmail();
    _needRide = 'No';
    _startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      9,
      0,
    );
    _endDateTime = _startDateTime!.add(const Duration(hours: 1));
    _startDateController.text = DateFormat('MMM dd, yyyy HH:mm').format(_startDateTime!);
    _endDateController.text = DateFormat('MMM dd, yyyy HH:mm').format(_endDateTime!);
  }

  Future<void> _loadUsersAndEmail() async {
    try {
      final usersData = await _userService.fetchUsers();
      final users = usersData
          .map((userData) => User.fromJson(userData))
          .where((user) => user.roles != 'ADMIN')
          .toList();
      final prefs = await SharedPreferences.getInstance();
      final currentEmail = prefs.getString('email');

      setState(() {
        _users = users;
        _isLoadingUsers = false;
        if (currentEmail != null && users.isNotEmpty) {
          _selectedUser = users.firstWhere(
            (user) => user.email == currentEmail,
            orElse: () => users.first,
          );
          _selectedUserEmail = _selectedUser?.email;
        }
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoadingUsers = false;
      });
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load users: $e',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  Future<void> _fetchAvailableVehicles() async {
    if (_startDateTime == null || _endDateTime == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Warning',
        text: 'Please select start and end dates before checking vehicle availability.',
        confirmBtnColor: const Color(0xFF0632A1),
      );
      return;
    }

    if (_endDateTime!.isBefore(_startDateTime!)) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Warning',
        text: 'End date must be after start date.',
        confirmBtnColor: const Color(0xFF0632A1),
      );
      return;
    }

    setState(() {
      _isLoadingVehicles = true;
      _availableVehicles = [];
      _selectedVehicle = null;
    });

    try {
      final dates = {
        'start': _startDateTime!.toUtc().toIso8601String(),
        'end': _endDateTime!.toUtc().toIso8601String(),
      };
      print('Fetching vehicles with dates: $dates');

      final vehicles = await _vehicleService.fetchAvailableVehicles(dates);
      print('Fetched Vehicles: ${vehicles.length}');
      print('Vehicles: ${vehicles.map((v) => "${v.model} (${v.id})").toList()}');

      setState(() {
        _availableVehicles = vehicles;
        _selectedVehicle = vehicles.isNotEmpty ? vehicles.first : null;
        _isLoadingVehicles = false;
      });

      if (vehicles.isEmpty) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.info,
          title: 'No Vehicles',
          text: 'No vehicles available for the selected time range.',
          confirmBtnColor: const Color(0xFF0632A1),
        );
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
      setState(() {
        _isLoadingVehicles = false;
      });
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load available vehicles: $e',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;

    try {
      print('Geocoding address: $address');

      List<String> addressVariations = [address.trim()];
      String cleanedAddress = address
          .replaceAll(RegExp(r'Délégation\s+'), '')
          .replaceAll(RegExp(r'Gouvernorat\s+'), '')
          .replaceAll(RegExp(r'Municipalité\s+'), '')
          .replaceAll(RegExp(r',\s*,'), ',')
          .trim();

      if (cleanedAddress != address.trim()) {
        addressVariations.add(cleanedAddress);
      }

      List<String> parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      if (parts.length > 2) {
        addressVariations.add('${parts.take(2).join(', ')}, Tunisia');
        if (parts.length > 3) {
          addressVariations.add('${parts.take(3).join(', ')}, Tunisia');
        }
      }

      if (address.toLowerCase().contains('tunis')) {
        addressVariations.add('${parts.first}, Tunis, Tunisia');
      }

      for (String testAddress in addressVariations) {
        if (testAddress.isEmpty) continue;

        print('Trying address variation: $testAddress');

        List<String> geocodingUrls = [
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(testAddress)}&countrycodes=tn&limit=5&addressdetails=1',
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(testAddress)}&limit=5&addressdetails=1',
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(testAddress)}&count=5&language=en&format=json',
        ];

        for (String url in geocodingUrls) {
          try {
            final response = await http.get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'PTE-Mobile-App/1.0 (Flutter)',
                'Accept': 'application/json',
              },
            );

            print('Geocoding URL: $url');
            print('Response status: ${response.statusCode}');
            print('Response body: ${response.body}');

            if (response.statusCode == 200) {
              final data = json.decode(response.body);

              if (data is List && data.isNotEmpty) {
                for (var result in data) {
                  final lat = double.tryParse(result['lat']?.toString() ?? '');
                  final lon = double.tryParse(result['lon']?.toString() ?? '');

                  if (lat != null && lon != null) {
                    if (lat >= 30.0 && lat <= 38.0 && lon >= 7.0 && lon <= 12.0) {
                      print('Found valid coordinates: $lat, $lon for address: $testAddress');
                      return LatLng(lat, lon);
                    }
                  }
                }
              }

              if (data is Map && data['results'] != null) {
                final results = data['results'] as List;
                for (var result in results) {
                  final lat = result['latitude']?.toDouble();
                  final lon = result['longitude']?.toDouble();

                  if (lat != null && lon != null) {
                    if (lat >= 30.0 && lat <= 38.0 && lon >= 7.0 && lon <= 12.0) {
                      print('Found valid coordinates from Open-Meteo: $lat, $lon');
                      return LatLng(lat, lon);
                    }
                  }
                }
              }
            }

            await Future.delayed(Duration(milliseconds: 1500));
          } catch (e) {
            print('Error with geocoding service: $e');
            continue;
          }
        }
      }

      final coordRegex = RegExp(r'(-?\d+\.?\d*),\s*(-?\d+\.?\d*)');
      final match = coordRegex.firstMatch(address);
      if (match != null) {
        final lat = double.tryParse(match.group(1)!);
        final lon = double.tryParse(match.group(2)!);
        if (lat != null && lon != null) {
          print('Extracted coordinates from address: $lat, $lon');
          return LatLng(lat, lon);
        }
      }

      print('Could not geocode address: $address');
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  Future<List<LatLng>> _getRoutePoints(LatLng start, LatLng end) async {
    try {
      print('Getting route from ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}');

      final response = await http.get(
        Uri.parse('https://router.project-osrm.org/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${end.longitude},${end.latitude}?overview=full&geometries=geojson'),
        headers: {'User-Agent': 'FlutterApp/1.0'},
      );

      print('Routing response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          final routePoints = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
          print('Route points count: ${routePoints.length}');
          return routePoints;
        }
      }

      print('Using fallback straight line route');
      return [start, end];
    } catch (e) {
      print('Routing error: $e');
      return [start, end];
    }
  }

  Future<void> _fetchTaskDetails() async {
    if (_formKey.currentState!.validate() && _selectedUserEmail != null) {
      setState(() {
        _isLoading = true;
        _destination = null;
        _routePoints = [];
        _taskDetails = null;
        _routeBounds = null;
      });

      try {
        print('Fetching task details...');
        final details = await _taskService.getTaskByUser(
          _refController.text.trim(),
          _selectedUserEmail!.trim(),
        );

        print('Task details received: $details');

        if (details['err'] == false) {
          setState(() {
            _taskDetails = details['data'];
            if (_taskDetails!['StartDate'] != null) {
              _startDateTime = DateTime.parse(_taskDetails!['StartDate']);
              _startDateController.text = DateFormat('MMM dd, yyyy HH:mm').format(_startDateTime!);
            }
            if (_taskDetails!['Deadline'] != null) {
              _endDateTime = DateTime.parse(_taskDetails!['Deadline']);
              _endDateController.text = DateFormat('MMM dd, yyyy HH:mm').format(_endDateTime!);
            }
          });

          final siteAddress = _taskDetails!['Project']?['client']?['address'];
          print('Site address: $siteAddress');

          if (siteAddress != null && siteAddress.toString().isNotEmpty) {
            print('Attempting to geocode address...');
            final destination = await _geocodeAddress(siteAddress.toString());

            if (destination != null) {
              print('Destination found: ${destination.latitude}, ${destination.longitude}');

              final routePoints = await _getRoutePoints(_startLocation, destination);

              setState(() {
                _destination = destination;
                _routePoints = routePoints;
                _routeBounds = LatLngBounds.fromPoints([_startLocation, destination]);
              });

              Future.delayed(Duration(milliseconds: 500), () {
                if (_routeBounds != null && mounted) {
                  try {
                    _mapController.fitBounds(
                      _routeBounds!,
                      options: FitBoundsOptions(
                        padding: EdgeInsets.all(80),
                        maxZoom: 15.0,
                      ),
                    );
                  } catch (e) {
                    print('Error fitting bounds: $e');
                    final centerLat = (_startLocation.latitude + destination.latitude!) / 2;
                    final centerLng = (_startLocation.longitude + destination.longitude!) / 2;
                    _mapController.move(LatLng(centerLat, centerLng), 12.0);
                  }
                }
              });

              QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Success',
                text: 'Task details loaded successfully!',
                confirmBtnColor: const Color(0xFF0632A1),
              );
            } else {
              print('Could not geocode address');
              QuickAlert.show(
                context: context,
                type: QuickAlertType.warning,
                title: 'Warning',
                text: 'Could not determine location for: $siteAddress\nTask details loaded but map location unavailable.',
                confirmBtnColor: const Color(0xFF0632A1),
              );
            }
          } else {
            print('No site address provided');
            QuickAlert.show(
              context: context,
              type: QuickAlertType.info,
              title: 'Info',
              text: 'Task details loaded but no site address provided.',
              confirmBtnColor: const Color(0xFF0632A1),
            );
          }
        } else {
          throw Exception(details['message'] ?? 'Failed to fetch task details');
        }
      } catch (e) {
        print('Error fetching task details: $e');
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Failed to fetch task details: ${e.toString()}',
          confirmBtnColor: const Color(0xFF0632A1),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Warning',
        text: 'Please select a user and enter a valid reference.',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate() && _taskDetails != null && _selectedUserEmail != null) {
      if (_needRide == 'Yes' && _selectedVehicle == null) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'Warning',
          text: 'Please select a vehicle to proceed.',
          confirmBtnColor: const Color(0xFF0632A1),
        );
        return;
      }

      bool proceed = true;
      if (_taskDetails!['StartDate'] != null && _taskDetails!['Deadline'] != null) {
        final taskStart = DateTime.parse(_taskDetails!['StartDate']);
        final taskEnd = DateTime.parse(_taskDetails!['Deadline']);
        final startDiff = _startDateTime!.difference(taskStart).inSeconds.abs();
        final endDiff = _endDateTime!.difference(taskEnd).inSeconds.abs();
        if (startDiff > 3600 || endDiff > 3600) {
          proceed = await QuickAlert.show(
            context: context,
            type: QuickAlertType.confirm,
            title: 'Confirm Date Changes',
            text: 'You’ve changed the dates significantly from the task’s original schedule. Proceed?',
            confirmBtnText: 'Confirm',
            cancelBtnText: 'Cancel',
            confirmBtnColor: const Color(0xFF0632A1),
            onConfirmBtnTap: () => Navigator.pop(context, true),
            onCancelBtnTap: () => Navigator.pop(context, false),
          ) ?? false;
        }
      }

      if (!proceed) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? 'unknown';

        if (_needRide == 'Yes') {
          final event = VehicleEvent(
            title: 'Project Reservation - ${_taskDetails!['Title'] ?? _refController.text}',
            start: _startDateTime,
            end: _endDateTime,
            vehicleId: _selectedVehicle!.id,
            driverId: userId,
            applicantId: userId,
            destination: _taskDetails!['Project']?['client']?['address'] ?? 'Unknown',
            departure: 'SIMOP Headquarters, Tunis',
            caseNumber: _refController.text.trim(),
            isAccepted: true,
          );

          final createdEvent = await _vehicleService.createEvent(event);
          print('Vehicle Event Created: ${createdEvent.id}');
          final userEvent = UserEvent(
            id: createdEvent.id ?? 'unknown-${DateTime.now().millisecondsSinceEpoch}',
            title: createdEvent.title ?? 'Untitled Event',
            start: createdEvent.start!,
            end: createdEvent.end!,
            engineer: userId,
            applicant: userId,
            job: createdEvent.caseNumber!,
            address: createdEvent.destination!,
            isAccepted: createdEvent.isAccepted!,
          );
          widget.onEventCreated(userEvent);
        } else {
          final event = await _userService.createUserEvent(
            title: 'Project Reservation - ${_taskDetails!['Title'] ?? _refController.text}',
            start: _startDateTime!,
            end: _endDateTime!,
            engineer: userId,
            applicant: userId,
            job: _refController.text.trim(),
            address: _taskDetails!['Project']?['client']?['address'] ?? 'Unknown',
            isAccepted: true,
          );
          print('User Event Created: ${event.id}');
          widget.onEventCreated(event);
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
      } catch (e) {
        print('Error creating event: $e');
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Failed to create event: ${e.toString()}',
          confirmBtnColor: const Color(0xFF0632A1),
        );
        if (e.toString().contains('type \'String\' is not a subtype of type \'int\'')) {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('userId') ?? 'unknown';
          final userEvent = UserEvent(
            id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Project Reservation - ${_taskDetails!['Title'] ?? _refController.text}',
            start: _startDateTime!,
            end: _endDateTime!,
            engineer: userId,
            applicant: userId,
            job: _refController.text.trim(),
            address: _taskDetails!['Project']?['client']?['address'] ?? 'Unknown',
            isAccepted: true,
          );
          widget.onEventCreated(userEvent);
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Warning',
        text: 'Please fetch task details, select a user, and select valid dates.',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.12,
            decoration: const BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 25,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      tooltip: 'Go back',
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Project Reservation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCard(
                      child: _isLoadingUsers
                          ? Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF0632A1)),
                                  SizedBox(width: 16),
                                  Text('Loading users...', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<User>(
                                  value: _selectedUser,
                                  decoration: InputDecoration(
                                    labelText: 'Select User',
                                    labelStyle: TextStyle(color: Colors.grey),
                                    prefixIcon: Icon(Icons.person, color: Color(0xFF0632A1)),
                                    border: InputBorder.none,
                                  ),
                                  items: _users.map((user) {
                                    return DropdownMenuItem<User>(
                                      value: user,
                                      child: Text(
                                        '${user.firstName} ${user.lastName}',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (user) {
                                    setState(() {
                                      _selectedUser = user;
                                      _selectedUserEmail = user?.email;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Please select a user' : null,
                                ),
                                if (_selectedUserEmail != null) ...[
                                  SizedBox(height: 16),
                                  _buildReadOnlyField(
                                    label: 'Email',
                                    value: _selectedUserEmail!,
                                    icon: Icons.email,
                                  ),
                                ],
                              ],
                            ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                    SizedBox(height: 16),
                    _buildCard(
                      child: TextFormField(
                        controller: _refController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Reference (e.g., P-6811)',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.confirmation_number, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a reference' : null,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fetchTaskDetails,
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : Text(
                                'Fetch Details',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0632A1),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                    ),
                    if (_taskDetails != null && !_isLoading) ...[
                      SizedBox(height: 16),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _taskDetails!['Title'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0632A1),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _taskDetails!['Project']?['Type'] ?? 'PMA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildReadOnlyField(
                              label: 'Project Name',
                              value: _taskDetails!['Project']?['Projectname'] ?? 'N/A',
                              icon: Icons.work,
                            ),
                            SizedBox(height: 8),
                            _buildReadOnlyField(
                              label: 'Client Name',
                              value: _taskDetails!['Project']?['client']?['fullName'] ?? 'N/A',
                              icon: Icons.person,
                            ),
                            SizedBox(height: 8),
                            _buildReadOnlyField(
                              label: 'Site Address',
                              value: _taskDetails!['Project']?['client']?['address'] ?? 'N/A',
                              icon: Icons.location_on,
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Status:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(width: 8),
                                _buildStatusIndicator(_taskDetails!['Status'] ?? 'N/A'),
                              ],
                            ),
                            SizedBox(height: 8),
                            _buildReadOnlyField(
                              label: 'Priority',
                              value: _taskDetails!['Priority'] ?? 'N/A',
                              icon: Icons.priority_high,
                            ),
                            SizedBox(height: 8),
                            _buildReadOnlyField(
                              label: 'Executors',
                              value: (_taskDetails!['Executor'] as List<dynamic>?)
                                      ?.map((e) => e['fullName'] ?? 'Unknown')
                                      .join(', ') ??
                                  'N/A',
                              icon: Icons.group,
                            ),
                            if (_destination != null) ...[
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.green, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Destination: ${_destination!.latitude.toStringAsFixed(4)}, ${_destination!.longitude.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                      if (_destination != null && _routePoints.isNotEmpty) ...[
                        SizedBox(height: 16),
                        _buildCard(
                          child: SizedBox(
                            height: 300,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                center: _startLocation,
                                zoom: 12.0,
                                minZoom: 5.0,
                                maxZoom: 18.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: ['a', 'b', 'c'],
                                  userAgentPackageName: 'com.example.app',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 4.0,
                                      color: Color(0xFF0632A1),
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _startLocation,
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                    if (_destination != null)
                                      Marker(
                                        point: _destination!,
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.location_pin,
                                          color: Colors.green,
                                          size: 40,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(delay: 650.ms),
                      ],
                      SizedBox(height: 16),
                      _buildCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _startDateController,
                                readOnly: true,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'Start Date & Time',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                                onTap: () {
                                  showDatePicker(
                                    context: context,
                                    initialDate: _startDateTime ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(Duration(days: 1825)),
                                    lastDate: DateTime.now().add(Duration(days: 365)),
                                  ).then((date) {
                                    if (date != null) {
                                      showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_startDateTime ?? DateTime.now()),
                                      ).then((time) {
                                        if (time != null) {
                                          setState(() {
                                            _startDateTime = DateTime(
                                              date.year,
                                              date.month,
                                              date.day,
                                              time.hour,
                                              time.minute,
                                            );
                                            _startDateController.text =
                                                DateFormat('MMM dd, yyyy HH:mm').format(_startDateTime!);
                                            if (_needRide == 'Yes') {
                                              _fetchAvailableVehicles();
                                            }
                                          });
                                        }
                                      });
                                    }
                                  });
                                },
                                validator: (value) =>
                                    _startDateTime == null ? 'Please select a start date' : null,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _endDateController,
                                readOnly: true,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'End Date & Time',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                                onTap: () {
                                  showDatePicker(
                                    context: context,
                                    initialDate: _endDateTime ?? _startDateTime ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(Duration(days: 1825)),
                                    lastDate: DateTime.now().add(Duration(days: 365)),
                                  ).then((date) {
                                    if (date != null) {
                                      showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_endDateTime ?? DateTime.now()),
                                      ).then((time) {
                                        if (time != null) {
                                          setState(() {
                                            _endDateTime = DateTime(
                                              date.year,
                                              date.month,
                                              date.day,
                                              time.hour,
                                              time.minute,
                                            );
                                            _endDateController.text =
                                                DateFormat('MMM dd, yyyy HH:mm').format(_endDateTime!);
                                            if (_needRide == 'Yes') {
                                              _fetchAvailableVehicles();
                                            }
                                          });
                                        }
                                      });
                                    }
                                  });
                                },
                                validator: (value) => _endDateTime == null ||
                                        _endDateTime!.isBefore(_startDateTime!)
                                    ? 'End date must be after start date'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 700.ms),
                      SizedBox(height: 16),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.directions_car, color: Color(0xFF0632A1)),
                                SizedBox(width: 8),
                                Text(
                                  'Need a ride?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Spacer(),
                                Switch(
                                  value: _needRide == 'Yes',
                                  onChanged: (value) {
                                    setState(() {
                                      _needRide = value ? 'Yes' : 'No';
                                      if (value) {
                                        _fetchAvailableVehicles();
                                      } else {
                                        _availableVehicles = [];
                                        _selectedVehicle = null;
                                      }
                                    });
                                  },
                                  activeColor: Color(0xFF0632A1),
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.grey[300],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 750.ms),
                      if (_needRide == 'Yes') ...[
                        SizedBox(height: 16),
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cars available for booking from ${_startDateController.text} to ${_endDateController.text}. Choose your preferred car to proceed:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 12),
                              _isLoadingVehicles
                                  ? Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircularProgressIndicator(color: Color(0xFF0632A1)),
                                          SizedBox(width: 16),
                                          Text('Loading vehicles...', style: TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    )
                                  : DropdownButtonFormField<Vehicle>(
                                      value: _selectedVehicle,
                                      decoration: InputDecoration(
                                        labelText: 'Select Vehicle',
                                        labelStyle: TextStyle(color: Colors.grey),
                                        prefixIcon: Icon(Icons.car_rental, color: Color(0xFF0632A1)),
                                        border: InputBorder.none,
                                      ),
                                      items: _availableVehicles.isEmpty
                                          ? [
                                              DropdownMenuItem<Vehicle>(
                                                value: null,
                                                enabled: false,
                                                child: Text('No vehicles available'),
                                              ),
                                            ]
                                          : _availableVehicles.map((vehicle) {
                                              return DropdownMenuItem<Vehicle>(
                                                value: vehicle,
                                                child: Text(
                                                  '${vehicle.model ?? 'Unknown'} - ${vehicle.registrationNumber ?? 'N/A'} (${vehicle.type ?? 'N/A'})',
                                                  style: TextStyle(color: Colors.black),
                                                ),
                                              );
                                            }).toList(),
                                      onChanged: (vehicle) {
                                        setState(() {
                                          _selectedVehicle = vehicle;
                                        });
                                        print('Selected Vehicle: ${vehicle?.id}');
                                      },
                                      validator: (value) => value == null && _needRide == 'Yes'
                                          ? 'Please select a vehicle'
                                          : null,
                                    ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(delay: 800.ms),
                      ],
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isLoadingVehicles ? null : _createEvent,
                          child: Text(
                            'Add Event',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0632A1),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: Colors.grey,
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(delay: 850.ms),
                )],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF0632A1), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'in progress':
        statusColor = Colors.orange;
        statusIcon = Icons.work;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}