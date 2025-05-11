import 'package:flutter/material.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/user_service.dart';
import '../../theme/theme.dart';

class UpdateUserScreen extends StatefulWidget {
  final User user;

  const UpdateUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UpdateUserScreenState createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends State<UpdateUserScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _nationalityController;
  late TextEditingController _departmentController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _nationalityController = TextEditingController(text: widget.user.nationality ?? '');
    _departmentController = TextEditingController(text: widget.user.department ?? '');
    _githubController = TextEditingController(text: widget.user.github ?? '');
    _linkedinController = TextEditingController(text: widget.user.linkedin ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _nationalityController.dispose();
    _departmentController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedUser = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'bio': _bioController.text.isEmpty ? null : _bioController.text,
        'nationality': _nationalityController.text.isEmpty ? null : _nationalityController.text,
        'department': _departmentController.text.isEmpty ? null : _departmentController.text,
        'github': _githubController.text.isEmpty ? null : _githubController.text,
        'linkedin': _linkedinController.text.isEmpty ? null : _linkedinController.text,
      };

      await _userService.updateUser(widget.user.id, updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User updated successfully'),
            backgroundColor: lightColorScheme.primary.withOpacity(0.85),
          ),
        );
        Navigator.pop(context, true); // Return to UserInfoScreen and trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $e'), backgroundColor: lightColorScheme.error),
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
        title: const Text('Update User'),
        centerTitle: true,
        backgroundColor: lightColorScheme.surface,
        elevation: 0,
        foregroundColor: lightColorScheme.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: lightColorScheme.primary.withOpacity(0.2)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_firstNameController, 'First Name', validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter first name';
                return null;
              }),
              const SizedBox(height: 16),
              _buildTextField(_lastNameController, 'Last Name', validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter last name';
                return null;
              }),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter email';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                return null;
              }),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Phone (Optional)'),
              const SizedBox(height: 16),
              _buildTextField(_bioController, 'Bio (Optional)', maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(_nationalityController, 'Nationality (Optional)'),
              const SizedBox(height: 16),
              _buildTextField(_departmentController, 'Department (Optional)'),
              const SizedBox(height: 16),
              _buildTextField(_githubController, 'GitHub (Optional)'),
              const SizedBox(height: 16),
              _buildTextField(_linkedinController, 'LinkedIn (Optional)'),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightColorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: lightColorScheme.onPrimary)
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: lightColorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary),
        ),
      ),
      validator: validator,
    );
  }
}