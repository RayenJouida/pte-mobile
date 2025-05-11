import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/leave_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({Key? key}) : super(key: key);

  @override
  _LeaveRequestScreenState createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeaveService _leaveService = LeaveService();
  final UserService _userService = UserService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _applicantId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _type;
  User? _supervisor;
  List<User> _supervisors = [];
  int _currentStep = 0;
  bool _isLoading = false;

  final List<String> _leaveTypes = [
    'Unpaid Leave',
    'Maternity Leave',
    'Annual Leave',
    'Sick Leave',
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
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
    setState(() {
      _applicantId = userId;
    });
    _loadUserProfile();
    _fetchSupervisors();
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    print('Loading user data from SharedPreferences:');
    print('userId: ${prefs.getString('userId')}');
    print('userName: ${prefs.getString('userName')}');
    print('email: ${prefs.getString('email')}');

    setState(() {
      _fullNameController.text = prefs.getString('userName') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
    });
  }

  Future<void> _fetchSupervisors() async {
    try {
      final users = await _userService.fetchUsers();
      setState(() {
        _supervisors = users
            .map((user) => User.fromJson(user))
            .where((user) => user.roles.contains('ADMIN') || user.roles.contains('LAB-MANAGER'))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load supervisors: $e')),
      );
    }
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
        } else {
          if (selectedDate.isAfter(_startDate ?? DateTime.now())) {
            _endDate = selectedDate;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End date must be after start date')),
            );
          }
        }
      });
    }
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _fullNameController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text);
      case 1:
        return _type != null && _supervisor != null;
      case 2:
        return _startDate != null && _endDate != null;
      default:
        return false;
    }
  }

  void _showValidationError() {
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

Future<void> _submitRequest() async {
  if (!_isStepValid(2)) {
    _showValidationError();
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  if (token == null) {
    print('No token found, redirecting to login');
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  setState(() {
    _isLoading = true;
  });

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
          fullName: _fullNameController.text,
          email: _emailController.text,
          startDate: _startDate!,
          endDate: _endDate!,
          type: _type!,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          applicantId: _applicantId!,
          supervisorId: _supervisor!.id,
        );

        // Check if leave object is valid before showing success
        if (leave != null && leave.id != null) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Success!',
            text: "Your leave request has been submitted. You'll be notified once it's processed.",
            confirmBtnColor: const Color(0xFF0632A1),
            onConfirmBtnTap: () {
              Navigator.pop(context);
              _formKey.currentState?.reset();
              setState(() {
                _startDate = null;
                _endDate = null;
                _type = null;
                _supervisor = null;
                _noteController.clear();
                _currentStep = 0;
              });
              Navigator.pop(context, 6); // Return to sidebar with currentIndex 6
            },
          );
        } else {
          throw Exception('Received invalid leave request response');
        }
      } catch (e) {
        print('Error submitting leave request: $e');
        // Check if the error is specifically about invalid user data
        final errorMessage = e.toString().contains('Invalid User data') 
            ? 'Leave request submitted but there was an issue with user data validation'
            : 'Failed to submit request: $e';
        
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: e.toString().contains('Invalid User data') ? 'Warning' : 'Error',
          text: errorMessage,
          confirmBtnColor: const Color(0xFF0632A1),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final bool isNextEnabled = _isStepValid(_currentStep);

    return Scaffold(
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
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => Navigator.pop(context),
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
                            children: List.generate(3, (index) {
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

                          // Step 0: Personal Info
                          if (_currentStep == 0) ...[
                            _buildCard(
                              isValid: _fullNameController.text.isNotEmpty,
                              child: TextFormField(
                                controller: _fullNameController,
                                enabled: false,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.person, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                            const SizedBox(height: 16),
                            _buildCard(
                              isValid: _emailController.text.isNotEmpty &&
                                  RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text),
                              child: TextFormField(
                                controller: _emailController,
                                enabled: false,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.email, color: Color(0xFF0632A1)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                          ],

                          // Step 1: Leave Details
                          if (_currentStep == 1) ...[
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
                                  setState(() {
                                    _type = value;
                                  });
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
                                  setState(() {
                                    _supervisor = value;
                                  });
                                },
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                          ],

                          // Step 2: Dates and Note
                          if (_currentStep == 2) ...[
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
                                            if (_currentStep < 2) {
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
                                      _currentStep == 2 ? 'Submit Request' : 'Next',
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