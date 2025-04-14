import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../services/user_service.dart';
import 'package:country_picker/country_picker.dart';
import '../config/env.dart'; // Added this import

class EditProfileScreen extends StatefulWidget {
  final User user;

  EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _nationalityController;
  late TextEditingController _fsController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  late TextEditingController _experienceController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _drivingLicenseController;

  final UserService _userService = UserService();
  final List<String> _maritalStatus = ['Single', 'Married', 'Divorced'];
  String? _selectedNationality;
  String? _selectedMaritalStatus;
  File? _imageFile; // To store the selected image file
  bool _isLoading = false; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _nationalityController = TextEditingController(text: widget.user.nationality);
    _fsController = TextEditingController(text: widget.user.fs);
    _bioController = TextEditingController(text: widget.user.bio);
    _addressController = TextEditingController(text: widget.user.address);
    _experienceController = TextEditingController(text: widget.user.experience?.toString());
    _githubController = TextEditingController(text: widget.user.github);
    _linkedinController = TextEditingController(text: widget.user.linkedin);
    _drivingLicenseController = TextEditingController(text: widget.user.drivingLicense == true ? "Yes" : "No");
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        final updatedUser = {
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "email": _emailController.text,
          "phone": _phoneController.text,
          "nationality": _selectedNationality,
          "fs": _selectedMaritalStatus,
          "bio": _bioController.text,
          "address": _addressController.text,
          "experience": int.tryParse(_experienceController.text),
          "github": _githubController.text,
          "linkedin": _linkedinController.text,
          "drivingLisence": _drivingLicenseController.text == "Yes" ? true : false,
        };

        // Call updateUser with or without an image
        await _userService.updateUser(
          widget.user.id!,
          updatedUser,
          imageFile: _imageFile, // Pass the selected image file
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!) // Show selected image
                            : (widget.user.image != null && widget.user.image!.isNotEmpty)
                                ? NetworkImage('${Env.userImageBaseUrl}${widget.user.image!}') // Updated to use Env
                                : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        child: _imageFile == null && (widget.user.image == null || widget.user.image!.isEmpty)
                            ? Icon(Icons.camera_alt, size: 40, color: Colors.white) // Show camera icon if no image
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildRow([
                      _buildTextField(_firstNameController, 'First Name', FontAwesomeIcons.user),
                      _buildTextField(_lastNameController, 'Last Name', FontAwesomeIcons.user),
                    ]),
                    _buildRow([
                      _buildTextField(_emailController, 'Email', FontAwesomeIcons.envelope, readOnly: true),
                      _buildTextField(_phoneController, 'Phone', FontAwesomeIcons.phone),
                    ]),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: TextFormField(
                        controller: _nationalityController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Nationality',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            showPhoneCode: false,
                            onSelect: (Country country) {
                              setState(() {
                                _selectedNationality = country.name;
                                _nationalityController.text = country.name;
                              });
                            },
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select nationality';
                          }
                          return null;
                        },
                      ),
                    ),
                    _buildDropdown('Marital Status', _selectedMaritalStatus, _maritalStatus, (value) {
                      setState(() => _selectedMaritalStatus = value);
                    }),
                    _buildTextField(_bioController, 'Bio', FontAwesomeIcons.infoCircle, maxLines: 3),
                    _buildTextField(_addressController, 'Address', FontAwesomeIcons.mapMarkerAlt),
                    _buildTextField(_experienceController, 'Experience (years)', FontAwesomeIcons.briefcase),
                    _buildRow([
                      _buildTextField(_githubController, 'GitHub', FontAwesomeIcons.github),
                      _buildTextField(_linkedinController, 'LinkedIn', FontAwesomeIcons.linkedin),
                    ]),
                    _buildDrivingLicenseField(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: children.map((child) => Expanded(child: child)).toList(),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool readOnly = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, void Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildDrivingLicenseField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            "Has Driving License",
            style: TextStyle(fontSize: 16),
          ),
          Switch(
            value: _drivingLicenseController.text == "Yes",
            onChanged: (value) {
              setState(() {
                _drivingLicenseController.text = value ? "Yes" : "No";
              });
            },
          ),
        ],
      ),
    );
  }
}