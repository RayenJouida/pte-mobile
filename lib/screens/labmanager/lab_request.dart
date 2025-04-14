import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/virtualization_env_service.dart';
import '../../models/virtualization_env.dart';
import 'requester_info.dart';

class LabRequestsScreen extends StatefulWidget {
  const LabRequestsScreen({Key? key}) : super(key: key);

  @override
  _LabRequestsScreenState createState() => _LabRequestsScreenState();
}

class _LabRequestsScreenState extends State<LabRequestsScreen> {
  List<VirtualizationEnv> _labRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Filtering, sorting, and pagination state
  String _selectedStatusFilter = 'All';
  String _selectedRoleFilter = 'All';
  bool _sortAlphabetically = false;
  int _currentPage = 0;
  final int _itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    _fetchLabRequests();
  }

  Future<void> _fetchLabRequests() async {
    try {
      final requests =
          await VirtualizationEnvService().getAllVirtualizationEnvs();
      setState(() {
        _labRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load lab requests: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<String> getRoleOptions() {
    var roles = _labRequests.map((e) => e.type).toSet().toList();
    roles.sort();
    return roles;
  }

  @override
  Widget build(BuildContext context) {
    // Apply search, status, and role filters.
    List<VirtualizationEnv> filteredRequests = _labRequests.where((request) {
      final query = _searchQuery.toLowerCase();
      bool matchesSearch = request.firstName.toLowerCase().contains(query) ||
          request.lastName.toLowerCase().contains(query) ||
          request.type.toLowerCase().contains(query);
      bool matchesStatus = _selectedStatusFilter == 'All' ||
          request.status.toLowerCase() ==
              _selectedStatusFilter.toLowerCase();
      bool matchesRole = _selectedRoleFilter == 'All' ||
          request.type.toLowerCase() ==
              _selectedRoleFilter.toLowerCase();
      return matchesSearch && matchesStatus && matchesRole;
    }).toList();

    // Sort alphabetically if enabled.
    if (_sortAlphabetically) {
      filteredRequests.sort((a, b) {
        final nameA = "${a.firstName} ${a.lastName}";
        final nameB = "${b.firstName} ${b.lastName}";
        return nameA.compareTo(nameB);
      });
    }

    // Pagination logic
    int totalPages = (filteredRequests.length / _itemsPerPage).ceil();
    if (totalPages > 0 && _currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
    final int startIndex = _currentPage * _itemsPerPage;
    final List<VirtualizationEnv> pagedRequests =
        filteredRequests.skip(startIndex).take(_itemsPerPage).toList();

    return Scaffold(
      // Note: The Floating Action Button has been removed.
      body: SafeArea(
        // Increase the top padding to push the content down further.
        minimum: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            // Extra spacer at the top.
            const SizedBox(height: 20),
            _buildSearchBar(),
            _buildFiltersRow(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRequests.isEmpty
                      ? _buildEmptyState()
                      : _buildRequestList(pagedRequests),
            ),
            if (filteredRequests.isNotEmpty)
              _buildPaginationControls(totalPages),
            // Extra space at the bottom for visual breathing room.
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 0; // Reset pagination on new search.
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search by name or type...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    List<String> roleOptions = getRoleOptions();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status Filter Dropdown
          DropdownButton<String>(
            value: _selectedStatusFilter,
            items: ['All', 'Active', 'Declined', 'Pending']
                .map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text("Status: $status"),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatusFilter = value!;
                _currentPage = 0;
              });
            },
          ),
          // Role Filter Dropdown (using "type" as role)
          DropdownButton<String>(
            value: _selectedRoleFilter,
            items: ['All', ...roleOptions]
                .map((role) => DropdownMenuItem<String>(
                      value: role,
                      child: Text("Role: $role"),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedRoleFilter = value!;
                _currentPage = 0;
              });
            },
          ),
          // Sort toggle for A–Z
          IconButton(
            icon: Icon(
              _sortAlphabetically ? Icons.sort_by_alpha : Icons.sort,
              color: _sortAlphabetically ? Colors.blueAccent : Colors.grey,
            ),
            tooltip: "Sort Alphabetically",
            onPressed: () {
              setState(() {
                _sortAlphabetically = !_sortAlphabetically;
                _currentPage = 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No lab requests found.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<VirtualizationEnv> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildLabRequestCard(request);
      },
    );
  }

  Widget _buildLabRequestCard(VirtualizationEnv request) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(request.status).withOpacity(0.2),
          child: Icon(Icons.person, color: _getStatusColor(request.status)),
        ),
        title: Text(
          '${request.firstName} ${request.lastName}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Lab Type: ${request.type}',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        trailing: Chip(
          label: Text(request.status,
              style: const TextStyle(color: Colors.white)),
          backgroundColor: _getStatusColor(request.status),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequesterInfoScreen(request: request),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // "Previous" button.
          ElevatedButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Previous"),
          ),
          const SizedBox(width: 20),
          // Page indicator.
          Text(
            "Page ${_currentPage + 1} of $totalPages",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(width: 20),
          // "Next" button.
          ElevatedButton(
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}
