import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/leave/leave_request_screen.dart';
import 'package:pte_mobile/services/leave_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class MyLeaveRequestsScreen extends StatefulWidget {
  final int? currentIndex;

  const MyLeaveRequestsScreen({Key? key, this.currentIndex}) : super(key: key);

  @override
  _MyLeaveRequestsScreenState createState() => _MyLeaveRequestsScreenState();
}

class _MyLeaveRequestsScreenState extends State<MyLeaveRequestsScreen> {
  final LeaveService _leaveService = LeaveService();
  final UserService _userService = UserService();
  List<Leave> _leaveRequests = [];
  List<Leave> _filteredLeaveRequests = [];
  List<User> _supervisors = [];
  bool _isLoading = true;
  String? _userId;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isRefreshing = false;
  String? _currentUserRole;
  int _currentIndex = 0;

  int _currentPage = 1;
  final int _itemsPerPage = 4;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.currentIndex != null) {
      _currentIndex = widget.currentIndex!;
    } else {
      _getDefaultIndex().then((value) {
        if (mounted) {
          setState(() {
            _currentIndex = value;
          });
        }
      });
    }
    _checkAuthentication();
    _fetchCurrentUserRole();
  }

  Future<int> _getDefaultIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole') ?? 'ASSISTANT';
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 14;
      case 'ASSISTANT':
        return 8;
      case 'ENGINEER':
        return 7;
      case 'LAB-MANAGER':
        return 9;
      default:
        return 8;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Assistant';
    });
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('authToken');
    if (userId == null || token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    setState(() {
      _userId = userId;
    });
    _fetchData();
  }

  Future<void> _logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('authToken');
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final leaveRequests = await _leaveService.fetchUserLeaves(_userId!);
      final users = await _userService.fetchUsers();

      if (mounted) {
        setState(() {
          _leaveRequests = leaveRequests..sort((a, b) => b.startDate.compareTo(a.startDate));
          _filteredLeaveRequests = _leaveRequests;
          _supervisors = users
              .map((user) => User.fromJson(user))
              .where((user) => user.teamLeader == true)
              .toList();
          _isLoading = false;
          _isRefreshing = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });

        if (e.toString().contains('Not authorized')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Session expired. Please log in again.')),
                ],
              ),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
          await _logoutAndRedirect();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Failed to load data: $e')),
                ],
              ),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchData();
  }

  String _getSupervisorName(User? supervisor) {
    if (supervisor == null) return 'N/A';
    return '${supervisor.firstName} ${supervisor.lastName}';
  }

  void _filterLeaveRequests() {
    setState(() {
      _filteredLeaveRequests = _leaveRequests.where((leave) {
        final status = leave.status ?? 'Pending 0/2';
        final matchesStatus = _selectedStatus == 'All' ||
            (status == 'Pending 0/2' && _selectedStatus == 'Pending 0/2') ||
            (status == 'Pending 1/2' && _selectedStatus == 'Pending 1/2') ||
            (status == _selectedStatus);

        final query = _searchQuery.toLowerCase();
        final matchesSearch = leave.type.toLowerCase().contains(query) ||
            status.toLowerCase().contains(query) ||
            leave.startDate.toString().toLowerCase().contains(query) ||
            leave.endDate.toString().toLowerCase().contains(query) ||
            (leave.note ?? '').toLowerCase().contains(query) ||
            (leave.code ?? '').toLowerCase().contains(query);

        return matchesStatus && matchesSearch;
      }).toList();
      _currentPage = 1;
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade600;
      case 'Rejected':
      case 'Declined':
        return Colors.red.shade600;
      case 'Pending 0/2':
      case 'Pending 1/2':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getDurationText(Leave leave) {
    final start = leave.startDate;
    final end = leave.endDate;
    final difference = end.difference(start).inDays + 1;
    return difference == 1 ? '1 day' : '$difference days';
  }

  Future<void> _downloadCertificate(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('No certificate URL available.'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    print('Attempting to download certificate from URL: $url');
    final fullUrl = '${Env.certBaseUrl}$url';
    print('Full URL constructed: $fullUrl');

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt < 29) {
        final permissionStatus = await Permission.storage.request();
        if (!permissionStatus.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Storage permission denied. Cannot download the file.'),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      } else if (sdkInt >= 30 && sdkInt <= 32) {
        final permissionStatus = await Permission.manageExternalStorage.request();
        if (!permissionStatus.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Manage storage permission denied. Cannot download the file.'),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      print('Using auth token: $token');
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('HTTP response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: Status ${response.statusCode}');
      }

      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          print('Downloads directory not found, falling back to external storage');
          downloadDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      } else {
        downloadDir = await getTemporaryDirectory();
      }

      if (downloadDir == null) {
        throw Exception('Could not find a suitable directory to save the file.');
      }

      print('Saving file to directory: ${downloadDir.path}');
      final fileName = url.split('/').last;
      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      print('File saved successfully at: $filePath');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Certificate downloaded to Downloads folder: $fileName',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('Download error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to download certificate: $e',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showLeaveDetailsDialog(BuildContext context, Leave leave) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.6;
    final maxDialogHeight = screenSize.height * 0.85;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 24,
          vertical: isSmallScreen ? 16 : 24,
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 20 : 24,
                  horizontal: isSmallScreen ? 20 : 28,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0632A1), Color(0xFF2E5CDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leave.type,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 22 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Request #${leave.code ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(dialogContext),
                            splashRadius: 20,
                            padding: EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(leave.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _getStatusColor(leave.status).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            leave.status == 'Approved'
                                ? Icons.check_circle
                                : (leave.status == 'Rejected' || leave.status == 'Declined')
                                    ? Icons.cancel
                                    : Icons.hourglass_top,
                            color: Colors.white,
                            size: isSmallScreen ? 16 : 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            leave.status ?? 'Pending 0/2',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 20 : 28,
                    horizontal: isSmallScreen ? 20 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(
                        title: 'Date Information',
                        icon: Icons.date_range,
                        iconColor: Color(0xFF0632A1),
                        content: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              label: 'Start Date',
                              value: _formatDate(leave.startDate),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              label: 'End Date',
                              value: _formatDate(leave.endDate),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              icon: Icons.timelapse,
                              label: 'Duration',
                              value: _getDurationText(leave),
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(height: 24),
                      _buildInfoCard(
                        title: 'Approval Information',
                        icon: Icons.verified_user,
                        iconColor: Color(0xFF0632A1),
                        content: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.supervisor_account,
                              label: 'Supervisor',
                              value: _getSupervisorName(leave.supervisor),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: 16),
                            _buildApprovalRow(
                              label: 'Supervisor Approval',
                              isApproved: leave.supervisorAccepted,
                              status: leave.status,
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: 16),
                            _buildApprovalRow(
                              label: 'Manager Approval',
                              isApproved: leave.managerAccepted,
                              status: leave.status,
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        ),
                        isSmallScreen: isSmallScreen,
                      ),
                      if (leave.note != null && leave.note!.isNotEmpty) ...[
                        SizedBox(height: 24),
                        _buildInfoCard(
                          title: 'Additional Notes',
                          icon: Icons.notes,
                          iconColor: Color(0xFF0632A1),
                          content: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              leave.note!,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                color: Colors.grey.shade800,
                                height: 1.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                      SizedBox(height: 24),
                      _buildInfoCard(
                        title: 'Approval Timeline',
                        icon: Icons.timeline,
                        iconColor: Color(0xFF0632A1),
                        content: _buildApprovalTimeline(leave, isSmallScreen),
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(Icons.close),
                      label: Text('Close'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 20,
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ),
                    if (leave.certif != null && leave.certif!.isNotEmpty) ...[
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _downloadCertificate(leave.certif!, dialogContext),
                        icon: Icon(Icons.download),
                        label: Text('Download Certif'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0632A1),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: isSmallScreen ? 18 : 20, color: iconColor),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0632A1),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: isSmallScreen ? 16 : 18, color: Colors.grey.shade700),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 16,
                  color: valueColor ?? Colors.grey.shade800,
                  fontWeight: valueBold ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalRow({
    required String label,
    required bool? isApproved,
    required String? status,
    required bool isSmallScreen,
  }) {
    final isPending = status == 'Pending 0/2' || status == 'Pending 1/2';
    final statusText = isApproved == true
        ? 'Approved'
        : isPending
            ? 'Pending'
            : isApproved == false
                ? 'Rejected'
                : 'Pending';
    final statusColor = isApproved == true
        ? Colors.green.shade600
        : isPending
            ? Colors.orange.shade600
            : isApproved == false
                ? Colors.red.shade600
                : Colors.orange.shade600;
    final statusIcon = isApproved == true
        ? Icons.check_circle
        : isPending
            ? Icons.hourglass_top
            : isApproved == false
                ? Icons.cancel
                : Icons.hourglass_top;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(statusIcon, size: isSmallScreen ? 16 : 18, color: statusColor),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalTimeline(Leave leave, bool isSmallScreen) {
    bool isSupervisorPreApproved = leave.supervisorAccepted == true && leave.status == 'Pending 1/2' && leave.managerAccepted == null;
    final isPending = leave.status == 'Pending 0/2' || leave.status == 'Pending 1/2';

    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Request Submitted',
        'description': 'Your leave request has been submitted',
        'icon': Icons.note_add,
        'isCompleted': true,
        'date': _formatDate(leave.startDate),
      },
      if (!isSupervisorPreApproved)
        {
          'title': 'Supervisor Review',
          'description': leave.supervisorAccepted == true
              ? 'Approved by supervisor'
              : isPending
                  ? 'Not treated yet'
                  : 'Rejected by supervisor',
          'icon': Icons.supervisor_account,
          'isCompleted': leave.supervisorAccepted != null || isPending,
          'isRejected': leave.supervisorAccepted == false && !isPending,
          'date': leave.supervisorAccepted != null && !isPending ? _formatDate(leave.startDate) : null,
        },
      {
        'title': 'Manager Review',
        'description': leave.managerAccepted == true
            ? 'Approved by manager'
            : isPending
                ? 'Not treated yet'
                : 'Rejected by manager',
        'icon': Icons.manage_accounts,
        'isCompleted': leave.managerAccepted != null || isPending,
        'isRejected': leave.managerAccepted == false && !isPending,
        'date': leave.managerAccepted != null && !isPending ? _formatDate(leave.endDate) : null,
      },
      {
        'title': 'Final Status',
        'description': leave.status == 'Approved'
            ? 'Your leave request has been approved'
            : (leave.status == 'Rejected' || leave.status == 'Declined')
                ? 'Your leave request has been rejected'
                : 'Awaiting final status',
        'icon': leave.status == 'Approved'
            ? Icons.check_circle
            : (leave.status == 'Rejected' || leave.status == 'Declined')
                ? Icons.cancel
                : Icons.pending_actions,
        'isCompleted': leave.status == 'Approved' || leave.status == 'Rejected' || leave.status == 'Declined',
        'isRejected': leave.status == 'Rejected' || leave.status == 'Declined',
        'date': (leave.status == 'Approved' || leave.status == 'Rejected' || leave.status == 'Declined') ? _formatDate(leave.endDate) : null,
      },
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLastStep = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: step['isCompleted']
                          ? step['isRejected'] == true
                              ? Colors.red.shade600
                              : Color(0xFF0632A1)
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: step['isCompleted']
                            ? step['isRejected'] == true
                                ? Colors.red.shade600
                                : Color(0xFF0632A1)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        step['icon'],
                        size: 12,
                        color: step['isCompleted'] ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  if (!isLastStep)
                    Container(
                      width: 2,
                      height: 50,
                      color: steps[index + 1]['isCompleted']
                          ? steps[index + 1]['isRejected'] == true
                              ? Colors.red.shade600
                              : Color(0xFF0632A1)
                          : Colors.grey.shade300,
                      margin: EdgeInsets.symmetric(vertical: 4),
                    ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          step['title'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 16,
                            fontWeight: FontWeight.w600,
                            color: step['isCompleted']
                                ? step['isRejected'] == true
                                    ? Colors.red.shade600
                                    : Color(0xFF0632A1)
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (step['date'] != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              step['date'],
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      step['description'],
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusPath(Leave leave, bool isSmallScreen) {
    bool isSupervisorPreApproved = leave.supervisorAccepted == true && leave.status == 'Pending 1/2' && leave.managerAccepted == null;
    final stages = isSupervisorPreApproved
        ? ['Pending 1/2', 'Final']
        : ['Pending 0/2', 'Pending 1/2', 'Final'];

    int currentStage = 0;
    if (isSupervisorPreApproved) {
      if (leave.status == 'Pending 1/2') currentStage = 0;
      else currentStage = 1;
    } else {
      if (leave.status == 'Pending 0/2') currentStage = 0;
      else if (leave.status == 'Pending 1/2') currentStage = 1;
      else currentStage = 2;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 12,
        horizontal: isSmallScreen ? 6 : 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stages.length, (index) {
          bool isActive = index <= currentStage;
          bool isLast = index == stages.length - 1;
          bool isApproved = leave.status == 'Approved' && isLast;
          bool isRejected = (leave.status == 'Rejected' || leave.status == 'Declined') && isLast;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          String message;
                          if (isSupervisorPreApproved) {
                            if (index == 0) message = 'Awaiting manager approval';
                            else message = leave.status == 'Approved'
                                ? 'Leave approved'
                                : (leave.status == 'Rejected' || leave.status == 'Declined')
                                    ? 'Leave rejected'
                                    : 'Final status pending';
                          } else {
                            if (index == 0) message = leave.supervisorAccepted == true
                                ? 'Supervisor approved on ${_formatDate(leave.startDate)}'
                                : 'Awaiting supervisor approval';
                            else if (index == 1) message = leave.managerAccepted == true
                                ? 'Manager approved on ${_formatDate(leave.endDate)}'
                                : 'Awaiting manager approval';
                            else message = leave.status == 'Approved'
                                ? 'Leave approved'
                                : (leave.status == 'Rejected' || leave.status == 'Declined')
                                    ? 'Leave rejected'
                                    : 'Final status pending';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                message,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            ),
                          );
                        },
                        child: Container(
                          width: isSmallScreen ? 32 : 36,
                          height: isSmallScreen ? 32 : 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? isLast && isRejected
                                    ? Colors.red.shade600
                                    : Color(0xFF0632A1)
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: isActive
                                  ? isLast && isRejected
                                      ? Colors.red.shade600
                                      : Color(0xFF0632A1)
                                  : Colors.grey.shade400,
                              width: isSmallScreen ? 1.5 : 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: isLast && isRejected
                                          ? Colors.red.shade600.withOpacity(0.3)
                                          : Color(0xFF0632A1).withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: isLast && (isApproved || isRejected)
                                ? Icon(
                                    isApproved ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: isSmallScreen ? 16 : 20,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(
                        stages[index],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: isActive
                              ? isLast && isRejected
                                  ? Colors.red.shade600
                                  : Color(0xFF0632A1)
                              : Colors.grey.shade600,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < stages.length - 1)
                  Expanded(
                    child: Container(
                      height: isSmallScreen ? 3 : 4,
                      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isActive
                                ? isLast && isRejected
                                    ? Colors.red.shade600
                                    : Color(0xFF0632A1)
                                : Colors.grey.shade300,
                            index + 1 <= currentStage
                                ? index + 1 == stages.length - 1 && (leave.status == 'Rejected' || leave.status == 'Declined')
                                    ? Colors.red.shade600
                                    : Color(0xFF0632A1)
                                : Colors.grey.shade300,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 1.5 : 2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Leave> _getPaginatedLeaves() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredLeaveRequests
        .asMap()
        .entries
        .where((entry) => entry.key >= startIndex && entry.key < endIndex)
        .map((entry) => entry.value)
        .toList();
  }

  Widget _buildPaginationControls() {
    final totalItems = _filteredLeaveRequests.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (totalItems == 0) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSmallScreen ? 16 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _scrollController.jumpTo(0);
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentPage > 1 ? Colors.white : Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_left,
                color: _currentPage > 1 ? Color(0xFF0632A1) : Colors.grey.shade400,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),
          SizedBox(width: 12),
          Row(
            children: List.generate(totalPages, (index) {
              final pageNumber = index + 1;
              final isActive = _currentPage == pageNumber;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage = pageNumber;
                    });
                    _scrollController.jumpTo(0);
                  },
                  child: Container(
                    width: isSmallScreen ? 32 : 36,
                    height: isSmallScreen ? 32 : 36,
                    decoration: BoxDecoration(
                      color: isActive ? Color(0xFF0632A1) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _scrollController.jumpTo(0);
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentPage < totalPages ? Colors.white : Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_right,
                color: _currentPage < totalPages ? Color(0xFF0632A1) : Colors.grey.shade400,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == _getDefaultIndex()) _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final horizontalPadding = screenSize.width * (isSmallScreen ? 0.04 : 0.08);

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      drawer: _currentUserRole == 'ADMIN'
          ? AdminSidebar(
              currentIndex: _currentIndex,
              onTabChange: (index) {
                _handleTabChange(index);
              },
            )
          : _currentUserRole == 'LAB-MANAGER'
              ? LabManagerSidebar(
                  currentIndex: _currentIndex,
                  onTabChange: (index) {
                    _handleTabChange(index);
                  },
                )
              : _currentUserRole == 'ENGINEER'
                  ? EngineerSidebar(
                      currentIndex: _currentIndex,
                      onTabChange: (index) {
                        _handleTabChange(index);
                      },
                    )
                  : AssistantSidebar(
                      currentIndex: _currentIndex,
                      onTabChange: (index) {
                        _handleTabChange(index);
                      },
                    ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Color(0xFF0632A1),
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
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
                      'My Leave Requests',
                      style: TextStyle(
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
                        icon: Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isSmallScreen ? 12 : 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Color(0xFF0632A1),
                      size: isSmallScreen ? 24 : 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LeaveRequestScreen()),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: isSmallScreen ? 45 : 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search requests...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF0632A1),
                            size: isSmallScreen ? 20 : 24,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 15,
                            horizontal: isSmallScreen ? 12 : 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _filterLeaveRequests();
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Container(
                    height: isSmallScreen ? 45 : 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: Padding(
                          padding: EdgeInsets.only(right: isSmallScreen ? 6 : 8),
                          child: Icon(
                            Icons.filter_list,
                            color: Color(0xFF0632A1),
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        items: ['All', 'Pending 0/2', 'Pending 1/2', 'Approved', 'Rejected', 'Declined'].map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 12,
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'All'
                                      ? Colors.grey.shade800
                                      : _getStatusColor(status),
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _filterLeaveRequests();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF0632A1),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading your leave requests...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredLeaveRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: Color(0xFF0632A1).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.event_busy,
                                  size: isSmallScreen ? 40 : 50,
                                  color: Color(0xFF0632A1),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              Text(
                                'No leave requests found',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 32 : 40,
                                ),
                                child: Text(
                                  'Try adjusting your search or filter settings',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              ElevatedButton.icon(
                                onPressed: _refreshData,
                                icon: Icon(Icons.refresh, size: isSmallScreen ? 16 : 18),
                                label: Text(
                                  'Refresh',
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0632A1),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 20 : 24,
                                    vertical: isSmallScreen ? 10 : 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 500.ms),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: isSmallScreen ? 8 : 12,
                                ),
                                itemCount: _getPaginatedLeaves().length,
                                itemBuilder: (context, index) {
                                  final leave = _getPaginatedLeaves()[index];
                                  return _buildLeaveCard(leave, index, isSmallScreen);
                                },
                              ),
                            ),
                            _buildPaginationControls(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveCard(Leave leave, int index, bool isSmallScreen) {
    final statusColor = _getStatusColor(leave.status);
    final cardPadding = isSmallScreen ? 12.0 : 16.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLeaveDetailsDialog(context, leave),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF9FAFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(cardPadding, cardPadding, cardPadding, cardPadding * 0.75),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                            decoration: BoxDecoration(
                              color: Color(0xFF0632A1).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event,
                              color: Color(0xFF0632A1),
                              size: isSmallScreen ? 18 : 20,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leave.type,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0632A1),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Code: ${leave.code ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: isSmallScreen ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        leave.status ?? 'Pending 0/2',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: cardPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: isSmallScreen ? 14 : 16,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Expanded(
                              child: Text(
                                '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timelapse,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Text(
                            _getDurationText(leave),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(cardPadding, cardPadding * 0.75, cardPadding, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      'Supervisor: ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getSupervisorName(leave.supervisor),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusPath(leave, isSmallScreen),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (index * 100).ms);
  }
}