import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/signup_screen.dart';
import 'package:rflutter_alert/rflutter_alert.dart'; // Import rflutter_alert
import 'profile_screen.dart'; // Import the ProfileScreen
import '../services/auth_service.dart'; // Import the AuthService
import 'forgot_password_screen.dart'; // Import the ForgotPasswordScreen
import 'package:pte_mobile/screens/feed/feed_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Track password visibility

  // Custom Alert Style
  final AlertStyle _alertStyle = AlertStyle(
    animationType: AnimationType.grow,
    isCloseButton: false,
    isOverlayTapDismiss: false,
    descStyle: TextStyle(fontSize: 16, color: Colors.black87),
    titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    backgroundColor: Colors.white,
    animationDuration: Duration(milliseconds: 400),
    alertBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.grey.shade300),
    ),
  );

Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final user = await _authService.login(email, password);
      print('User roles: ${user?.roles}');

      if (user != null) {
        // Show success dialog
        _showSuccessDialog(context, user);
      }
    } catch (e) {
      print('Exception: $e');
      // Handle account not yet confirmed
      if (e.toString().contains('Account not yet confirmed')) {
        Alert(
          context: context,
          style: _alertStyle,
          type: AlertType.info,
          title: "Account Not Confirmed",
          desc: "Your account is not yet confirmed. Please wait for email verification.",
          buttons: [
            DialogButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF0632A1), Color(0xFF3D6DFF)],
              ),
              onPressed: () => Navigator.pop(context), // Close the alert
            ),
          ],
        ).show();
      }
      // Handle invalid credentials
      else if (e.toString().contains('Invalid credentials')) {
        Alert(
          context: context,
          style: _alertStyle,
          type: AlertType.error,
          title: "Invalid Credentials",
          desc: "Please check your email and password.",
          buttons: [
            DialogButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
              ),
              onPressed: () => Navigator.pop(context), // Close the alert
            ),
          ],
        ).show();
      }
      // Handle other errors
      else {
        Alert(
          context: context,
          style: _alertStyle,
          type: AlertType.error,
          title: "Error!",
          desc: "Login failed. Please try again.",
          buttons: [
            DialogButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
              ),
              onPressed: () => Navigator.pop(context), // Close the alert
            ),
          ],
        ).show();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _showSuccessDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Automatically navigate after 2 seconds
Future.delayed(Duration(seconds: 2), () {
  Navigator.pop(context); // Close the dialog
  if (user.roles.contains("ADMIN")) {
    Navigator.pushReplacementNamed(context, '/admin');
  } else if (user.roles.contains("ASSISTANT")) {
    Navigator.pushReplacementNamed(context, '/settings');
  } else if (user.roles.contains("LAB-MANAGER")) {
    Navigator.pushReplacementNamed(context, '/feed'); // Redirect to HomeLabScreen
  } else {
    Navigator.pushReplacementNamed(
      context,
      '/profile',
      arguments: user.firstName,
    );
  }
});
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white, // White background for a clean look
    body: Stack(
      children: [
        // Main Content
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Use a Stack to overlap the Prologic image over the login.jpg illustration
                  Stack(
                    alignment: Alignment.center, // Center the overlapping image
                    children: [
                      // Illustration Image (login.jpg)
                      Image.asset(
                        'assets/illustrations/login.jpg',
                        height: 280,
                      ).animate().fade(duration: 500.ms),

                      // Prologic Logo (overlapping the illustration)
                      Positioned(
                        top: 228, // Adjust this value to control the overlap
                        child: Image.asset(
                          'assets/images/prologic.png',
                          height: 70,
                        ).animate().fade(duration: 600.ms),
                      ),
                    ],
                  ),
                  SizedBox(height: 60), // Increased space between logo and form

                  // Form without card wrapping
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Color(0xFF0632A1)),
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Color(0xFF0632A1)),
                            filled: true,
                            fillColor: Colors.white, // White background for input fields
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF0632A1), width: 2), // Refined border
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: TextStyle(color: Color(0xFF0632A1)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ).animate().fade(duration: 500.ms),
                        SizedBox(height: 30), // Increased space between email and password fields

                        // Password Field with Visibility Toggle
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF0632A1)),
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Color(0xFF0632A1)),
                            filled: true,
                            fillColor: Colors.white, // White background for input fields
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF0632A1), width: 2), // Refined border
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF0632A1),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: TextStyle(color: Color(0xFF0632A1)),
                          obscureText: !_isPasswordVisible, // Toggle obscureText based on visibility
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ).animate().fade(duration: 600.ms),
                        SizedBox(height: 50), // Increased space between fields and login button

                        // Login and Forgot Password in the same row
                        Row(
                          children: [
                            // Login Button (wider and bigger text)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _login, // Disable button when loading
                                icon: FaIcon(FontAwesomeIcons.signInAlt, size: 18, color: Colors.white),
                                label: Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18), // Bigger text
                                ),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Color(0xFF0632A1),
                                  padding: EdgeInsets.symmetric(vertical: 18), // Increased padding
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // Reduced border radius
                                  ),
                                  disabledBackgroundColor: Color(0xFF0632A1).withOpacity(0.5), // Greyed-out when disabled
                                ),
                              ),
                            ),
                            SizedBox(width: 10),

                            // Forgot Password Button
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: Color(0xFF0632A1)),
                              ),
                            ).animate().fade(duration: 800.ms),
                          ],
                        ),
                        SizedBox(height: 40), // Increased space between login button and separator

                        // Thin Line Separator (moved further down)
                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                        SizedBox(height: 20), // Reduced space between separator and text

                        // Register Section (moved closer to the button)
                        Column(
                          children: [
                            Text(
                              "If you're not already a member?",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            SizedBox(height: 40), // Reduced space between text and button
                            // Register Button with Solid Color
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupScreen(), // Navigate to SignupScreen
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFF0632A1), // Match Login button color
                                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5, // Add subtle elevation for consistency
                              ),
                              child: Text(
                                'Register',
                                style: TextStyle(fontSize: 16),
                              ),
                            ).animate().fade(duration: 900.ms),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}