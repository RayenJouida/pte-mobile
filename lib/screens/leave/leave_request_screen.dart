import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/leave/my_leave_requests_screen.dart';
import 'package:pte_mobile/services/leave_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';

class LeaveRequestScreen extends StatefulWidget {
  final int? currentIndex;

  const LeaveRequestScreen({Key? key, this.currentIndex}) : super(key: key);

  @override
  _LeaveRequestScreenState createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeaveService _leaveService = LeaveService();
  final UserService _userService = UserService();

  final TextEditingController _noteController = TextEditingController();
  String? _applicantId;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _halfDayTime; // For 1/2 Day leave
  String? _type;
  User? _supervisor;
  List<User> _supervisors = [];
  int _currentStep = 0;
  bool _isLoading = false;
  File? _certifFile; // For certificate upload
  String? _currentUserRole;
  int _currentIndex = 0; // Will be set dynamically

  final List<String> _leaveTypes = [
    '1/2 Day',
    'Sick Leave',
    'Personal Leave',
    'Annual Leave',
    'Unpaid Leave',
    'Maternity Leave',
    'Authorisation Leaves',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.currentIndex != null) {
      _currentIndex = widget.currentIndex!;
    } else {
      _initializeIndex().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    _checkAuthentication();
    _fetchCurrentUserRole();
  }

  Future<void> _initializeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'ASSISTANT';
    print('Detected role: $role');
    switch (role.toUpperCase()) {
      case 'ADMIN':
        _currentIndex = 13; // Leave Request index for Admin
        break;
      case 'ASSISTANT':
        _currentIndex = 7; // Leave Request index for Assistant
        break;
      case 'ENGINEER':
        _currentIndex = 6; // Leave Request index for Engineer
        break;
      case 'LAB-MANAGER':
        _currentIndex = 8; // Leave Request index for Lab Manager
        break;
      default:
        _currentIndex = 7; // Default to Assistant's index
    }
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserRole = prefs.getString('userRole') ?? 'Assistant';
        print('Current user role set to: $_currentUserRole');
      });
    }
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('authToken');
    print('User ID: $userId');
    print('Token: $token');
    if (userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (mounted) {
      setState(() {
        _applicantId = userId;
      });
    }
    _fetchSupervisors();
  }

  Future<void> _fetchSupervisors() async {
    try {
      final users = await _userService.fetchUsers();
      if (mounted) {
        setState(() {
          _supervisors = users
              .map((user) => User.fromJson(user))
              .where((user) => user.teamLeader == true)
              .toList();
        });
      }
      print('Filtered supervisors (team leaders): ${_supervisors.map((u) => "${u.firstName} ${u.lastName}").toList()}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load team leaders: $e')),
        );
      }
    }
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate.toUtc();
          if (_type == '1/2 Day') {
            _endDate = selectedDate.toUtc();
            _selectHalfDayTime();
          }
        } else {
          if (selectedDate.toUtc().isAfter(_startDate?.toUtc() ?? DateTime.now().toUtc()) || 
              selectedDate.toUtc() == _startDate?.toUtc()) {
            _endDate = selectedDate.toUtc();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End date must be on or after start date')),
            );
          }
        }
      });
    }
  }

  Future<void> _selectHalfDayTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null && mounted) {
      setState(() {
        _halfDayTime = selectedTime;
      });
    }
  }

  Future<void> _pickCertifFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null && mounted) {
      setState(() {
        _certifFile = File(result.files.single.path!);
      });
    }
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        if (_type == 'Sick Leave' || _type == 'Maternity Leave') {
          return _type != null && _supervisor != null && _certifFile != null;
        }
        return _type != null && _supervisor != null;
      case 1:
        if (_type == '1/2 Day') {
          return _startDate != null && _halfDayTime != null;
        }
        return _startDate != null && _endDate != null;
      default:
        return false;
    }
  }

  void _showValidationError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please complete all required fields',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitRequest() async {
    if (!_isStepValid(1)) {
      _showValidationError();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      print('No token found, redirecting to login');
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Confirm Submission',
      text: 'Do you want to submit this leave request?',
      confirmBtnText: 'Yes',
      cancelBtnText: 'No',
      confirmBtnColor: const Color(0xFF2FCCBA),
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Close confirm dialog

        try {
          final leave = await _leaveService.createLeaveRequest(
            fullName: prefs.getString('userName') ?? '',
            email: prefs.getString('email') ?? '',
            startDate: _startDate!.toUtc(),
            endDate: _type == '1/2 Day' ? _startDate!.toUtc() : _endDate!.toUtc(),
            type: _type!,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
            applicantId: _applicantId!,
            supervisorId: _supervisor!.id,
            certifFile: _certifFile,
          );

          print('Leave request created successfully: $leave');

          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Success!',
            text: "Your leave request has been submitted. You'll be notified once it's processed.",
            confirmBtnColor: const Color(0xFF0632A1),
            onConfirmBtnTap: () {
              Navigator.pop(context); // Close success alert
              if (mounted) {
                _formKey.currentState?.reset();
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _halfDayTime = null;
                  _type = null;
                  _supervisor = null;
                  _certifFile = null;
                  _noteController.clear();
                  _currentStep = 0;
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyLeaveRequestsScreen()),
                );
              }
            },
          );
        } catch (e) {
          print('Error submitting leave request: $e');
          if (e.toString().contains('Invalid User data')) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Success!',
              text: "Your leave request has been submitted. You'll be notified once it's processed.",
              confirmBtnColor: const Color(0xFF0632A1),
              onConfirmBtnTap: () {
                Navigator.pop(context); // Close success alert
                if (mounted) {
                  _formKey.currentState?.reset();
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _halfDayTime = null;
                    _type = null;
                    _supervisor = null;
                    _certifFile = null;
                    _noteController.clear();
                    _currentStep = 0;
                  });
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MyLeaveRequestsScreen()),
                  );
                }
              },
            );
          } else {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error!',
              text: 'Error submitting leave request: $e',
              confirmBtnColor: const Color(0xFF0632A1),
              onConfirmBtnTap: () {
                Navigator.pop(context); // Close error alert
              },
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  void _handleTabChange(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index; // Sync with navigation
      });
    }
    if (index == _currentIndex) _fetchSupervisors(); // Refresh data only for this screen
  }

  @override
  Widget build(BuildContext context) {
    final bool isNextEnabled = _isStepValid(_currentStep);

    return Scaffold(
      drawer: _currentUserRole == 'ADMIN'
          ? AdminSidebar(
              currentIndex: _currentIndex,
              onTabChange: (index) {
                _handleTabChange(index);
              },
            )
          : _currentUserRole == 'LAB-MANAGER'
              ? LabManagerSidebar(
                  currentIndex: _currentIndex,
                  onTabChange: (index) {
                    _handleTabChange(index);
                  },
                )
              : _currentUserRole == 'ENGINEER'
                  ? EngineerSidebar(
                      currentIndex: _currentIndex,
                      onTabChange: (index) {
                        _handleTabChange(index);
                      },
                    )
                  : AssistantSidebar(
                      currentIndex: _currentIndex,
                      onTabChange: (index) {
                        _handleTabChange(index);
                      },
                    ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0632A1),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          'Leave Request',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
                      ),
                      Positioned(
                        left: 16,
                        top: MediaQuery.of(context).padding.top + 16,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                    ],
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(2, (index) {
                              return Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentStep == index
                                      ? const Color(0xFF0632A1)
                                      : Colors.grey[300],
                                ),
                              ).animate().fade(duration: 300.ms);
                            }),
                          ),
                          const SizedBox(height: 24),

                          // Step 0: Leave Details
                          if (_currentStep == 0) ...[
                            _buildCard(
                              isValid: _type != null,
                              child: DropdownButtonFormField<String>(
                                value: _type,
                                decoration: const InputDecoration(
                                  labelText: 'Leave Type',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.category, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                                items: _leaveTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type, style: const TextStyle(color: Colors.black)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      _type = value;
                                      _certifFile = null;
                                      _halfDayTime = null;
                                    });
                                  }
                                },
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                            const SizedBox(height: 16),
                            _buildCard(
                              isValid: _supervisor != null,
                              child: DropdownButtonFormField<User>(
                                value: _supervisor,
                                decoration: const InputDecoration(
                                  labelText: 'Supervisor',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.supervisor_account, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                                items: _supervisors.map((user) {
                                  return DropdownMenuItem<User>(
                                    value: user,
                                    child: Text(
                                      '${user.firstName} ${user.lastName}',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      _supervisor = value;
                                    });
                                  }
                                },
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                            if (_type == 'Sick Leave' || _type == 'Maternity Leave') ...[
                              const SizedBox(height: 16),
                              _buildCard(
                                isValid: _certifFile != null,
                                child: ListTile(
                                  leading: const Icon(Icons.upload_file, color: Color(0xFF0632A1)),
                                  title: const Text(
                                    'Upload Certificate (Required)',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  subtitle: Text(
                                    _certifFile != null ? _certifFile!.path.split('/').last : 'No file selected',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.attach_file, color: Color(0xFF0632A1)),
                                    onPressed: _pickCertifFile,
                                  ),
                                ),
                              ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                            ],
                          ],

                          // Step 1: Dates and Note
                          if (_currentStep == 1) ...[
                            if (_type == '1/2 Day') ...[
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Half Day Leave Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    InkWell(
                                      onTap: () => _selectDate(isStartDate: true),
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Date',
                                          labelStyle: TextStyle(color: Colors.grey),
                                          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0632A1)),
                                          border: InputBorder.none,
                                        ),
                                        child: Text(
                                          _startDate == null
                                              ? 'Select Date'
                                              : _startDate!.toLocal().toString().split(' ')[0],
                                          style: const TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 32),
                                    InkWell(
                                      onTap: _selectHalfDayTime,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Time (AM/PM)',
                                          labelStyle: TextStyle(color: Colors.grey),
                                          prefixIcon: Icon(Icons.access_time, color: Color(0xFF0632A1)),
                                          border: InputBorder.none,
                                        ),
                                        child: Text(
                                          _halfDayTime == null
                                              ? 'Select Time (AM/PM)'
                                              : _halfDayTime!.format(context),
                                          style: const TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCard(
                                      isValid: _startDate != null,
                                      child: InkWell(
                                        onTap: () => _selectDate(isStartDate: true),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Start Date',
                                            labelStyle: TextStyle(color: Colors.grey),
                                            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0632A1)),
                                            border: InputBorder.none,
                                          ),
                                          child: Text(
                                            _startDate == null
                                                ? 'Select Start Date'
                                                : _startDate!.toLocal().toString().split(' ')[0],
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildCard(
                                      isValid: _endDate != null,
                                      child: InkWell(
                                        onTap: () => _selectDate(isStartDate: false),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'End Date',
                                            labelStyle: TextStyle(color: Colors.grey),
                                            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF0632A1)),
                                            border: InputBorder.none,
                                          ),
                                          child: Text(
                                            _endDate == null
                                                ? 'Select End Date'
                                                : _endDate!.toLocal().toString().split(' ')[0],
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            _buildCard(
                              child: TextFormField(
                                controller: _noteController,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  labelText: 'Note (Optional)',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.note, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                                maxLines: 3,
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                          ],

                          // Navigation Buttons
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_currentStep > 0)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => setState(() => _currentStep--),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0632A1),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                        'Back',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                if (_currentStep > 0) const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isNextEnabled
                                        ? () {
                                            if (_currentStep < 1) {
                                              setState(() => _currentStep++);
                                            } else {
                                              _submitRequest();
                                            }
                                          }
                                        : () {
                                            _showValidationError();
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isNextEnabled
                                          ? const Color(0xFF0632A1)
                                          : Colors.grey[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: isNextEnabled ? 2 : 0,
                                    ),
                                    child: Text(
                                      _currentStep == 1 ? 'Submit Request' : 'Next',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard({required Widget child, bool isValid = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: !isValid
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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