import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/screens/labmanager/requests_by_user_id.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickalert/quickalert.dart';
import '../../services/virtualization_env_service.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import '../../theme/theme.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';

class RequestLabScreen extends StatefulWidget {
  const RequestLabScreen({Key? key}) : super(key: key);

  @override
  State<RequestLabScreen> createState() => _RequestLabScreenState();
}

class _RequestLabScreenState extends State<RequestLabScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _departementController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _processorController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  bool _backup = false;
  bool _dhcp = false;
  DateTime? _startDate;
  DateTime? _endDate;
  double _ramValue = 1;
  double _diskValue = 1;
  int _currentStep = 0;
  String? _selectedLabType;
  double _processorCores = 1;
  final UserService _userService = UserService();
  User? currentUser;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
    _loadUserProfile();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Unknown Role';
    });
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    print('Loading user data from SharedPreferences:');
    print('userId: ${prefs.getString('userId')}');
    print('firstName: ${prefs.getString('firstName')}');
    print('lastName: ${prefs.getString('lastName')}');
    print('email: ${prefs.getString('email')}');
    print('userName: ${prefs.getString('userName')}');
    print('departement: ${prefs.getString('departement')}');

    if (userId != null) {
      try {
        final userData = await _userService.getUserById(userId);
        setState(() {
          currentUser = User.fromJson(userData);
          _firstNameController.text = currentUser?.firstName ?? prefs.getString('firstName') ?? '';
          _lastNameController.text = currentUser?.lastName ?? prefs.getString('lastName') ?? '';
          _emailController.text = currentUser?.email ?? prefs.getString('email') ?? '';
          _departementController.text = currentUser?.departement ?? prefs.getString('departement') ?? '';
        });
      } catch (e) {
        print('Error loading user profile: $e');
        setState(() {
          _firstNameController.text = prefs.getString('firstName') ?? '';
          _lastNameController.text = prefs.getString('lastName') ?? '';
          _emailController.text = prefs.getString('email') ?? '';
          _departementController.text = prefs.getString('departement') ?? '';
        });
      }
    }
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0632A1),
            ),
          ),
          child: child!,
        );
      },
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
        return _selectedLabType != null &&
            _ramValue >= 1 &&
            _diskValue >= 1 &&
            _processorCores >= 1;
      case 1:
        return _startDate != null &&
            _endDate != null &&
            _goalsController.text.isNotEmpty;
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_isStepValid(1)) {
      _showValidationError();
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? email = prefs.getString('email') ?? 'meher@gmail.com';

    _typeController.text = _selectedLabType ?? '';

    try {
      final Map<String, dynamic> requestData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': email,
        'departement': currentUser?.departement ?? _departementController.text,
        'type': _typeController.text,
        'backup': _backup,
        'ram': _ramValue.toInt().toString(),
        'disk': _diskValue.toInt().toString(),
        'processor': _processorCores.toInt().toString(),
        'dhcp': _dhcp,
        'start': _startDate?.toIso8601String(),
        'end': _endDate?.toIso8601String(),
        'goals': _goalsController.text,
        'applicant': userId,
      };

      print('===== SUBMITTING REQUEST =====');
      print('User ID: $userId');
      print('Email: $email');
      print('Request data: ${jsonEncode(requestData)}');

      final response = await VirtualizationEnvService().addVirtualizationEnv(requestData);
      print('Response received: ${jsonEncode(response.toJson())}');

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success!',
        text: "Your request has been submitted. You'll be emailed once it's treated.",
        confirmBtnColor: const Color(0xFF0632A1),
        onConfirmBtnTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RequestsByUserId()),
          );
        },
      );
    } catch (e) {
      print('===== ERROR IN SUBMIT REQUEST =====');
      print('Full error: $e');

      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to submit request: $e',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNextEnabled = _isStepValid(_currentStep);

    // Determine the correct index based on the role
    int currentIndex = 0; // Default index
    switch (_currentUserRole) {
      case 'ADMIN':
        currentIndex = 10; // Request Lab
        break;
      case 'ENGINEER':
        currentIndex = 4; // Request Lab
        break;
      case 'LAB-MANAGER':
        currentIndex = 5; // Request Lab
        break;
      case 'ASSISTANT':
        currentIndex = 10; // Request Lab
        break;
      default:
        currentIndex = 0; // Fallback to a safe index
    }

    return Scaffold(
      drawer: _currentUserRole == 'ADMIN'
          ? AdminSidebar(
              currentIndex: currentIndex,
              onTabChange: (index) {
                setState(() {});
              },
            )
          : _currentUserRole == 'LAB-MANAGER'
              ? LabManagerSidebar(
                  currentIndex: currentIndex,
                  onTabChange: (index) {
                    setState(() {});
                  },
                )
              : _currentUserRole == 'ENGINEER'
                  ? EngineerSidebar(
                      currentIndex: currentIndex,
                      onTabChange: (index) {
                        setState(() {});
                      },
                    )
                  : AssistantSidebar(
                      currentIndex: currentIndex,
                      onTabChange: (index) {
                        setState(() {});
                      },
                    ),
      body: Column(
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
                    'Request a Lab',
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

                    // Step 0: Lab Details
                    if (_currentStep == 0) ...[
                      _buildCard(
                        isValid: _selectedLabType != null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lab Type',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            RadioListTile<String>(
                              value: 'Hyper-V',
                              groupValue: _selectedLabType,
                              onChanged: (value) => setState(() => _selectedLabType = value),
                              title: const Text(
                                'Hyper-V',
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                              activeColor: const Color(0xFF0632A1),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            RadioListTile<String>(
                              value: 'VMWare',
                              groupValue: _selectedLabType,
                              onChanged: (value) => setState(() => _selectedLabType = value),
                              title: const Text(
                                'VMWare',
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                              activeColor: const Color(0xFF0632A1),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                      const SizedBox(height: 16),
                      _buildCard(
                        isValid: _ramValue >= 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RAM: ${_ramValue.toInt()} GB',
                              style: const TextStyle(color: Colors.black),
                            ),
                            Slider(
                              value: _ramValue,
                              min: 1,
                              max: 64,
                              divisions: 63,
                              label: _ramValue.toInt().toString(),
                              onChanged: (value) => setState(() => _ramValue = value),
                              activeColor: const Color(0xFF0632A1),
                              inactiveColor: Colors.grey.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                      const SizedBox(height: 16),
                      _buildCard(
                        isValid: _diskValue >= 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Disk Space: ${_diskValue.toInt()} GB',
                              style: const TextStyle(color: Colors.black),
                            ),
                            Slider(
                              value: _diskValue,
                              min: 1,
                              max: 1024,
                              divisions: 1023,
                              label: _diskValue.toInt().toString(),
                              onChanged: (value) => setState(() => _diskValue = value),
                              activeColor: const Color(0xFF0632A1),
                              inactiveColor: Colors.grey.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                      const SizedBox(height: 16),
                      _buildCard(
                        isValid: _processorCores >= 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Processor Cores: ${_processorCores.toInt()}',
                              style: const TextStyle(color: Colors.black),
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbColor: const Color(0xFF0632A1),
                                activeTrackColor: const Color(0xFF0632A1),
                                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                                overlayColor: const Color(0xFF0632A1).withOpacity(0.2),
                                tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
                                activeTickMarkColor: const Color(0xFF0632A1),
                                inactiveTickMarkColor: Colors.grey.withOpacity(0.5),
                              ),
                              child: Slider(
                                value: _processorCores,
                                min: 1,
                                max: 32,
                                divisions: 31,
                                label: _processorCores.toInt().toString(),
                                onChanged: (value) => setState(() => _processorCores = value.roundToDouble()),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '8',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '16',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '32',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                    ],

                    // Step 1: Additional Info
                    if (_currentStep == 1) ...[
                      _buildCard(
                        child: SwitchListTile(
                          title: const Text('Backup Required', style: TextStyle(color: Colors.black)),
                          value: _backup,
                          onChanged: (value) => setState(() => _backup = value),
                          activeColor: const Color(0xFF0632A1),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                      const SizedBox(height: 16),
                      _buildCard(
                        child: SwitchListTile(
                          title: const Text('DHCP Enabled', style: TextStyle(color: Colors.black)),
                          value: _dhcp,
                          onChanged: (value) => setState(() => _dhcp = value),
                          activeColor: const Color(0xFF0632A1),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                      const SizedBox(height: 16),
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
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
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
                            ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        isValid: _goalsController.text.isNotEmpty,
                        child: TextFormField(
                          controller: _goalsController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Goals',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.flag, color: Color(0xFF0632A1)),
                            border: InputBorder.none,
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideY(delay: 700.ms),
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
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0632A1),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFF0632A1)),
                                  ),
                                  elevation: 0,
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
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 800.ms),
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