import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ValidateCodeScreen extends StatefulWidget {
  @override
  _ValidateCodeScreenState createState() => _ValidateCodeScreenState();
}

class _ValidateCodeScreenState extends State<ValidateCodeScreen> {
  late String id;
  late String email;
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _canResend = true;
  int _resendCooldown = 60;
  int _currentCooldown = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    id = args['id'];
    email = args['email'];
  }

  Future<void> _validateCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text;

      final response = await http.post(
        Uri.parse('${Env.apiUrl}/users/validateCode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        Navigator.pushNamed(
          context,
          '/change-password',
          arguments: {'id': id, 'email': email},
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Invalid code',
          confirmBtnColor: const Color(0xFF0632A1),
        );
      }
    } catch (e) {
      print('Error: $e');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'An error occurred while validating the code',
        confirmBtnColor: const Color(0xFF0632A1),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _canResend = false;
      _currentCooldown = _resendCooldown;
    });

    // Start countdown
    for (int i = _resendCooldown; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _currentCooldown = i;
      });
    }

    setState(() {
      _canResend = true;
    });

    // Resend the code
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/users/forgotPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        String newId = response.body.replaceAll('"', '');
        setState(() {
          id = newId;
        });
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success',
          text: 'A new code has been sent to your email',
          confirmBtnColor: const Color(0xFF0632A1),
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Failed to resend the code',
          confirmBtnColor: const Color(0xFF0632A1),
        );
      }
    } catch (e) {
      print('Error: $e');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'An error occurred while resending the code',
        confirmBtnColor: const Color(0xFF0632A1),
      );
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
                'Validate Code',
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
                      'assets/illustrations/validate.png',
                      height: 150,
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                    const SizedBox(height: 20),
                    Text(
                      'Enter the code sent to your email.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0632A1),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF0632A1)),
                        labelText: 'Enter the verification code',
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
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the verification code';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'Code must be numeric';
                        }
                        return null;
                      },
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF0632A1))
                        : ElevatedButton(
                            onPressed: _validateCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0632A1),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Validate Code',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _canResend ? _resendCode : null,
                      child: Text(
                        _canResend ? 'Resend Code' : 'Resend Code ($_currentCooldown s)',
                        style: TextStyle(
                          color: _canResend ? const Color(0xFF0632A1) : Colors.grey,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 700.ms),
                    const SizedBox(height: 10),
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