// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ManageProfilePage extends StatefulWidget {
  const ManageProfilePage({super.key});

  @override
  _ManageProfilePageState createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> {
  final DatabaseReference _teacherRef = FirebaseDatabase.instance.ref().child('Teacher');
  final User? _user = FirebaseAuth.instance.currentUser;

  // Define TextEditingControllers for each field
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _fullName = '';
  final _formKey = GlobalKey<FormState>();

  // Add a boolean to track if the user wants to change their password
  bool _isChangingPassword = false;

  // Add state variables for validation errors and password visibility
  String? _passwordError;
  String? _emailError;
  String? _icError;
  String? _currentPasswordError;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Add validation functions
  bool _validateCurrentPassword(String password) {
    if (password.isEmpty) {
      setState(() => _currentPasswordError = 'Current password is required');
      return false;
    }
    setState(() => _currentPasswordError = null);
    return true;
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters long');
      return false;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() => _passwordError = 'Password must contain at least one uppercase letter');
      return false;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      setState(() => _passwordError = 'Password must contain at least one lowercase letter');
      return false;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      setState(() => _passwordError = 'Password must contain at least one special character');
      return false;
    }
    setState(() => _passwordError = null);
    return true;
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return false;
    }
    
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      return false;
    }
    
    setState(() => _emailError = null);
    return true;
  }

  bool _validateIC(String ic) {
    ic = ic.replaceAll(RegExp(r'[-\s]'), '');
    
    if (ic.length != 12) {
      setState(() => _icError = 'IC number must be 12 digits');
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(ic)) {
      setState(() => _icError = 'IC number must contain only numbers');
      return false;
    }

    int year = int.parse(ic.substring(0, 2));
    int month = int.parse(ic.substring(2, 4));
    int day = int.parse(ic.substring(4, 6));

    year += (year >= 0 && year <= DateTime.now().year % 100) ? 2000 : 1900;

    try {
      final date = DateTime(year, month, day);
      if (date.isAfter(DateTime.now())) {
        setState(() => _icError = 'Invalid date of birth');
        return false;
      }
    } catch (e) {
      setState(() => _icError = 'Invalid date of birth');
      return false;
    }

    int stateCode = int.parse(ic.substring(6, 8));
    List<int> validStateCodes = [
      01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 21, 22, 23, 24
    ];
    if (!validStateCodes.contains(stateCode)) {
      setState(() => _icError = 'Invalid state code');
      return false;
    }

    setState(() => _icError = null);
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    if (_user != null) {
      DatabaseEvent event = await _teacherRef.child(_user.uid).once();
      DataSnapshot snapshot = event.snapshot; // Access the snapshot from the DatabaseEvent
      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;
        setState(() {
          _fullName = data['fullName']?.toString() ?? '';
          _fullNameController.text = _fullName;
          _icNumberController.text = data['icNumber']?.toString() ?? ''; // Populate IC Number
          _emailController.text = data['email']?.toString() ?? ''; // Populate Email
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    bool isValid = true;

    // Validate email and IC
    if (!_validateEmail(_emailController.text)) isValid = false;
    if (!_validateIC(_icNumberController.text)) isValid = false;

    // Validate password if changing
    if (_isChangingPassword && _newPasswordController.text.isNotEmpty) {
      if (!_validateCurrentPassword(_currentPasswordController.text)) isValid = false;
      if (!_validatePassword(_newPasswordController.text)) isValid = false;

      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'New password and confirm password do not match.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 20,
              right: 20,
              left: 20,
              top: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      try {
        // Change password first if requested
        await _changePassword();
      } catch (e) {
        // If password change fails, stop the profile update
        return;
      }
    }

    if (!isValid) return;

    // If we get here, either no password change was requested or it was successful
    // Now proceed with profile updates
    Map<String, dynamic> teacherUpdates = {
      'fullName': _fullNameController.text,
      'icNumber': _icNumberController.text,
      'email': _emailController.text,
    };

    await _teacherRef.child(_user!.uid).update(teacherUpdates);
    
    Map<String, dynamic> userUpdates = {
      'fullName': _fullNameController.text,
      'email': _emailController.text,
      'icNumber': _icNumberController.text,
    };

    final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('User');
    await userRef.child(_user.uid).update(userUpdates);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Profile updated successfully!',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 20,
          right: 20,
          left: 20,
          top: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    try {
      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _emailController.text,
        password: _currentPasswordController.text,
      );

      await _user!.reauthenticateWithCredential(credential);

      // Change the password
      await _user.updatePassword(_newPasswordController.text);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Password changed successfully!',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: 20,
            right: 20,
            left: 20,
            top: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Clear the password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      // Turn off password change mode
      setState(() {
        _isChangingPassword = false;
      });
    } catch (e) {
      String errorMessage = 'Failed to change password. Please check your current password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: 20,
            right: 20,
            left: 20,
            top: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      throw Exception('Password change failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pinkAccent, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // Form Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        title: 'Full Name',
                        controller: _fullNameController,
                        icon: Icons.person_outline,
                      ),
                      _buildInputField(
                        title: 'Identity Card Number',
                        controller: _icNumberController,
                        icon: Icons.assignment_ind,
                        isIC: true,
                      ),
                      _buildInputField(
                        title: 'Email',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        isEmail: true,
                      ),
                      
                      // Password Change Section
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _isChangingPassword,
                            onChanged: (value) {
                              setState(() {
                                _isChangingPassword = value;
                              });
                            },
                            activeColor: Colors.pinkAccent,
                          ),
                        ],
                      ),

                      if (_isChangingPassword) ...[
                        _buildInputField(
                          title: 'Current Password',
                          controller: _currentPasswordController,
                          icon: Icons.lock_outline,
                          isCurrentPassword: true,
                        ),
                        _buildInputField(
                          title: 'New Password',
                          controller: _newPasswordController,
                          icon: Icons.lock_outline,
                          isNewPassword: true,
                        ),
                        _buildInputField(
                          title: 'Confirm New Password',
                          controller: _confirmPasswordController,
                          icon: Icons.lock_outline,
                          isConfirmPassword: true,
                        ),
                      ],

                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
    bool isIC = false,
    bool isNewPassword = false,
    bool isConfirmPassword = false,
    bool isCurrentPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isCurrentPassword ? _obscureCurrentPassword :
                      isNewPassword ? _obscureNewPassword :
                      isConfirmPassword ? _obscureConfirmPassword : false,
          onChanged: (value) {
            if (isCurrentPassword) {
              _validateCurrentPassword(value);
            } else if (isNewPassword || isConfirmPassword) {
              _validatePassword(value);
            } else if (isEmail) {
              _validateEmail(value);
            } else if (isIC) {
              _validateIC(value);
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.pinkAccent),
            suffixIcon: (isPassword || isNewPassword || isConfirmPassword || isCurrentPassword) ? IconButton(
              icon: Icon(
                (isCurrentPassword && _obscureCurrentPassword) ||
                (isNewPassword && _obscureNewPassword) ||
                (isConfirmPassword && _obscureConfirmPassword)
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.pinkAccent,
              ),
              onPressed: () {
                setState(() {
                  if (isCurrentPassword) _obscureCurrentPassword = !_obscureCurrentPassword;
                  if (isNewPassword) _obscureNewPassword = !_obscureNewPassword;
                  if (isConfirmPassword) _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ) : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.pinkAccent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            errorText: isCurrentPassword ? _currentPasswordError :
                      isNewPassword || isConfirmPassword ? _passwordError :
                      isEmail ? _emailError :
                      isIC ? _icError : null,
            hintText: isIC ? 'YYMMDD-PB-XXXX' : null,
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          validator: (value) => value!.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }
}