import 'package:flutter/material.dart';
import 'labmanager_bottom_navbar.dart'; // Import the LabManagerBottomNavigationBar

class HomeLabScreen extends StatelessWidget {
  const HomeLabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Welcome to the Lab Manager Home Screen!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: LabManagerBottomNavigationBar(), // Add the bottom navbar
    );
  }
}