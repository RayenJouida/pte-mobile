import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/leave_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _userId;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isProcessing = false;

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 4;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

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
    final token = prefs.getString('authToken');
    final role = prefs.getString('userRole');
    final userId = prefs.getString('userId');

    if (token == null || userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _userRole = role;
      _userId = userId;
    });
    await _fetchData();
  }

  Future<void> _logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('authToken');
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _fetchData() async {
    try {
      List<Leave> leaveRequests;
      if (_userRole == 'ADMIN') {
        leaveRequests = await _leaveService.fetchAllLeaves();
      } else {
        if (_userId != null) {
          leaveRequests = await _leaveService.fetchWorkerRequests(_userId!);
        } else {
          throw Exception('No user ID found');
        }
      }
      final users = await _userService.fetchUsers();
      if (mounted) {
        setState(() {
          _leaveRequests = leaveRequests
            ..sort((a, b) => b.localCreationTime.compareTo(a.localCreationTime));
          _filteredLeaveRequests = List.from(_leaveRequests);
          _supervisors = users
              .map((user) => User.fromJson(user))
              .where((user) => user.roles.contains('ADMIN') || user.roles.contains('LAB-MANAGER'))
              .toList();
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (e.toString().contains('Not authorized') || e.toString().contains('401')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
          await _logoutAndRedirect();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load data: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<String> _getSupervisorName(User? supervisor) async {
    if (supervisor == null) return 'N/A';
    if (supervisor.firstName == 'Unknown' && supervisor.id != 'unknown') {
      final userData = await _userService.getUserById(supervisor.id);
      if (userData != null) {
        final user = User.fromJson(userData);
        return '${user.firstName} ${user.lastName}';
      }
    }
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
            leave.endDate.toString().toLowerCase().contains(query) ||
            (leave.note ?? '').toLowerCase().contains(query) ||
            (leave.code ?? '').toLowerCase().contains(query) ||
            leave.fullName.toLowerCase().contains(query) ||
            leave.email.toLowerCase().contains(query);

        return matchesStatus && matchesSearch;
      }).toList()
        ..sort((a, b) => b.localCreationTime.compareTo(a.localCreationTime));
      _currentPage = 1;
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade600;
      case 'Declined':
        return Colors.red.shade600;
      case 'Pending 1/2':
      case 'Pending':
      case 'Pending 0/2':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _handleApproval(String leaveId, bool approve) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final leaveIndex = _leaveRequests.indexWhere((l) => l.id == leaveId);
      if (leaveIndex == -1) {
        throw Exception('Leave request not found');
      }

      Leave currentLeave = _leaveRequests[leaveIndex];
      if (currentLeave.status == 'Approved' || currentLeave.status == 'Declined') {
        _showStatusAlert('This request has already been processed.');
        return;
      }

      if (_userRole == 'ADMIN') {
        if (approve) {
          await _leaveService.managerAccept(leaveId);
          setState(() {
            _leaveRequests[leaveIndex] = currentLeave.copyWith(status: 'Approved', managerAccepted: true);
            _filteredLeaveRequests = List.from(_leaveRequests);
          });
        } else {
          await _leaveService.managerDecline(leaveId);
          setState(() {
            _leaveRequests[leaveIndex] = currentLeave.copyWith(status: 'Declined', managerAccepted: false);
            _filteredLeaveRequests = List.from(_leaveRequests);
          });
        }
      } else {
        if (approve) {
          if (currentLeave.status != 'Pending 0/2') {
            _showStatusAlert('Only Pending 0/2 requests can be approved by you.');
            return;
          }
          setState(() {
            _leaveRequests[leaveIndex] = currentLeave.copyWith(status: 'Pending 1/2', supervisorAccepted: true);
            _filteredLeaveRequests = List.from(_leaveRequests);
          });
          await _leaveService.workerAccept(leaveId);
          if (_userId != null) {
            final updatedLeaves = await _leaveService.fetchWorkerRequests(_userId!);
            final updatedLeave = updatedLeaves.firstWhere(
              (l) => l.id == leaveId,
              orElse: () => currentLeave,
            );
            if (updatedLeave.status == 'Pending' && updatedLeave.supervisorAccepted == true) {
              setState(() {
                _leaveRequests[leaveIndex] = updatedLeave;
                _filteredLeaveRequests = List.from(_leaveRequests);
              });
            } else {
              setState(() {
                _leaveRequests[leaveIndex] = currentLeave.copyWith(status: 'Pending', supervisorAccepted: true);
                _filteredLeaveRequests = List.from(_leaveRequests);
              });
              await _fetchData();
              _showStatusAlert('Update applied locally. Sync completed.');
            }
          }
        } else {
          await _leaveService.workerDecline(leaveId);
          setState(() {
            _leaveRequests[leaveIndex] = currentLeave.copyWith(status: 'Declined', supervisorAccepted: false);
            _filteredLeaveRequests = List.from(_leaveRequests);
          });
        }
      }

      await _fetchData();
      _showStatusAlert(approve ? 'Leave request approved' : 'Leave request declined');
    } catch (e) {
      _showStatusAlert('Failed to process request: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadCertif(String? certifUrl) async {
    if (certifUrl != null && certifUrl.isNotEmpty) {
      final uri = Uri.parse(certifUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showStatusAlert('Could not open certificate link');
      }
    }
  }

  void _showLeaveDetailsDialog(BuildContext context, Leave leave) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dialogWidth = isSmallScreen ? screenSize.width * 0.9 : 550.0;
    final maxDialogHeight = screenSize.height * 0.85;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 16 : 24,
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.type,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Code: ${leave.code ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(dialogContext),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Section
                      _buildInfoCard(
                        title: 'Request Details',
                        icon: Icons.info_outline,
                        children: [
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Date Range',
                            value: '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Applicant',
                            value: leave.fullName,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: leave.email,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.supervisor_account,
                            label: 'Supervisor',
                            valueWidget: FutureBuilder<String>(
                              future: _getSupervisorName(leave.supervisor),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Text(
                                    'Loading...',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 15,
                                      color: Colors.grey.shade800,
                                    ),
                                  );
                                }
                                return Text(
                                  snapshot.data ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    color: Colors.grey.shade800,
                                  ),
                                );
                              },
                            ),
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                        isSmallScreen: isSmallScreen,
                      ),
                      // Status Section
                      SizedBox(height: 20),
                      _buildInfoCard(
                        title: 'Approval Status',
                        icon: Icons.check_circle_outline,
                        children: [
                          _buildInfoRow(
                            icon: Icons.info,
                            label: 'Status',
                            value: leave.status ?? 'Pending',
                            valueColor: _getStatusColor(leave.status),
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.supervisor_account,
                            label: 'Supervisor Approval',
                            value: leave.supervisorAccepted != null
                                ? leave.supervisorAccepted! ? 'Approved' : 'Declined'
                                : 'Pending',
                            valueColor: leave.supervisorAccepted == true
                                ? Colors.green.shade600
                                : leave.supervisorAccepted == false
                                    ? Colors.red.shade600
                                    : Colors.orange.shade600,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.manage_accounts,
                            label: 'Manager Approval',
                            value: leave.managerAccepted != null
                                ? leave.managerAccepted! ? 'Approved' : 'Declined'
                                : 'Pending',
                            valueColor: leave.managerAccepted == true
                                ? Colors.green.shade600
                                : leave.managerAccepted == false
                                    ? Colors.red.shade600
                                    : Colors.orange.shade600,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                        isSmallScreen: isSmallScreen,
                      ),
                      // Note Section
                      if (leave.note != null && leave.note!.isNotEmpty) ...[
                        SizedBox(height: 20),
                        _buildInfoCard(
                          title: 'Additional Notes',
                          icon: Icons.note,
                          children: [
                            Text(
                              leave.note!,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                color: Colors.grey.shade800,
                                height: 1.5,
                              ),
                            ),
                          ],
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                      // Certificate Section
                      if (leave.certif != null && leave.certif!.isNotEmpty) ...[
                        SizedBox(height: 20),
                        _buildInfoCard(
                          title: 'Certificate',
                          icon: Icons.download,
                          children: [
                            GestureDetector(
                              onTap: () => _downloadCertif(leave.certif),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.download,
                                    size: isSmallScreen ? 18 : 20,
                                    color: Color(0xFF0632A1),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Download Certificate',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 15,
                                      color: Color(0xFF0632A1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Action Buttons
              if (_userRole != 'ADMIN' && leave.status == 'Pending 1/2' && leave.supervisorAccepted == true)
                SizedBox.shrink()
              else
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                        ),
                      ),
                      if (leave.status != 'Approved' && leave.status != 'Declined' && !_isProcessing) ...[
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _handleApproval(leave.id, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16 : 20,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Approve',
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _handleApproval(leave.id, false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16 : 20,
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Decline',
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(delay: 200.ms),
    );
  }

  void _showStatusAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0632A1), Color(0xFF2E5CDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Status Update',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFF0632A1),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF0632A1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: isSmallScreen ? 18 : 20,
                    color: Color(0xFF0632A1),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0632A1),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
    required bool isSmallScreen,
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
          child: Icon(
            icon,
            size: isSmallScreen ? 16 : 18,
            color: Color(0xFF0632A1),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 4),
              valueWidget ??
                  Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      color: valueColor ?? Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPath(Leave leave) {
    final List<String> stages;
    int currentStage = 0;
    if (leave.status == 'Pending 0/2' || (leave.status == 'Pending 1/2' && !leave.supervisorAccepted!)) {
      stages = ['Pending 0/2', 'Pending 1/2', 'Final'];
      if (leave.status == 'Pending 0/2') {
        currentStage = 0;
      } else if (leave.status == 'Pending 1/2') {
        currentStage = 1;
      } else {
        currentStage = 2;
      }
    } else {
      stages = ['Pending 1/2', 'Pending', 'Final'];
      if (leave.status == 'Pending 1/2' && leave.supervisorAccepted!) {
        currentStage = 0;
      } else if (leave.status == 'Pending') {
        currentStage = 1;
      } else {
        currentStage = 2;
      }
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16, horizontal: isSmallScreen ? 8 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stages.length, (index) {
          bool isActive = index <= currentStage;
          bool isLast = index == stages.length - 1;
          bool isApproved = leave.status == 'Approved' && isLast;
          bool isRejected = leave.status == 'Declined' && isLast;

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
                              ? 'Supervisor approved on ${_formatDate(leave.startDate)}'
                              : 'Awaiting supervisor approval';
                        } else if (index == 1) {
                          if (stages[1] == 'Pending 1/2') {
                            message = leave.supervisorAccepted == true
                                ? 'Supervisor approved on ${_formatDate(leave.startDate)}'
                                : 'Awaiting manager approval';
                          } else {
                            message = leave.managerAccepted == true
                                ? 'Manager approved on ${_formatDate(leave.endDate)}'
                                : 'Awaiting manager approval';
                          }
                        } else {
                          message = leave.status == 'Approved'
                              ? 'Leave approved'
                              : leave.status == 'Declined'
                                  ? 'Leave rejected'
                                  : 'Final status pending';
                        }
                        _showStatusAlert(message);
                      },
                      child: Container(
                        width: isSmallScreen ? 36 : 40,
                        height: isSmallScreen ? 36 : 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? const Color(0xFF0632A1) : Colors.grey.shade200,
                          border: Border.all(
                            color: isActive ? const Color(0xFF0632A1) : Colors.grey.shade400,
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
                                  size: isSmallScreen ? 18 : 20,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : 16,
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
                        color: isActive ? const Color(0xFF0632A1) : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (index < stages.length - 1)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
                      child: Container(
                        height: isSmallScreen ? 3 : 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isActive ? const Color(0xFF0632A1) : Colors.grey.shade300,
                              index + 1 <= currentStage ? const Color(0xFF0632A1) : Colors.grey.shade300,
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

    if (totalItems == 0) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSmallScreen ? 12 : 16),
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
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
                    color: _currentPage > 1 ? const Color(0xFF0632A1) : Colors.grey.shade400,
                    size: isSmallScreen ? 18 : 22,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Row(
                children: List.generate(totalPages, (index) {
                  final pageNumber = index + 1;
                  final isActive = _currentPage == pageNumber;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentPage = pageNumber;
                        });
                        _scrollController.jumpTo(0);
                      },
                      child: Container(
                        width: isSmallScreen ? 28 : 32,
                        height: isSmallScreen ? 28 : 32,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF0632A1) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? const Color(0xFF0632A1) : Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
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
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
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
                    color: _currentPage < totalPages ? const Color(0xFF0632A1) : Colors.grey.shade400,
                    size: isSmallScreen ? 18 : 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _userRole == 'ADMIN'
          ? AdminSidebar(
              currentIndex: 15,
              onTabChange: (index) {
                setState(() {});
              },
            )
          : null,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0632A1),
                strokeWidth: 3,
              ),
            )
          : _userId == null
              ? Center(
                  child: Text(
                    'Error: User not authenticated.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      pinned: true,
                      expandedHeight: isSmallScreen ? 100 : 120,
                      automaticallyImplyLeading: false,
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + (isSmallScreen ? 8 : 12),
                              bottom: isSmallScreen ? 12 : 16,
                              left: padding,
                              right: padding,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF0632A1),
                                  Color(0xFF0632A1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (_userRole != 'ADMIN')
                                  IconButton(
                                    icon: Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: isSmallScreen ? 24 : 28,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  )
                                else
                                  Builder(
                                    builder: (context) => IconButton(
                                      icon: Icon(
                                        Icons.menu,
                                        color: Colors.white,
                                        size: isSmallScreen ? 24 : 28,
                                      ),
                                      onPressed: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  _userRole == 'ADMIN' ? 'All Leave Requests' : 'Team Leave Requests',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                  onPressed: () {
                                    _fetchData();
                                  },
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms);
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: isSmallScreen ? 45 : 50,
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
                                  decoration: InputDecoration(
                                    hintText: 'Search by type, status, applicant...',
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
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Container(
                              height: isSmallScreen ? 45 : 50,
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
                                  icon: Icon(Icons.filter_list, color: Color(0xFF0632A1)),
                                  items: ['All', 'Pending 0/2', 'Pending 1/2', 'Pending', 'Approved', 'Declined'].map((status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 13 : 14,
                                            fontWeight: FontWeight.w500,
                                            color: _getStatusColor(status),
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
                        ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                            itemCount: _getPaginatedLeaves().length,
                            itemBuilder: (context, index) {
                              final leave = _getPaginatedLeaves()[index];
                              return _buildLeaveCard(leave, index);
                            },
                          ),
                          _buildPaginationControls(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLeaveCard(Leave leave, int index) {
    final statusColor = _getStatusColor(leave.status);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showLeaveDetailsDialog(context, leave);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: Color(0xFF0632A1).withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF0632A1).withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.event,
                            color: Color(0xFF0632A1),
                            size: isSmallScreen ? 20 : 22,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.type,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0632A1),
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Code: ${leave.code ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: isSmallScreen ? 5 : 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                      ),
                      child: Text(
                        leave.status ?? 'Pending',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: isSmallScreen ? 16 : 18,
                      color: Color(0xFF0632A1),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        'Applicant: ${leave.fullName}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: isSmallScreen ? 16 : 18,
                          color: Color(0xFF0632A1),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.supervisor_account_outlined,
                          size: isSmallScreen ? 16 : 18,
                          color: Color(0xFF0632A1),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        FutureBuilder<String>(
                          future: _getSupervisorName(leave.supervisor),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            return Text(
                              snapshot.data ?? 'N/A',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildStatusPath(leave),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(delay: (300 + index * 100).ms);
  }
}