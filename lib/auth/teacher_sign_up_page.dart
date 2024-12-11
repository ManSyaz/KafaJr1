// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';

class TeacherSignUpPage extends StatefulWidget {
  const TeacherSignUpPage({super.key});

  @override
  _TeacherSignUpPageState createState() => _TeacherSignUpPageState();
}

class _TeacherSignUpPageState extends State<TeacherSignUpPage> {
  final TextEditingController _accessCodeController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  
  bool _isAccessCodeVerified = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _passwordError;
  String? _emailError;
  String? _icError;

  // IC validation function
  bool _validateIC(String ic) {
    // Remove any dashes or spaces from the IC
    ic = ic.replaceAll(RegExp(r'[-\s]'), '');
    
    // Check if IC is 12 digits
    if (ic.length != 12) {
      setState(() => _icError = 'IC number must be 12 digits');
      return false;
    }

    // Check if all characters are numbers
    if (!RegExp(r'^[0-9]+$').hasMatch(ic)) {
      setState(() => _icError = 'IC number must contain only numbers');
      return false;
    }

    // Extract date components
    int year = int.parse(ic.substring(0, 2));
    int month = int.parse(ic.substring(2, 4));
    int day = int.parse(ic.substring(4, 6));

    // Add 1900 or 2000 to year depending on current year
    year += (year >= 0 && year <= DateTime.now().year % 100) ? 2000 : 1900;

    // Validate date
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

    // Validate state code (positions 7-8)
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

  // Password validation function
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

  // Email validation function
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

  Future<void> _verifyAccessCode() async {
    setState(() => _isLoading = true);

    try {
      // In a real app, you should verify this against your Firebase database
      const validAccessCode = "TEACHER2024"; // Example access code
      
      if (_accessCodeController.text == validAccessCode) {
        setState(() => _isAccessCodeVerified = true);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invalid Access Code'),
            content: const Text('Please enter a valid teacher access code.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpTeacher() async {
    setState(() => _isLoading = true);

    bool isPasswordValid = _validatePassword(_passwordController.text);
    bool isEmailValid = _validateEmail(_emailController.text);
    bool isICValid = _validateIC(_icNumberController.text);

    if (!isPasswordValid || !isEmailValid || !isICValid) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Create user authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String userId = userCredential.user?.uid ?? '';

      // Store in User table
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("User").child(userId);
      await userRef.set({
        'email': _emailController.text,
        'fullName': _fullNameController.text,
        'icNumber': _icNumberController.text.replaceAll(RegExp(r'[-\s]'), ''), // Remove dashes and spaces
        'role': 'Teacher',
      });

      // Store in Teacher table
      DatabaseReference teacherRef = FirebaseDatabase.instance.ref().child("Teacher").child(userId);
      await teacherRef.set({
        'email': _emailController.text,
        'fullName': _fullNameController.text,
        'icNumber': _icNumberController.text.replaceAll(RegExp(r'[-\s]'), ''), // Remove dashes and spaces
      });

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('You have successfully registered as a teacher.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Failed'),
            content: Text('Error: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
    bool isIC = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
              obscureText: isPassword ? _obscurePassword : false,
              onChanged: (value) {
                if (isPassword) {
                  _validatePassword(value);
                } else if (isEmail) {
                  _validateEmail(value);
                } else if (isIC) {
                  _validateIC(value);
                }
              },
              decoration: InputDecoration(
                hintText: isIC ? 'YYMMDD-PB-XXXX' : hint,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                prefixIcon: Icon(icon, color: const Color(0xFF0C6B58)),
                suffixIcon: isPassword ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF0C6B58),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                errorText: isPassword ? _passwordError : 
                          isEmail ? _emailError :
                          isIC ? _icError : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C6B58),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Teacher Registration', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Image.asset(
                'assets/kafalogo.png',
                height: 140,
                width: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              
              if (!_isAccessCodeVerified) ...[
                _buildInputField(
                  controller: _accessCodeController,
                  label: 'Access Code',
                  hint: 'Enter teacher access code',
                  icon: Icons.key,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAccessCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B58),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify Access Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                _buildInputField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                ),
                _buildInputField(
                  controller: _icNumberController,
                  label: 'Identity Card Number',
                  hint: 'Enter your IC number',
                  icon: Icons.assignment_ind_outlined,
                  isIC: true,
                ),
                _buildInputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  isEmail: true,
                ),
                _buildInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUpTeacher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B58),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}