import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/leave_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyLeaveRequestsScreen extends StatefulWidget {
  const MyLeaveRequestsScreen({Key? key}) : super(key: key);

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

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          _leaveRequests = leaveRequests;
          _filteredLeaveRequests = leaveRequests;
          _supervisors = users
              .map((user) => User.fromJson(user))
              .where((user) => user.roles.contains('ADMIN') || user.roles.contains('LAB-MANAGER'))
              .toList();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        
        if (e.toString().contains('Not authorized')) {
          _showErrorSnackBar('Session expired. Please log in again.');
          await _logoutAndRedirect();
        } else {
          _showErrorSnackBar('Failed to load data: $e');
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _getSupervisorName(User? supervisor) {
    if (supervisor == null) return 'N/A';
    return '${supervisor.firstName} ${supervisor.lastName}';
  }

  void _filterLeaveRequests() {
    setState(() {
      _filteredLeaveRequests = _leaveRequests.where((leave) {
        final matchesStatus = _selectedStatus == 'All' ||
            (leave.status ?? 'Pending') == _selectedStatus;

        final query = _searchQuery.toLowerCase();
        final matchesSearch = leave.type.toLowerCase().contains(query) ||
            (leave.status ?? 'Pending').toLowerCase().contains(query) ||
            leave.startDate.toString().toLowerCase().contains(query) ||
            leave.endDate.toString().toLowerCase().contains(query) ||
            (leave.note ?? '').toLowerCase().contains(query) ||
            (leave.code ?? '').toLowerCase().contains(query);

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade600;
      case 'Rejected':
        return Colors.red.shade600;
      case 'Pending 1/2':
        return Colors.orange.shade600;
      case 'Pending':
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
    
    if (difference == 1) {
      return '1 day';
    } else {
      return '$difference days';
    }
  }

  void _showLeaveDetailsDialog(BuildContext context, Leave leave) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0632A1), Color(0xFF2E5CDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.type,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Request #${leave.code ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: _getStatusColor(leave.status).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: _getStatusColor(leave.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(leave.status).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        leave.status == 'Approved' 
                            ? Icons.check_circle
                            : leave.status == 'Rejected'
                                ? Icons.cancel
                                : Icons.hourglass_top,
                        color: _getStatusColor(leave.status),
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          leave.status ?? 'Pending',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(leave.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dates
                    _buildDialogInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date Range',
                      value: '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                      valueColor: Colors.grey.shade800,
                    ),
                    
                    _buildDialogInfoRow(
                      icon: Icons.timelapse,
                      label: 'Duration',
                      value: _getDurationText(leave),
                      valueColor: Colors.grey.shade800,
                    ),
                    
                    Divider(height: 32, thickness: 1, color: Colors.grey.shade200),
                    
                    // Applicant Info
                    _buildDialogInfoRow(
                      icon: Icons.person,
                      label: 'Applicant',
                      value: leave.fullName,
                      valueColor: Colors.grey.shade800,
                    ),
                    
                    _buildDialogInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: leave.email,
                      valueColor: Colors.grey.shade800,
                    ),
                    
                    Divider(height: 32, thickness: 1, color: Colors.grey.shade200),
                    
                    // Supervisor and Approvals
                    _buildDialogInfoRow(
                      icon: Icons.supervisor_account,
                      label: 'Supervisor',
                      value: _getSupervisorName(leave.supervisor),
                      valueColor: Colors.grey.shade800,
                    ),
                    
                    _buildDialogInfoRow(
                      icon: Icons.check_circle,
                      label: 'Supervisor Approval',
                      value: leave.supervisorAccepted != null
                          ? (leave.supervisorAccepted! ? 'Approved' : 'Rejected')
                          : 'Pending',
                      valueColor: leave.supervisorAccepted == true
                          ? Colors.green.shade600
                          : leave.supervisorAccepted == false
                              ? Colors.red.shade600
                              : Colors.orange.shade600,
                    ),
                    
                    _buildDialogInfoRow(
                      icon: Icons.manage_accounts,
                      label: 'Manager Approval',
                      value: leave.managerAccepted != null
                          ? (leave.managerAccepted! ? 'Approved' : 'Rejected')
                          : 'Pending',
                      valueColor: leave.managerAccepted == true
                          ? Colors.green.shade600
                          : leave.managerAccepted == false
                              ? Colors.red.shade600
                              : Colors.orange.shade600,
                    ),
                    
                    if (leave.note != null && leave.note!.isNotEmpty) ...[
                      Divider(height: 32, thickness: 1, color: Colors.grey.shade200),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              leave.note!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Footer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0632A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildDialogInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF0632A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0632A1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPath(Leave leave) {
    final stages = ['Pending 1/2', 'Pending', 'Final'];
    int currentStage = 0;
    if (leave.status == 'Pending 1/2') {
      currentStage = 0;
    } else if (leave.status == 'Pending') {
      currentStage = 1;
    } else {
      currentStage = 2; // Approved or Rejected
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stages.length, (index) {
          bool isActive = index <= currentStage;
          bool isLast = index == stages.length - 1;
          bool isApproved = leave.status == 'Approved' && isLast;
          bool isRejected = leave.status == 'Rejected' && isLast;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          String message;
                          if (index == 0) {
                            message = leave.supervisorAccepted == true
                                ? 'Supervisor approved on ${_formatDate(leave.startDate)}'
                                : 'Awaiting supervisor approval';
                          } else if (index == 1) {
                            message = leave.managerAccepted == true
                                ? 'Manager approved on ${_formatDate(leave.endDate)}'
                                : 'Awaiting manager approval';
                          } else {
                            message = leave.status == 'Approved'
                                ? 'Leave approved'
                                : leave.status == 'Rejected'
                                    ? 'Leave rejected'
                                    : 'Final status pending';
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: EdgeInsets.all(16),
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive 
                                ? isLast && isRejected 
                                    ? Colors.red.shade600
                                    : const Color(0xFF0632A1) 
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: isActive 
                                  ? isLast && isRejected 
                                      ? Colors.red.shade600
                                      : const Color(0xFF0632A1) 
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: isLast && isRejected
                                          ? Colors.red.shade600.withOpacity(0.3)
                                          : const Color(0xFF0632A1).withOpacity(0.3),
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
                                    size: 20,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stages[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive 
                              ? isLast && isRejected 
                                  ? Colors.red.shade600
                                  : const Color(0xFF0632A1) 
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
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isActive 
                                ? isLast && isRejected 
                                    ? Colors.red.shade600
                                    : const Color(0xFF0632A1) 
                                : Colors.grey.shade300,
                            index + 1 <= currentStage 
                                ? index + 1 == stages.length - 1 && leave.status == 'Rejected'
                                    ? Colors.red.shade600
                                    : const Color(0xFF0632A1) 
                                : Colors.grey.shade300,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF0632A1),
        child: Column(
          children: [
            // Header
            Container(
              height: MediaQuery.of(context).size.height * 0.22,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0632A1), Color(0xFF2E5CDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x290632A1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Back button
                    Positioned(
                      left: 16,
                      top: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    
                    // Title
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'My Leave Requests',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
                          SizedBox(height: 8),
                          Text(
                            'Manage your time off requests',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, delay: 300.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Search and Filter Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
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
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
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
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
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
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.filter_list, color: Color(0xFF0632A1)),
                        ),
                        items: ['All', 'Pending 1/2', 'Pending', 'Approved', 'Rejected'].map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'All' 
                                      ? Colors.grey.shade800
                                      : _getStatusColor(status),
                                  fontWeight: FontWeight.w500,
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
            
            // Leave Requests List
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
                              fontSize: 16,
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
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Color(0xFF0632A1).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.event_busy,
                                  size: 50,
                                  color: Color(0xFF0632A1),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'No leave requests found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 8),
Padding(
  padding: EdgeInsets.symmetric(horizontal: 40),
  child: Text(
    'Try adjusting your search or filter settings',
    style: TextStyle(
      fontSize: 14,
      color: Colors.grey.shade600,
    ),
    textAlign: TextAlign.center,
  ),
),                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _refreshData,
                                icon: Icon(Icons.refresh, size: 18),
                                label: Text('Refresh', style: TextStyle(fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0632A1),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 500.ms),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredLeaveRequests.length,
                          itemBuilder: (context, index) {
                            final leave = _filteredLeaveRequests[index];
                            return _buildLeaveCard(leave, index);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create leave request screen
          _showSuccessSnackBar('Create leave request feature coming soon!');
        },
        backgroundColor: Color(0xFF0632A1),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, size: 28),
      ).animate().scale(duration: 300.ms, delay: 600.ms),
    );
  }

  Widget _buildLeaveCard(Leave leave, int index) {
    final statusColor = _getStatusColor(leave.status);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLeaveDetailsDialog(context, leave),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF9FAFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type and Status
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0632A1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event,
                            color: Color(0xFF0632A1),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.type,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0632A1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${leave.code ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        leave.status ?? 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dates and Duration
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timelapse, size: 16, color: Colors.grey.shade600),
                          SizedBox(width: 8),
                          Text(
                            _getDurationText(leave),
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Supervisor
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Text(
                      'Supervisor: ',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    Text(
                      _getSupervisorName(leave.supervisor),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
              
              // Status Path
              _buildStatusPath(leave),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, delay: (300 + index * 100).ms);
  }
}