import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math'; // For Random number generation
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController matriculeController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();
  final TextEditingController fsController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  bool _isTeamLeader = false;
  bool _isPasswordVisible = false; // For password visibility toggle
  double _experienceYears = 0; // Slider value for experience

  @override
  void initState() {
    super.initState();
    // Show the pop-up when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomePopup(context);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    bool success = await AuthService().signUp(
      matricule: matriculeController.text,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      email: emailController.text,
      password: passwordController.text,
      experience: _experienceYears.toString(),
      phone: phoneController.text,
      nationality: nationalityController.text,
      fs: fsController.text,
      bio: bioController.text,
      address: addressController.text,
      department: departmentController.text,
      teamLeader: _isTeamLeader,
      imagePath: _imageFile?.path,
    );

    if (success) {
      _showSuccessPopup(context); // Show success pop-up
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Failed!')),
      );
    }
  }

  void _showWelcomePopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Welcome to Registration!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0632A1),
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              color: Color(0xFF0632A1),
              size: 50,
            ),
            SizedBox(height: 16),
            Text(
              'To ensure a smooth registration process, please follow these guidelines:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              '1. Fill out all fields in each step.\n'
              '2. Ensure your email is valid (e.g., name@gmail.com).\n'
              '3. Use a strong password (at least 8 characters, including letters and numbers).\n'
              '4. Add a profile picture in the final step.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the pop-up
            },
            child: Text(
              'Got it!',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF0632A1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Sign Up Request Sent!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0632A1),
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 50,
            ),
            SizedBox(height: 16),
            Text(
              'Your sign-up request has been sent successfully. You will receive an email once it is approved.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Redirect to login screen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pop(context); // Close the pop-up
      Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
    });
  }

  void _generateMatricule() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      final randomNumber = Random().nextInt(99) + 1; // Random number between 1 and 99
      matriculeController.text = '$firstName$lastName$randomNumber';
    } else {
      matriculeController.text = ''; // Clear if first name or last name is empty
    }
    setState(() {}); // Rebuild to update button state
  }

  Widget _buildMatriculeField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Light grey background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF0632A1), // Dark blue border
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.badge, color: Color(0xFF0632A1)), // Matricule icon
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  matriculeController.text.isEmpty
                      ? "Matricule will be generated automatically"
                      : matriculeController.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: Icon(Icons.person, color: Color(0xFF0632A1)), // Icon for "Infos"
        content: Column(children: [
          _buildTextField(
            firstNameController,
            "First Name",
            Icons.person,
            onChanged: (value) {
              _generateMatricule(); // Generate matricule on first name change
            },
          ),
          _buildTextField(
            lastNameController,
            "Last Name",
            Icons.person_outline,
            onChanged: (value) {
              _generateMatricule(); // Generate matricule on last name change
            },
          ),
          _buildMatriculeField(), // Custom matricule field
        ]),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Icon(Icons.description, color: Color(0xFF0632A1)), // Icon for "Details"
        content: Column(children: [
          _buildTextField(emailController, "Email example : name@gmail.com", Icons.email, isEmail: true),
          _buildTextField(passwordController, "Password example : Password123", Icons.lock, isPassword: true),
          // Beautiful Experience Slider
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Experience (years): ${_experienceYears.toStringAsFixed(1)}",
                  style: TextStyle(color: Color(0xFF0632A1), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF0632A1).withOpacity(0.3), width: 1.5),
                  ),
                  child: Slider(
                    value: _experienceYears,
                    min: 0,
                    max: 15, // Max set to 15
                    divisions: 15,
                    label: _experienceYears.toStringAsFixed(1),
                    activeColor: Color(0xFF0632A1),
                    inactiveColor: Color(0xFF0632A1).withOpacity(0.3),
                    onChanged: (value) {
                      setState(() {
                        _experienceYears = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ]),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Icon(Icons.account_circle, color: Color(0xFF0632A1)), // Icon for "Profile"
        content: Column(children: [
          SwitchListTile(
            title: Text("Team Leader", style: TextStyle(color: Color(0xFF0632A1), fontSize: 16)),
            value: _isTeamLeader,
            onChanged: (bool value) => setState(() => _isTeamLeader = value),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60, // Larger profile picture
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null
                  ? Icon(Icons.camera_alt, size: 50, color: Colors.grey.shade800) // Larger icon
                  : null,
            ),
          ),
          SizedBox(height: 10),
          Text("Tap to add a profile picture", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        ]),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool isEmail = false,
    String placeholder = "",
    Function(String)? onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0), // Increased padding
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible, // Toggle password visibility
        style: TextStyle(color: Colors.black, fontSize: 16), // Larger text
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder, // Add placeholder
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 16), // Larger label
          prefixIcon: Icon(icon, color: Color(0xFF0632A1)), // Dark blue icon
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Color(0xFF0632A1)),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white, // White background for input fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), // Reduced border radius
            borderSide: BorderSide(color: Color(0xFF0632A1)), // Dark blue border
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (isEmail && !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
            return 'Enter a valid email (e.g., name@gmail.com)';
          }
          if (isPassword && (value.length < 8 || !RegExp(r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$").hasMatch(value))) {
            return 'Password must be at least 8 characters and include letters and numbers';
          }
          return null;
        },
        onChanged: onChanged, // Pass the onChanged callback
        enabled: enabled, // Enable/disable the field
      ),
    );
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return matriculeController.text.isNotEmpty &&
            firstNameController.text.isNotEmpty &&
            lastNameController.text.isNotEmpty;
      case 1:
        return emailController.text.isNotEmpty &&
            passwordController.text.isNotEmpty &&
            _formKey.currentState!.validate();
      case 2:
        return true; // No validation for the image step
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for a clean look
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Illustration Image (register.jpg)
            Padding(
              padding: const EdgeInsets.only(top: 80), // Reduced top padding
              child: Image.asset(
                'assets/illustrations/register.jpg',
                height: 230, // Increased image height
                fit: BoxFit.cover,
              ),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Page Title
                    Text(
                      "Please fill in the form",
                      style: TextStyle(
                        color: Color(0xFF0632A1),
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 42), // Reduced space between image and title
                    // Horizontal Stepper with Icons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1), // Shift stepper to the left
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start, // Align to the start (left)
                          children: _buildSteps().asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value;
                            final icon = step.title as Icon; // Extract the icon from the step title

                            return GestureDetector(
                              onTap: () {
                                if (_currentStep != index) {
                                  setState(() {
                                    _currentStep = index;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12), // Wider padding
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _currentStep == index ? Color(0xFF0632A1) : Colors.white,
                                  borderRadius: BorderRadius.circular(8), // Reduced border radius
                                  border: Border.all(
                                    color: _currentStep == index ? Color(0xFF0632A1) : Color(0xFF0632A1).withOpacity(0.3), // Neumorphism blue border
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon.icon, // Use the icon from the step
                                  color: _currentStep == index ? Colors.white : Color(0xFF0632A1),
                                  size: 24, // Adjust icon size
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Step Content
                    _buildSteps()[_currentStep].content,
                    SizedBox(height: 20),
                    // Navigation Buttons with Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentStep != 0)
                          Container(
                            width: 120, // Wider back button
                            child: IconButton(
                              onPressed: () {
                                setState(() => _currentStep--);
                              },
                              icon: Icon(Icons.arrow_back, size: 32, color: Color(0xFF0632A1)),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Color(0xFF0632A1), width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(width: 20),
                        Container(
                          width: 120, // Wider next button
                          child: IconButton(
                            onPressed: _isStepValid(_currentStep)
                                ? () {
                                    if (_currentStep < _buildSteps().length - 1) {
                                      setState(() => _currentStep++);
                                    } else {
                                      _submitSignup();
                                    }
                                  }
                                : null, // Disable if step is not valid
                            icon: Icon(
                              Icons.arrow_forward,
                              size: 32,
                              color: _isStepValid(_currentStep) ? Colors.white : Colors.white.withOpacity(0.5), // Semi-transparent icon when disabled
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _isStepValid(_currentStep)
                                  ? Color(0xFF0632A1) // Primary color when enabled
                                  : Color(0xFF0632A1).withOpacity(0.3), // Semi-transparent primary color when disabled
                              padding: EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _isStepValid(_currentStep)
                                      ? Color(0xFF0632A1) // Primary color border when enabled
                                      : Color(0xFF0632A1).withOpacity(0.3), // Semi-transparent border when disabled
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // "Already have an account? Login" link
                    Padding(
                      padding: EdgeInsets.only(top: 40, bottom: 20), // Moved further down
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login'); // Adjust to your route
                        },
                        child: Text(
                          "Already have an account? Login",
                          style: TextStyle(color: Color(0xFF0632A1), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}