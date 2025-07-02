import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/screens/labmanager/requester_info.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/models/virtualization_env.dart';
import 'package:pte_mobile/services/virtualization_env_service.dart';
import 'package:pte_mobile/widgets/lab_manager_navbar.dart';
import 'package:provider/provider.dart';
import 'package:pte_mobile/providers/notification_provider.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabRequestsScreen extends StatefulWidget {
  const LabRequestsScreen({Key? key}) : super(key: key);

  @override
  _LabRequestsScreenState createState() => _LabRequestsScreenState();
}

class _LabRequestsScreenState extends State<LabRequestsScreen> {
  List<VirtualizationEnv> _labRequests = [];
  List<VirtualizationEnv> _filteredRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedTypeFilter = 'All';
  bool _sortAlphabetically = false;
  int _currentPage = 1;
  final int _itemsPerPage = 6;
  int _currentIndex = 1;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
    _fetchLabRequests();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Assistant';
    });
  }

  Future<void> _fetchLabRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await VirtualizationEnvService().getAllVirtualizationEnvs();
      setState(() {
        _labRequests = requests;
        _filteredRequests = List.from(requests);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching lab requests: $e');
      setState(() {
        _isLoading = false;
        _labRequests = [];
        _filteredRequests = [];
      });
    }
  }

  void _filterRequests() {
    setState(() {
      _filteredRequests = _labRequests.where((request) {
        final query = _searchQuery.toLowerCase();
        bool matchesSearch = request.firstName.toLowerCase().contains(query) ||
            request.lastName.toLowerCase().contains(query) ||
            request.type.toLowerCase().contains(query);
        bool matchesStatus = _selectedStatusFilter == 'All' ||
            request.status.toLowerCase() == _selectedStatusFilter.toLowerCase();
        bool matchesType = _selectedTypeFilter == 'All' ||
            request.type.toLowerCase() == _selectedTypeFilter.toLowerCase();
        return matchesSearch && matchesStatus && matchesType;
      }).toList();

      if (_sortAlphabetically) {
        _filteredRequests.sort((a, b) {
          final nameA = "${a.firstName} ${a.lastName}";
          final nameB = "${b.firstName} ${b.lastName}";
          return nameA.compareTo(nameB);
        });
      }

      _currentPage = 1;
    });
  }

  List<VirtualizationEnv> _getPaginatedRequests() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredRequests.sublist(
      startIndex,
      endIndex > _filteredRequests.length ? _filteredRequests.length : endIndex,
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
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'hyper-v':
        return Icons.cloud;
      case 'vmware':
        return Icons.computer;
      default:
        return Icons.device_hub;
    }
  }

  List<String> getTypeOptions() {
    var types = _labRequests.map((e) => e.type).toSet().toList();
    types.sort();
    return ['All', ...types];
  }

  void _onTabChange(int index) {
    if (index != _currentIndex) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final paginatedRequests = _getPaginatedRequests();

    int sidebarIndex = 0;
    switch (_currentUserRole) {
      case 'ADMIN':
        sidebarIndex = 12;
        break;
      case 'ENGINEER':
        sidebarIndex = 0;
        break;
      case 'LAB-MANAGER':
        sidebarIndex = 7;
        break;
      case 'ASSISTANT':
        sidebarIndex = 0;
        break;
      default:
        sidebarIndex = 0;
    }

    return Scaffold(
      drawer: _currentUserRole == 'ADMIN'
          ? AdminSidebar(
              currentIndex: sidebarIndex,
              onTabChange: (index) => setState(() {}),
            )
          : _currentUserRole == 'LAB-MANAGER'
              ? LabManagerSidebar(
                  currentIndex: sidebarIndex,
                  onTabChange: (index) => setState(() {}),
                )
              : _currentUserRole == 'ENGINEER'
                  ? EngineerSidebar(
                      currentIndex: sidebarIndex,
                      onTabChange: (index) => setState(() {}),
                    )
                  : AssistantSidebar(
                      currentIndex: sidebarIndex,
                      onTabChange: (index) => setState(() {}),
                    ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(context),
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchLabRequests,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: paginatedRequests.length,
                                itemBuilder: (context, index) {
                                  return _buildRequestCard(paginatedRequests[index])
                                      .animate()
                                      .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                                      .slideY(begin: 0.1, delay: (50 * index).ms);
                                },
                              ),
                            ),
                            _buildPaginationControls(),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const Spacer(),
              const Text(
                'Lab Requests',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchLabRequests,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have ${_filteredRequests.length} requests',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search requests...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _filterRequests();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterRequests();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 40),
            elevation: 4,
            itemBuilder: (context) {
              final typeOptions = getTypeOptions();
              return [
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'status:All',
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'All',
                        groupValue: _selectedStatusFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
                            _filterRequests();
                            Navigator.pop(context);
                          });
                        },
                      ),
                      const Text('All'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'status:Active',
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'Active',
                        groupValue: _selectedStatusFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
                            _filterRequests();
                            Navigator.pop(context);
                          });
                        },
                      ),
                      const Text('Active'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'status:Pending',
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'Pending',
                        groupValue: _selectedStatusFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
                            _filterRequests();
                            Navigator.pop(context);
                          });
                        },
                      ),
                      const Text('Pending'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'status:Declined',
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'Declined',
                        groupValue: _selectedStatusFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
                            _filterRequests();
                            Navigator.pop(context);
                          });
                        },
                      ),
                      const Text('Declined'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'type:All',
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'All',
                        groupValue: _selectedTypeFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedTypeFilter = value!;
                            _filterRequests();
                            Navigator.pop(context);
                          });
                        },
                      ),
                      const Text('All'),
                    ],
                  ),
                ),
                ...typeOptions.skip(1).map((type) => PopupMenuItem<String>(
                      value: 'type:$type',
                      child: Row(
                        children: [
                          Radio<String>(
                            value: type,
                            groupValue: _selectedTypeFilter,
                            onChanged: (value) {
                              setState(() {
                                _selectedTypeFilter = value!;
                                _filterRequests();
                                Navigator.pop(context);
                              });
                            },
                          ),
                          Text(type),
                        ],
                      ),
                    )),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'sort',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _sortAlphabetically,
                        onChanged: (value) {
                          setState(() {
                            _sortAlphabetically = value!;
                            _filterRequests();
                            Navigator.pop(context);
                          });
                        },
                      ),
                      const Text('Sort A-Z'),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (value) {
              // Handled in itemBuilder's onChanged to ensure immediate updates
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().shimmer(duration: 1.seconds);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No Requests Found' : 'No Matching Requests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchQuery.isEmpty
                  ? 'No lab requests are available.'
                  : 'No requests match your search criteria.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchLabRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Refresh Requests',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(VirtualizationEnv request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequesterInfoScreen(request: request),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 6,
                height: 120,
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              request.code,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.qr_code, 'Type', request.type),
                      _buildInfoRow(Icons.memory, 'Processor', '${request.processor} Cores'),
                      _buildInfoRow(Icons.hardware, 'RAM', '${request.ram} GB'),
                      _buildInfoRow(Icons.storage, 'Disk', '${request.disk} GB'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDateInfo(request.start, 'Start'),
                          _buildDateInfo(request.end, 'End'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(DateTime date, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${date.toLocal().toString().split(' ')[0]}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          ...List.generate(_totalPages, (index) {
            final pageNumber = index + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => setState(() => _currentPage = pageNumber),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _currentPage == pageNumber
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$pageNumber',
                    style: TextStyle(
                      color: _currentPage == pageNumber ? Colors.white : Colors.grey[700],
                      fontWeight: _currentPage == pageNumber ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  int get _totalPages => (_filteredRequests.length / _itemsPerPage).ceil();
}