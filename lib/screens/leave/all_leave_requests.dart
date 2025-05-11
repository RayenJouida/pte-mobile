import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/leave_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllLeaveRequestsScreen extends StatefulWidget {
  const AllLeaveRequestsScreen({Key? key}) : super(key: key);

  @override
  _AllLeaveRequestsScreenState createState() => _AllLeaveRequestsScreenState();
}

class _AllLeaveRequestsScreenState extends State<AllLeaveRequestsScreen> {
  final LeaveService _leaveService = LeaveService();
  final UserService _userService = UserService();
  List<Leave> _leaveRequests = [];
  List<Leave> _filteredLeaveRequests = [];
  List<User> _supervisors = [];
  bool _isLoading = true;
  String? _userRole;
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final role = prefs.getString('userRole');
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    setState(() {
      _userRole = role;
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
      final leaveRequests = await _leaveService.fetchAllLeaves();
      final users = await _userService.fetchUsers();
      setState(() {
        _leaveRequests = leaveRequests;
        _filteredLeaveRequests = leaveRequests;
        _supervisors = users
            .map((user) => User.fromJson(user))
            .where((user) => user.roles.contains('ADMIN') || user.roles.contains('LAB-MANAGER'))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (e.toString().contains('Not authorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        await _logoutAndRedirect();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
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
            (leave.code ?? '').toLowerCase().contains(query) ||
            leave.fullName.toLowerCase().contains(query) ||
            leave.email.toLowerCase().contains(query);

        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending 1/2':
        return Colors.orange;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleApproval(String leaveId, bool approve) async {
    try {
      if (_userRole == 'ADMIN') {
        if (approve) {
          await _leaveService.managerAccept(leaveId);
        } else {
          await _leaveService.managerDecline(leaveId);
        }
      } else if (_userRole == 'LAB-MANAGER') {
        if (approve) {
          await _leaveService.workerAccept(leaveId);
        } else {
          await _leaveService.workerDecline(leaveId);
        }
      }
      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Leave request approved' : 'Leave request declined')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process request: $e')),
      );
    }
  }

  void _showLeaveDetailsDialog(BuildContext context, Leave leave) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0632A1), Color(0xFF2E5CDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        leave.type,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(leave.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(leave.status), width: 1),
                          ),
                          child: Text(
                            leave.status ?? 'Pending',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(leave.status),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Code: ${leave.code ?? 'N/A'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDialogInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date Range',
                      value:
                          '${leave.startDate.toLocal().toString().split(' ')[0]} - ${leave.endDate.toLocal().toString().split(' ')[0]}',
                    ),
                    const Divider(height: 30),
                    _buildDialogInfoRow(
                      icon: Icons.person,
                      label: 'Applicant',
                      value: leave.fullName,
                    ),
                    _buildDialogInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: leave.email,
                    ),
                    const Divider(height: 30),
                    _buildDialogInfoRow(
                      icon: Icons.supervisor_account,
                      label: 'Supervisor',
                      value: _getSupervisorName(leave.supervisor),
                    ),
                    _buildDialogInfoRow(
                      icon: Icons.check_circle,
                      label: 'Supervisor Accepted',
                      value: leave.supervisorAccepted != null
                          ? (leave.supervisorAccepted! ? 'Yes' : 'No')
                          : 'Pending',
                      valueColor: leave.supervisorAccepted == true
                          ? Colors.green
                          : leave.supervisorAccepted == false
                              ? Colors.red
                              : Colors.grey,
                    ),
                    _buildDialogInfoRow(
                      icon: Icons.manage_accounts,
                      label: 'Manager Accepted',
                      value: leave.managerAccepted != null
                          ? (leave.managerAccepted! ? 'Yes' : 'No')
                          : 'Pending',
                      valueColor: leave.managerAccepted == true
                          ? Colors.green
                          : leave.managerAccepted == false
                              ? Colors.red
                              : Colors.grey,
                    ),
                    if (leave.note != null && leave.note!.isNotEmpty) ...[
                      const Divider(height: 30),
                      _buildDialogInfoRow(
                        icon: Icons.note,
                        label: 'Note',
                        value: leave.note!,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (leave.status != 'Approved' && leave.status != 'Rejected') ...[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleApproval(leave.id, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleApproval(leave.id, false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0632A1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeInOut),
      ),
    );
  }

  Widget _buildDialogInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0632A1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w400,
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
      currentStage = 2;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stages.length, (index) {
          bool isActive = index <= currentStage;
          bool isLast = index == stages.length - 1;
          bool isApproved = leave.status == 'Approved' && isLast;
          bool isRejected = leave.status == 'Rejected' && isLast;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        String message;
                        if (index == 0) {
                          message = leave.supervisorAccepted == true
                              ? 'Supervisor approved on ${leave.startDate.toLocal().toString().split(' ')[0]}'
                              : 'Awaiting supervisor approval';
                        } else if (index == 1) {
                          message = leave.managerAccepted == true
                              ? 'Manager approved on ${leave.endDate.toLocal().toString().split(' ')[0]}'
                              : 'Awaiting manager approval';
                        } else {
                          message = leave.status == 'Approved'
                              ? 'Leave approved'
                              : leave.status == 'Rejected'
                                  ? 'Leave rejected'
                                  : 'Final status pending';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? const Color(0xFF0632A1) : Colors.grey[200],
                          border: Border.all(
                            color: isActive ? const Color(0xFF0632A1) : Colors.grey[400]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isActive ? const Color(0xFF0632A1).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
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
                                    color: isActive ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                        color: isActive ? const Color(0xFF0632A1) : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (index < stages.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isActive ? const Color(0xFF0632A1) : Colors.grey[300]!,
                              index + 1 <= currentStage ? const Color(0xFF0632A1) : Colors.grey[300]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
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
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
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
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'All Leave Requests',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
                ),
                Positioned(
                  left: 16,
                  top: MediaQuery.of(context).padding.top + 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by type, status, applicant...',
                        hintStyle: TextStyle(color: Colors.grey),
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
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      icon: const Icon(Icons.filter_list, color: Color(0xFF0632A1)),
                      items: ['All', 'Pending 1/2', 'Pending', 'Approved', 'Rejected'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              status,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
            ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLeaveRequests.isEmpty
                    ? Center(
                        child: Text(
                          'No leave requests found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(duration: 500.ms),
                      )
                    : ListView.builder(
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
    );
  }

  Widget _buildLeaveCard(Leave leave, int index) {
    final statusColor = _getStatusColor(leave.status);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLeaveDetailsDialog(context, leave),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0632A1).withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0632A1).withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.event,
                            color: Color(0xFF0632A1),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.type,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0632A1),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Code: ${leave.code ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                      ),
                      child: Text(
                        leave.status ?? 'Pending',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Color(0xFF0632A1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Applicant: ${leave.fullName}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF0632A1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${leave.startDate.toLocal().toString().split(' ')[0]} - ${leave.endDate.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.supervisor_account_outlined,
                          size: 18,
                          color: Color(0xFF0632A1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSupervisorName(leave.supervisor),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatusPath(leave),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(delay: (300 + index * 100).ms);
  }
}