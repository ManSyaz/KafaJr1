// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add state variables for validation errors and password visibility
  String? _passwordError;
  String? _emailError;
  String? _icError;
  String? _parentEmailError;
  bool _obscurePassword = true;

  // Add validation functions
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

  bool _validateEmail(String email, {bool isParent = false}) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (email.isEmpty) {
      setState(() {
        if (isParent) {
          _parentEmailError = 'Email is required';
        } else {
          _emailError = 'Email is required';
        }
      });
      return false;
    }
    
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        if (isParent) {
          _parentEmailError = 'Please enter a valid email address';
        } else {
          _emailError = 'Please enter a valid email address';
        }
      });
      return false;
    }
    
    setState(() {
      if (isParent) {
        _parentEmailError = null;
      } else {
        _emailError = null;
      }
    });
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

  Future<void> _addStudent() async {
    bool isValid = true;

    // Validate all fields
    if (!_validateEmail(_emailController.text)) isValid = false;
    if (!_validateEmail(_parentEmailController.text, isParent: true)) isValid = false;
    if (!_validateIC(_icNumberController.text)) isValid = false;
    if (!_validatePassword(_passwordController.text)) isValid = false;
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter student\'s full name',
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
      isValid = false;
    }

    if (!isValid) return;

    try {
      // First create the user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final String newUid = userCredential.user!.uid;

      try {
        // Try to write to Student collection
        await FirebaseDatabase.instance.ref().child('Student').child(newUid).set({
          'email': _emailController.text.trim(),
          'fullName': _fullNameController.text,
          'icNumber': _icNumberController.text,
          'parentEmail': _parentEmailController.text.trim(),
        });

        // Try to write to User collection with email instead of username
        await FirebaseDatabase.instance.ref().child('User').child(newUid).set({
          'email': _emailController.text.trim(),
          'fullName': _fullNameController.text,
          'icNumber': _icNumberController.text,
          'role': 'Student',
        });

        // If both writes succeed, show success message and pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Student added successfully',
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
        Navigator.pop(context);
        
      } catch (dbError) {
        print('Database Error: $dbError');
        // Even if database write fails, the user was created in Authentication
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Student account created but some information may be incomplete. Please try editing the student details.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
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
        Navigator.pop(context);
      }

    } catch (e) {
      print('Auth Error: $e');
      String errorMessage = 'Failed to add student';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already registered';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format';
            break;
          case 'weak-password':
            errorMessage = 'Password should be at least 6 characters';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C6B58),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add New Student',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Form Fields
                _buildInputField(
                  'Student Full Name',
                  _fullNameController,
                  Icons.person_outline,
                  'Enter student\'s full name',
                ),
                _buildInputField(
                  'Student IC Number',
                  _icNumberController,
                  Icons.badge_outlined,
                  'YYMMDD-PB-XXXX',
                  isIC: true,
                ),
                _buildInputField(
                  'Student Email',
                  _emailController,
                  Icons.email_outlined,
                  'Enter student\'s email address',
                  isEmail: true,
                ),
                _buildInputField(
                  'Student Password',
                  _passwordController,
                  Icons.lock_outline,
                  'Enter student\'s password',
                  isPassword: true,
                ),
                _buildInputField(
                  'Parent Email',
                  _parentEmailController,
                  Icons.family_restroom,
                  'Enter parent\'s email address',
                  isParentEmail: true,
                ),

                const SizedBox(height: 30),
                
                // Submit Button
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0C6B58),
                        Color(0xFF094A3D),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0C6B58).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _addStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Add Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isPassword = false,
    bool isEmail = false,
    bool isIC = false,
    bool isParentEmail = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              onChanged: (value) {
                if (isPassword) {
                  _validatePassword(value);
                } else if (isEmail) {
                  _validateEmail(value);
                } else if (isParentEmail) {
                  _validateEmail(value, isParent: true);
                } else if (isIC) {
                  _validateIC(value);
                }
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                prefixIcon: Icon(icon, color: const Color(0xFF0C6B58)),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF0C6B58),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                errorText: isPassword ? _passwordError :
                          isEmail ? _emailError :
                          isParentEmail ? _parentEmailError :
                          isIC ? _icError : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
