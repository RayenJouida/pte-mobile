import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../services/user_service.dart';
import 'package:country_picker/country_picker.dart';
import '../config/env.dart';
import 'package:file_picker/file_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
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
  late TextEditingController _teamLeaderController;
  late TextEditingController _departementController;
  late TextEditingController _cvController;

  final UserService _userService = UserService();
  final List<String> _maritalStatus = ['Single', 'Married', 'Divorced'];
  final List<String> _departements = ['Administration', 'System', 'Networking', 'Cyber Security', 'Development'];
  String? _selectedNationality;
  String? _selectedMaritalStatus;
  String? _selecteddepartement;
  File? _imageFile;
  File? _cvFile;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

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
    _teamLeaderController = TextEditingController(text: widget.user.teamLeader == true ? "Yes" : "No");
    _departementController = TextEditingController(text: widget.user.departement);
    _cvController = TextEditingController(text: widget.user.cv != null ? "CV Uploaded" : "No CV");

    // Set initial dropdown values
    _selectedNationality = widget.user.nationality;
    _selectedMaritalStatus = widget.user.fs;
    _selecteddepartement = widget.user.departement;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Select Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: FontAwesomeIcons.camera,
                  label: 'Camera',
                  onTap: () => _pickImageFromSource(ImageSource.camera),
                ),
                _buildImageSourceOption(
                  icon: FontAwesomeIcons.images,
                  label: 'Gallery',
                  onTap: () => _pickImageFromSource(ImageSource.gallery),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Color(0xFF0632A1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF0632A1).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF0632A1), size: 24),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF0632A1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _cvFile = File(result.files.single.path!);
        _cvController.text = _cvFile!.path.split('/').last;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
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
          "teamLeader": _teamLeaderController.text == "Yes" ? true : false,
          "departement": _selecteddepartement,
        };

        await _userService.updateUser(
          widget.user.id!,
          updatedUser,
          imageFile: _imageFile,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Failed to update profile: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF0632A1), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF0632A1),
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateProfile,
              icon: _isLoading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.save, size: 18),
              label: Text(_isLoading ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0632A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _isLoading
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
                    'Updating profile...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image Section
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(bottom: 32),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF0632A1), Color(0xFF3D6DFF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF0632A1).withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : (widget.user.image != null && widget.user.image!.isNotEmpty)
                                            ? NetworkImage('${Env.userImageBaseUrl}${widget.user.image!}')
                                            : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                    child: _imageFile == null && (widget.user.image == null || widget.user.image!.isEmpty)
                                        ? Icon(Icons.camera_alt, size: 32, color: Colors.white.withOpacity(0.8))
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0632A1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    FontAwesomeIcons.camera,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information', FontAwesomeIcons.user),
                      _buildCard([
                        _buildRow([
                          _buildTextField(_firstNameController, 'First Name', FontAwesomeIcons.user),
                          _buildTextField(_lastNameController, 'Last Name', FontAwesomeIcons.user),
                        ]),
                        _buildRow([
                          _buildTextField(_emailController, 'Email', FontAwesomeIcons.envelope, readOnly: true),
                          _buildTextField(_phoneController, 'Phone', FontAwesomeIcons.phone),
                        ]),
                        _buildCountryPicker(),
                        _buildDropdown('Marital Status', _selectedMaritalStatus, _maritalStatus, (value) {
                          setState(() => _selectedMaritalStatus = value);
                        }, icon: FontAwesomeIcons.heart),
                      ]),

                      // Professional Information Section
                      _buildSectionHeader('Professional Information', FontAwesomeIcons.briefcase),
                      _buildCard([
                        _buildDropdown('Department', _selecteddepartement, _departements, (value) {
                          setState(() => _selecteddepartement = value);
                        }, icon: FontAwesomeIcons.building),
                        _buildTextField(_experienceController, 'Experience (years)', FontAwesomeIcons.briefcase),
                        _buildSwitchCard('Driving License', FontAwesomeIcons.car, _drivingLicenseController),
                        _buildSwitchCard('Team Leader', FontAwesomeIcons.users, _teamLeaderController),
                      ]),

                      // Additional Information Section
                      _buildSectionHeader('Additional Information', FontAwesomeIcons.infoCircle),
                      _buildCard([
                        _buildTextField(_bioController, 'Bio', FontAwesomeIcons.infoCircle, maxLines: 3),
                        _buildTextField(_addressController, 'Address', FontAwesomeIcons.mapMarkerAlt),
                      ]),

                      // Social Links Section
                      _buildSectionHeader('Social Links', FontAwesomeIcons.link),
                      _buildCard([
                        _buildRow([
                          _buildTextField(_githubController, 'GitHub', FontAwesomeIcons.github),
                          _buildTextField(_linkedinController, 'LinkedIn', FontAwesomeIcons.linkedin),
                        ]),
                        _buildCVField(),
                      ]),

                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16, top: 24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF0632A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF0632A1), size: 18),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildCountryPicker() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _nationalityController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Nationality',
          prefixIcon: Icon(FontAwesomeIcons.flag, color: Color(0xFF0632A1), size: 18),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Color(0xFF0632A1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF0632A1), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: children.map((child) => Expanded(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: child,
        ))).toList(),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool readOnly = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF0632A1), size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF0632A1), width: 2),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
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

  Widget _buildDropdown(String label, String? value, List<String> items, void Function(String?) onChanged, {IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Color(0xFF0632A1), size: 18) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF0632A1), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildSwitchCard(String title, IconData icon, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF0632A1), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Switch(
            value: controller.text == "Yes",
            onChanged: (value) {
              setState(() {
                controller.text = value ? "Yes" : "No";
              });
            },
            activeColor: Color(0xFF0632A1),
          ),
        ],
      ),
    );
  }

  Widget _buildCVField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(FontAwesomeIcons.filePdf, color: Colors.red, size: 20),
        ),
        title: Text(
          'CV (PDF only)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            _cvFile != null 
                ? _cvFile!.path.split('/').last 
                : (widget.user.cv != null ? 'CV Uploaded' : 'No CV selected'),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF0632A1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            FontAwesomeIcons.upload,
            color: Color(0xFF0632A1),
            size: 16,
          ),
        ),
        onTap: _pickCV,
      ),
    );
  }
}