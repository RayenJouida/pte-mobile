import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/user_service.dart';
import '../../theme/theme.dart';
import '../../config/env.dart';

class UpdateUserScreen extends StatefulWidget {
  final User user;

  const UpdateUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UpdateUserScreenState createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends State<UpdateUserScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _departmentController;
  bool _isLoading = false;
  List<String> _roles = ['ADMIN', 'ENGINEER', 'ASSISTANT', 'LAB-MANAGER'];
  String? _selectedRole;
  bool _isExternal = false;
  bool? _drivingLicense;
  bool? _teamLeader;

  @override
  void initState() {
    super.initState();
    _departmentController = TextEditingController(text: widget.user.departement);
    _selectedRole = widget.user.roles.isNotEmpty ? widget.user.roles[0] : null;
    _isExternal = widget.user.external ?? false;
    _drivingLicense = widget.user.drivingLicense;
    _teamLeader = widget.user.teamLeader;
  }

  @override
  void dispose() {
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedUser = {
        'departement': _departmentController.text.isEmpty ? null : _departmentController.text,
        'roles': [_selectedRole],
        'external': _isExternal,
        'drivingLicense': _drivingLicense,
        'teamLeader': _teamLeader,
      };

      await _userService.updateUser(widget.user.id, updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('User updated successfully'),
              ],
            ),
            backgroundColor: lightColorScheme.primary.withOpacity(0.85),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to update user: $e')),
              ],
            ),
            backgroundColor: lightColorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update User',
          style: TextStyle(color: lightColorScheme.onPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: lightColorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: lightColorScheme.onPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightColorScheme.primary.withOpacity(0.05),
              lightColorScheme.background,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // User Avatar Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: lightColorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        widget.user.image != null
                            ? '${Env.userImageBaseUrl}${widget.user.image}'
                            : 'https://ui-avatars.com/api/?name=${widget.user.firstName}+${widget.user.lastName}&background=${lightColorScheme.primary.value.toRadixString(16).substring(2)}&color=fff',
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.user.firstName} ${widget.user.lastName}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: lightColorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: lightColorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Form Card
              Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: lightColorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Personal Information', Icons.person_outline),
                        SizedBox(height: 20),
                        
                        _buildDepartmentDropdown(),
                        SizedBox(height: 32),
                        
                        _buildSectionHeader('Professional Details', Icons.work_outline),
                        SizedBox(height: 20),
                        
                        _buildRoleDropdown(),
                        SizedBox(height: 32),
                        
                        _buildSectionHeader('Settings', Icons.settings_outlined),
                        SizedBox(height: 20),
                        
                        _buildToggleCard('External User', 'Mark as external contractor', Icons.business_center_outlined, _isExternal, (value) => setState(() => _isExternal = value)),
                        SizedBox(height: 12),
                        
                        _buildToggleCard('Driving License', 'Has valid driving license', Icons.drive_eta_outlined, _drivingLicense ?? false, (value) => setState(() => _drivingLicense = value)),
                        SizedBox(height: 12),
                        
                        _buildToggleCard('Team Leader', 'Leadership responsibilities', Icons.supervisor_account_outlined, _teamLeader ?? false, (value) => setState(() => _teamLeader = value)),
                        SizedBox(height: 32),
                        
                        // Save Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lightColorScheme.primary,
                              foregroundColor: lightColorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: lightColorScheme.primary.withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: lightColorScheme.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Updating...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightColorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: lightColorScheme.primary, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: lightColorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    final departments = ['Administration', 'System', 'Networking', 'Cyber Security', 'Development'];
    return DropdownButtonFormField<String>(
      value: _departmentController.text.isEmpty ? null : _departmentController.text,
      hint: Text('Select department', style: TextStyle(color: lightColorScheme.onSurfaceVariant)),
      icon: Icon(Icons.arrow_drop_down, color: lightColorScheme.primary),
      decoration: InputDecoration(
        labelText: 'Department',
        labelStyle: TextStyle(color: lightColorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.domain_outlined, color: lightColorScheme.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        filled: true,
        fillColor: lightColorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: lightColorScheme.onSurface, fontSize: 16),
      onChanged: (String? newValue) {
        setState(() {
          _departmentController.text = newValue ?? '';
        });
      },
      items: departments.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a department' : null,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      hint: Text('Select role', style: TextStyle(color: lightColorScheme.onSurfaceVariant)),
      icon: Icon(Icons.arrow_drop_down, color: lightColorScheme.primary),
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: TextStyle(color: lightColorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.assignment_ind_outlined, color: lightColorScheme.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        filled: true,
        fillColor: lightColorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: lightColorScheme.onSurface, fontSize: 16),
      onChanged: (String? newValue) {
        setState(() {
          _selectedRole = newValue;
        });
      },
      items: _roles.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }

  Widget _buildToggleCard(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightColorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightColorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightColorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: lightColorScheme.primary, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: lightColorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: lightColorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: lightColorScheme.primary,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}