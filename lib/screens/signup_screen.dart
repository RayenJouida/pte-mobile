import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
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
  bool _isPasswordVisible = false;
  double _experienceYears = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

    setState(() {
      _isLoading = true;
    });

    try {
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
        _showSuccessPopup(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup Failed!'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showWelcomePopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Welcome to Registration!',
          style: TextStyle(
            fontSize: 20,
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
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              'To ensure a smooth registration process, please follow these guidelines:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGuidelineItem('1', 'Fill out all fields in each step.'),
                  _buildGuidelineItem('2', 'Ensure your email is valid (e.g., name@gmail.com).'),
                  _buildGuidelineItem('3', 'Use a strong password (at least 8 characters with letters and numbers).'),
                  _buildGuidelineItem('4', 'Add a profile picture in the final step.'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF0632A1),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Got it!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(0xFF0632A1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Sign Up Request Sent!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0632A1),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Your sign-up request has been sent successfully. You will receive an email once it is approved.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Redirect to login screen after 2.5 seconds (reduced from 3)
    Future.delayed(Duration(milliseconds: 2500), () {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void _generateMatricule() {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      final randomNumber = Random().nextInt(99) + 1;
      matriculeController.text = '$firstName$lastName$randomNumber';
    } else {
      matriculeController.text = '';
    }
    setState(() {});
  }

  Widget _buildMatriculeField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Color(0xFF0632A1).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.badge, color: Color(0xFF0632A1), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  matriculeController.text.isEmpty
                      ? "Matricule will be generated automatically"
                      : matriculeController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
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
        title: Icon(Icons.person, color: Color(0xFF0632A1)),
        content: Column(children: [
          _buildTextField(
            firstNameController,
            "First Name",
            Icons.person,
            onChanged: (value) {
              _generateMatricule();
            },
          ),
          _buildTextField(
            lastNameController,
            "Last Name",
            Icons.person_outline,
            onChanged: (value) {
              _generateMatricule();
            },
          ),
          _buildMatriculeField(),
        ]),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Icon(Icons.description, color: Color(0xFF0632A1)),
        content: Column(children: [
          _buildTextField(emailController, "Email", Icons.email, 
            placeholder: "name@gmail.com",
            isEmail: true),
          _buildTextField(passwordController, "Password", Icons.lock, 
            placeholder: "Min. 8 characters with letters & numbers",
            isPassword: true),
          // Refined Experience Slider
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Experience",
                      style: TextStyle(
                        color: Colors.grey.shade700, 
                        fontSize: 14, 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF0632A1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_experienceYears.toStringAsFixed(1)} years",
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF0632A1).withOpacity(0.3), width: 1),
                  ),
                  child: Slider(
                    value: _experienceYears,
                    min: 0,
                    max: 15,
                    divisions: 30, // More granular divisions
                    activeColor: Color(0xFF0632A1),
                    inactiveColor: Color(0xFF0632A1).withOpacity(0.2),
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
        title: Icon(Icons.account_circle, color: Color(0xFF0632A1)),
        content: Column(children: [
          // Refined Team Leader Switch
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF0632A1).withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, color: Color(0xFF0632A1), size: 20),
                    SizedBox(width: 12),
                    Text(
                      "Team Leader",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isTeamLeader,
                  onChanged: (bool value) => setState(() => _isTeamLeader = value),
                  activeColor: Color(0xFF0632A1),
                  activeTrackColor: Color(0xFF0632A1).withOpacity(0.4),
                ),
              ],
            ),
          ),
          // Refined Profile Picture Selector
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF0632A1).withOpacity(0.3), width: 1),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? Icon(Icons.person, size: 40, color: Colors.grey.shade500)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color(0xFF0632A1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Tap to add a profile picture",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
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
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(color: Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          prefixIcon: Icon(icon, color: Color(0xFF0632A1), size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Color(0xFF0632A1),
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF0632A1).withOpacity(0.3), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF0632A1).withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF0632A1), width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (isEmail && !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
            return 'Enter a valid email (e.g., name@gmail.com)';
          }
          if (isPassword && (value.length < 8 || !RegExp(r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$").hasMatch(value))) {
            return 'Password must be at least 8 characters with letters and numbers';
          }
          return null;
        },
        onChanged: onChanged,
        enabled: enabled,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF0632A1)),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
        title: Text(
          "Create Account",
          style: TextStyle(
            color: Color(0xFF0632A1),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Illustration Image with reduced size
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Image.asset(
                  'assets/illustrations/register.jpg',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              // Main Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Step Indicator
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              width: 80,
                              height: 4,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _currentStep >= index 
                                    ? Color(0xFF0632A1) 
                                    : Color(0xFF0632A1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      // Step Title
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: Text(
                          _currentStep == 0 
                              ? "Personal Information" 
                              : _currentStep == 1 
                                  ? "Account Details" 
                                  : "Profile Setup",
                          style: TextStyle(
                            color: Color(0xFF0632A1),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      // Step Content
                      _buildSteps()[_currentStep].content,
                      SizedBox(height: 24),
                      
                      // Navigation Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Button
                          _currentStep > 0
                              ? ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => _currentStep--);
                                  },
                                  icon: Icon(Icons.arrow_back, size: 16),
                                  label: Text("Back"),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Color(0xFF0632A1),
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Color(0xFF0632A1), width: 1),
                                    ),
                                    elevation: 0,
                                  ),
                                )
                              : SizedBox(width: 100), // Empty space if on first step
                          
                          // Next/Submit Button
                          ElevatedButton.icon(
                            onPressed: _isStepValid(_currentStep) && !_isLoading
                                ? () {
                                    if (_currentStep < _buildSteps().length - 1) {
                                      setState(() => _currentStep++);
                                    } else {
                                      _submitSignup();
                                    }
                                  }
                                : null,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _currentStep < _buildSteps().length - 1
                                        ? Icons.arrow_forward
                                        : Icons.check,
                                    size: 16,
                                  ),
                            label: Text(
                              _isLoading
                                  ? "Processing..."
                                  : _currentStep < _buildSteps().length - 1
                                      ? "Next"
                                      : "Submit",
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: _isStepValid(_currentStep)
                                  ? Color(0xFF0632A1)
                                  : Color(0xFF0632A1).withOpacity(0.3),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                              shadowColor: Color(0xFF0632A1).withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      
                      // Login Link
                      Padding(
                        padding: EdgeInsets.only(top: 30, bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Color(0xFF0632A1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    matriculeController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    nationalityController.dispose();
    fsController.dispose();
    bioController.dispose();
    addressController.dispose();
    departmentController.dispose();
    super.dispose();
  }
}