import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/users/forgotPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _emailController.text}),
      );

      if (response.statusCode == 200) {
        String id = response.body.replaceAll('"', '');
        Navigator.pushNamed(
          context,
          '/validate-code',
          arguments: {
            'id': id,
            'email': _emailController.text,
          },
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'User not found or an error occurred',
          confirmBtnColor: const Color(0xFF0632A1),
        );
      }
    } catch (e) {
      print('Error: $e');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'An error occurred while sending the code',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: const BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/illustrations/forgot.png',
                      height: 150,
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                    const SizedBox(height: 20),
                    Text(
                      'Forgot password? We got you.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0632A1),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                    const SizedBox(height: 10),
                    Text(
                      'We will send you a code to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: Color(0xFF0632A1)),
                        labelText: 'Enter your email',
                        labelStyle: const TextStyle(color: Color(0xFF0632A1)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0632A1), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0632A1), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: const TextStyle(color: Color(0xFF0632A1)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF0632A1))
                        : ElevatedButton(
                            onPressed: _requestPasswordReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0632A1),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Send Code',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 700.ms),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(color: Color(0xFF0632A1)),
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
}