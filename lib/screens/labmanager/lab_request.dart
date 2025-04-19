import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pte_mobile/screens/labmanager/requester_info.dart';
import 'package:quickalert/quickalert.dart';
import 'package:pte_mobile/models/virtualization_env.dart';
import 'package:pte_mobile/services/virtualization_env_service.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:pte_mobile/widgets/lab_manager_navbar.dart';
import 'package:provider/provider.dart';
import 'package:pte_mobile/providers/notification_provider.dart';

class LabRequestsScreen extends StatefulWidget {
  const LabRequestsScreen({Key? key}) : super(key: key);

  @override
  _LabRequestsScreenState createState() => _LabRequestsScreenState();
}

class _LabRequestsScreenState extends State<LabRequestsScreen> {
  List<VirtualizationEnv> _labRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedRoleFilter = 'All';
  bool _sortAlphabetically = false;
  int _currentPage = 0;
  final int _itemsPerPage = 6;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchLabRequests();
  }

  Future<void> _fetchLabRequests() async {
    try {
      final requests = await VirtualizationEnvService().getAllVirtualizationEnvs();
      setState(() {
        _labRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load lab requests: $e',
        confirmBtnColor: lightColorScheme.primary,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'declined':
        return lightColorScheme.error;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<String> getRoleOptions() {
    var roles = _labRequests.map((e) => e.type).toSet().toList();
    roles.sort();
    return ['All', ...roles];
  }

  void _onTabChange(int index) {
    if (index != _currentIndex) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    List<VirtualizationEnv> filteredRequests = _labRequests.where((request) {
      final query = _searchQuery.toLowerCase();
      bool matchesSearch = request.firstName.toLowerCase().contains(query) ||
          request.lastName.toLowerCase().contains(query) ||
          request.type.toLowerCase().contains(query);
      bool matchesStatus = _selectedStatusFilter == 'All' ||
          request.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
      bool matchesRole = _selectedRoleFilter == 'All' ||
          request.type.toLowerCase() == _selectedRoleFilter.toLowerCase();
      return matchesSearch && matchesStatus && matchesRole;
    }).toList();

    if (_sortAlphabetically) {
      filteredRequests.sort((a, b) {
        final nameA = "${a.firstName} ${a.lastName}";
        final nameB = "${b.firstName} ${b.lastName}";
        return nameA.compareTo(nameB);
      });
    }

    int totalPages = (filteredRequests.length / _itemsPerPage).ceil();
    if (totalPages > 0 && _currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
    final int startIndex = _currentPage * _itemsPerPage;
    final List<VirtualizationEnv> pagedRequests =
        filteredRequests.skip(startIndex).take(_itemsPerPage).toList();

    return Scaffold(
      backgroundColor: lightColorScheme.surfaceVariant,
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            decoration: BoxDecoration(
              color: lightColorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Lab Requests',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: lightColorScheme.onPrimary,
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
                const SizedBox(height: 16),
                _buildSearchBar().animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
              ],
            ),
          ),
          
          // Filters Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: _buildFiltersRow().animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
          ),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: lightColorScheme.primary,
                      strokeWidth: 2,
                    ),
                  )
                : filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: lightColorScheme.primary,
                        onRefresh: _fetchLabRequests,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: pagedRequests.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildLabRequestCard(pagedRequests[index])
                                .animate()
                                .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                                .slideY(begin: 0.1, end: 0, delay: (50 * index).ms);
                          },
                        ),
                      ),
          ),
          
          // Pagination Controls
          if (filteredRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPaginationControls(totalPages)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(delay: 500.ms),
            ),
        ],
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return LabManagerNavbar(
            currentIndex: _currentIndex,
            onTabChange: _onTabChange,
            unreadMessageCount: notificationProvider.unreadMessageCount,
            unreadNotificationCount: notificationProvider.unreadActivityCount,
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: lightColorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() {
            _searchQuery = value;
            _currentPage = 0;
          }),
          decoration: InputDecoration(
            hintText: 'Search requests...',
            hintStyle: GoogleFonts.poppins(
              color: lightColorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: Icon(Icons.search, color: lightColorScheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.poppins(color: lightColorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    List<String> roleOptions = getRoleOptions();
    return Row(
      children: [
        // Status Filter
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedStatusFilter,
            items: ['All', 'Active', 'Pending', 'Declined'],
            label: 'Status',
            onChanged: (value) => setState(() {
              _selectedStatusFilter = value!;
              _currentPage = 0;
            }),
          ),
        ),
        const SizedBox(width: 8),
        
        // Role Filter
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedRoleFilter,
            items: roleOptions,
            label: 'Type',
            onChanged: (value) => setState(() {
              _selectedRoleFilter = value!;
              _currentPage = 0;
            }),
          ),
        ),
        const SizedBox(width: 8),
        
        // Sort Button
        Container(
          decoration: BoxDecoration(
            color: _sortAlphabetically 
                ? lightColorScheme.primary.withOpacity(0.2)
                : lightColorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.sort_by_alpha,
              color: _sortAlphabetically 
                  ? lightColorScheme.primary 
                  : lightColorScheme.onSurface.withOpacity(0.6),
            ),
            onPressed: () => setState(() {
              _sortAlphabetically = !_sortAlphabetically;
              _currentPage = 0;
            }),
            tooltip: "Sort alphabetically",
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: lightColorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: lightColorScheme.surface,
        style: GoogleFonts.poppins(
          color: lightColorScheme.onSurface,
          fontSize: 14,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text('$label: $item'),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: lightColorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No requests found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: lightColorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: lightColorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchLabRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: lightColorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Refresh',
              style: GoogleFonts.poppins(
                color: lightColorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabRequestCard(VirtualizationEnv request) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequesterInfoScreen(request: request),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: lightColorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 8,
              height: 60,
              decoration: BoxDecoration(
                color: _getStatusColor(request.status),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.firstName} ${request.lastName}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: lightColorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.type,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: lightColorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(request.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(request.status).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                request.status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(request.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Button
        IconButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          icon: Icon(Icons.chevron_left),
          color: _currentPage > 0
              ? lightColorScheme.primary
              : lightColorScheme.onSurface.withOpacity(0.3),
          splashRadius: 20,
        ),
        
        // Page Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: lightColorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentPage + 1} / $totalPages',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: lightColorScheme.primary,
            ),
          ),
        ),
        
        // Next Button
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          icon: Icon(Icons.chevron_right),
          color: _currentPage < totalPages - 1
              ? lightColorScheme.primary
              : lightColorScheme.onSurface.withOpacity(0.3),
          splashRadius: 20,
        ),
      ],
    );
  }
}