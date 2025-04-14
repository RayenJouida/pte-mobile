import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For simple persistent state

class HomeScreen extends StatelessWidget {
  // Check if the user is logged in
  Future<bool> checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false; // Use SharedPreferences to check if user is logged in
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/homebackground.jpg"), // Background image
            fit: BoxFit.cover, // Cover the entire screen
          ),
        ),
        child: FutureBuilder<bool>(
          future: checkIfLoggedIn(), // Fetch the login status
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // Show loading indicator while checking
            }

            if (snapshot.hasData && snapshot.data == true) {
              // If the user is logged in, show a welcome message
              return Center(
                child: Text(
                  "Welcome, you're logged in!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            } else {
              // If not logged in, show the welcome back screen
              return Stack(
                children: [
                  // Centered Content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Welcome Back Title
                          AnimatedOpacity(
                            opacity: 1.0,
                            duration: Duration(seconds: 1),
                            child: AnimatedPadding(
                              duration: Duration(seconds: 1),
                              padding: EdgeInsets.only(bottom: 16), // Add margin below the title
                              child: Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Animated Subtitle
                          AnimatedOpacity(
                            opacity: 1.0,
                            duration: Duration(seconds: 1),
                            child: AnimatedPadding(
                              duration: Duration(seconds: 1),
                              padding: EdgeInsets.only(bottom: 40), // Add margin below the subtitle
                              child: Text(
                                "Press Sign Up if you've just joined us,\npress Login if you're already registered.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ),
                          // Buttons side by side with animations
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Animated Login Button
                              Expanded(
                                child: AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: Duration(seconds: 1),
                                  child: AnimatedPadding(
                                    duration: Duration(seconds: 1),
                                    padding: EdgeInsets.zero,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/login'); // Navigate to Login screen
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Color(0xFF0632A1), // Text color blue
                                        backgroundColor: Colors.white, // Background color white
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Login",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16), // Space between buttons
                              // Animated Sign Up Button
                              Expanded(
                                child: AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: Duration(seconds: 1),
                                  child: AnimatedPadding(
                                    duration: Duration(seconds: 1),
                                    padding: EdgeInsets.zero,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/signup'); // Navigate to Signup screen
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white, // Text color white
                                        backgroundColor: Color(0xFF0632A1), // Background color blue
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer with copyright notice
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24, // Position the footer at the bottom
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(seconds: 1),
                      child: AnimatedPadding(
                        duration: Duration(seconds: 1),
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.copyright,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            SizedBox(width: 4), // Space between icon and text
                            Text(
                              "Copyrights 2025. All rights are reserved to Prologic.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}