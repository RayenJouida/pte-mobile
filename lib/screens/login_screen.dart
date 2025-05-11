import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/signup_screen.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
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
  bool _isPasswordVisible = false;

  // Refined alert style with softer colors and smaller size
  final AlertStyle _alertStyle = AlertStyle(
    animationType: AnimationType.fromTop,
    isCloseButton: false,
    isOverlayTapDismiss: false,
    descStyle: TextStyle(fontSize: 14, color: Colors.black87),
    titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    backgroundColor: Colors.white,
    animationDuration: Duration(milliseconds: 300),
    alertBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    alertPadding: EdgeInsets.all(20),
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
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFF0632A1), Color(0xFF3D6DFF)],
                ),
                onPressed: () => Navigator.pop(context),
                width: 120,
                radius: BorderRadius.circular(10),
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
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
                ),
                onPressed: () => Navigator.pop(context),
                width: 120,
                radius: BorderRadius.circular(10),
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
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
                ),
                onPressed: () => Navigator.pop(context),
                width: 120,
                radius: BorderRadius.circular(10),
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 50,
            ),
            SizedBox(height: 12),
            Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Automatically navigate after 1.5 seconds (reduced from 2)
    Future.delayed(Duration(milliseconds: 1500), () {
      Navigator.pop(context); // Close the dialog
      if (user.roles.contains("ADMIN") || 
          user.roles.contains("ASSISTANT") || 
          user.roles.contains("LAB-MANAGER")) {
        Navigator.pushReplacementNamed(context, '/feed');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Optimized image stack with reduced height
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Illustration Image (reduced height)
                      Image.asset(
                        'assets/illustrations/login.jpg',
                        height: 220, // Reduced from 280
                      ).animate().fade(duration: 400.ms),

                      // Prologic Logo (adjusted position)
                      Positioned(
                        top: 180, // Adjusted for new illustration height
                        child: Image.asset(
                          'assets/images/prologic.png',
                          height: 60, // Slightly reduced
                        ).animate().fade(duration: 500.ms),
                      ),
                    ],
                  ),
                  SizedBox(height: 40), // Reduced from 60

                  // Form with improved spacing and styling
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field with refined styling
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Color(0xFF0632A1), size: 20),
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Color(0xFF0632A1), fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF0632A1).withOpacity(0.5), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF0632A1).withOpacity(0.3), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF0632A1), width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          ),
                          style: TextStyle(color: Color(0xFF0632A1), fontSize: 14),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ).animate().fade(duration: 400.ms),
                        SizedBox(height: 20), // Reduced from 30

                        // Password Field with refined styling
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF0632A1), size: 20),
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Color(0xFF0632A1), fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF0632A1).withOpacity(0.5), width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF0632A1).withOpacity(0.3), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF0632A1), width: 1.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF0632A1),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          ),
                          style: TextStyle(color: Color(0xFF0632A1), fontSize: 14),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ).animate().fade(duration: 500.ms),
                        SizedBox(height: 30), // Reduced from 50

                        // Forgot Password link moved above login button for better UX
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF0632A1),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Login Button (full width, cleaner design)
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 16, 
                                  height: 16, 
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                )
                              : FaIcon(FontAwesomeIcons.signInAlt, size: 16, color: Colors.white),
                          label: Text(
                            _isLoading ? 'Logging in...' : 'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFF0632A1),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            shadowColor: Color(0xFF0632A1).withOpacity(0.3),
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ).animate().fade(duration: 600.ms),
                        SizedBox(height: 30), // Reduced from 40

                        // Divider with text for cleaner separation
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
                          ],
                        ),
                        SizedBox(height: 30),

                        // Register Section with improved styling
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Register Button with outline style for visual hierarchy
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF0632A1),
                            side: BorderSide(color: Color(0xFF0632A1), width: 1.5),
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(200, 44),
                          ),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ).animate().fade(duration: 700.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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