import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickalert/quickalert.dart';
import 'package:pte_mobile/services/virtualization_env_service.dart';
import '../../models/virtualization_env.dart';

class RequestsByUserId extends StatefulWidget {
  const RequestsByUserId({Key? key}) : super(key: key);

  @override
  State<RequestsByUserId> createState() => _RequestsByUserIdState();
}

class _RequestsByUserIdState extends State<RequestsByUserId> {
  final VirtualizationEnvService _service = VirtualizationEnvService();
  List<VirtualizationEnv> _requests = [];
  bool _isLoading = true;
  String? _userId;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndRequests();
  }

  Future<void> _loadUserIdAndRequests() async {
    print('===== STARTING LOAD PROCESS =====');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');

      print('Loaded userId from SharedPreferences: $_userId');
      print('All SharedPreferences keys: ${prefs.getKeys()}');

      if (_userId == null) {
        print('ERROR: No user ID found in SharedPreferences');
        setState(() {
          _isLoading = false;
          _lastError = 'No user ID found. Please log in again.';
        });
        return;
      }

      print('Fetching requests for user: $_userId');
      final requests = await _service.getUserLabEnvs(_userId!);

      print('Received ${requests.length} requests from service');
      if (requests.isNotEmpty) {
        print('First request details:');
        print('ID: ${requests[0].id}');
        print('Type: ${requests[0].type}');
        print('Status: ${requests[0].status}');
        print('Applicant ID: ${requests[0].applicantId}');
      } else {
        print('No requests returned for this user.');
      }

      setState(() {
        _requests = requests;
        _isLoading = false;
        _lastError = null;
      });
    } catch (e) {
      print('===== ERROR IN LOAD PROCESS =====');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      setState(() {
        _isLoading = false;
        _lastError = e.toString();
      });

      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Load Error',
        text: 'Failed to fetch requests: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('===== BUILDING WIDGET =====');
    print('Current requests count: ${_requests.length}');
    print('Loading state: $_isLoading');
    print('Last error: $_lastError');

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: const BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Text(
                'My Lab Requests',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No requests found yet.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submit a new request from "Request Lab"!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_lastError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _lastError!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/settings'), // Adjust route if needed
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0632A1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Go to Request Lab'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadUserIdAndRequests,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0632A1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _requests.map((request) {
                            return _buildRequestCard(request).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(VirtualizationEnv request) {
    print('Building card for request: ${request.id}');
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Typo: should be bottom
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Processor: ${request.processor}', style: const TextStyle(color: Colors.black)),
            Text('RAM: ${request.ram} GB', style: const TextStyle(color: Colors.black)),
            Text('Disk: ${request.disk} GB', style: const TextStyle(color: Colors.black)),
            Text('Goals: ${request.goals}', style: const TextStyle(color: Colors.black)),
            Text(
              'Start: ${request.start.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.black),
            ),
            Text(
              'End: ${request.end.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'active':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}