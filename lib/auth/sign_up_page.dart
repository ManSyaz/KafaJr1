// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController(); // New controller for IC Number
  final TextEditingController _studentEmailController = TextEditingController(); // New controller for Student Email
  String _role = 'Student'; // Default role
  String? _passwordError;
  String? _emailError;
  String? _parentEmailError;

  // Add new state variable for password visibility
  bool _obscurePassword = true;

  // Add new state variable for IC error
  String? _icError;

  // Add IC validation function
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

  bool _validateEmail(String email, {bool isParentEmail = false}) {
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (email.isEmpty) {
      setState(() {
        if (isParentEmail) {
          _parentEmailError = 'Parent email is required';
        } else {
          _emailError = 'Email is required';
        }
      });
      return false;
    }
    
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        if (isParentEmail) {
          _parentEmailError = 'Please enter a valid email address';
        } else {
          _emailError = 'Please enter a valid email address';
        }
      });
      return false;
    }
    
    setState(() {
      if (isParentEmail) {
        _parentEmailError = null;
      } else {
        _emailError = null;
      }
    });
    return true;
  }

  bool _isLoading = false; // New state variable for loading

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    bool isPasswordValid = _validatePassword(_passwordController.text);
    bool isEmailValid = _validateEmail(_emailController.text);
    bool isParentEmailValid = true;
    bool isICValid = _validateIC(_icNumberController.text);
    
    if (_role == 'Student') {
      isParentEmailValid = _validateEmail(_studentEmailController.text, isParentEmail: true);
    }

    if (!isPasswordValid || !isEmailValid || !isParentEmailValid || !isICValid) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Check if parent email exists in Parent table when registering as Student
      if (_role == 'Student') {
        final parentSnapshot = await FirebaseDatabase.instance
            .ref("Parent")
            .orderByChild("email")
            .equalTo(_studentEmailController.text)
            .get();

        if (parentSnapshot.value == null) {
          throw Exception("Parent email not registered. Please ensure the parent has registered first.");
        }

        // Convert snapshot to Map and verify email exists
        final parentData = parentSnapshot.value as Map;
        bool parentFound = false;
        String? parentId;

        parentData.forEach((key, value) {
          if (value['email'] == _studentEmailController.text) {
            parentFound = true;
            parentId = key;
          }
        });

        if (!parentFound || parentId == null) {
          throw Exception("Parent email not found. Please check the email and try again.");
        }
      }

      // Register user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String userId = userCredential.user?.uid ?? '';

      // Add user details to "User" table
      DatabaseReference userRef = FirebaseDatabase.instance.ref("User/$userId");
      await userRef.set({
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'icNumber': _icNumberController.text,
        'role': _role,
      });

      // Add data to specific role tables
      if (_role == 'Student') {
        // Add to Student table
        DatabaseReference studentRef = FirebaseDatabase.instance.ref("Student/$userId");
        await studentRef.set({
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'icNumber': _icNumberController.text,
          'parentEmail': _studentEmailController.text,
        });
      } else if (_role == 'Parent') {
        DatabaseReference parentRef = FirebaseDatabase.instance.ref("Parent/$userId");
        await parentRef.set({
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'icNumber': _icNumberController.text,
        });
      }

      // Show success dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('You have successfully registered.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
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
      // Show error dialog with more user-friendly message
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String errorMessage = e.toString();
          if (errorMessage.contains("Parent email not registered")) {
            errorMessage = "The parent email provided is not registered. Please ensure the parent has created an account first.";
          } else if (errorMessage.contains("Parent email not found")) {
            errorMessage = "Could not find a parent account with this email. Please verify the email address.";
          }
          
          return AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C6B58),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Replace Logo and Title Section
              Image.asset(
                'assets/kafalogo.png',
                height: 140,
                width: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 0),
              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Role Selection
              Container(
                padding: const EdgeInsets.all(4),
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
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: () => setState(() => _role = 'Student'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _role == 'Student' ? const Color(0xFF0C6B58) : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Student',
                            style: TextStyle(
                              color: _role == 'Student' ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: () => setState(() => _role = 'Parent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _role == 'Parent' ? const Color(0xFF0C6B58) : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Parent',
                            style: TextStyle(
                              color: _role == 'Parent' ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Input Fields
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
              if (_role == 'Student')
                _buildInputField(
                  controller: _studentEmailController,
                  label: 'Parent Email',
                  hint: 'Enter parent\'s email',
                  icon: Icons.family_restroom,
                  isParentEmail: true,
                ),

              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp, // Disable button while loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C6B58),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) // Show loading indicator
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
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
    bool isParentEmail = false,
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
                } else if (isParentEmail) {
                  _validateEmail(value, isParentEmail: true);
                } else if (isIC) {
                  _validateIC(value);
                }
              },
              decoration: InputDecoration(
                hintText: isIC ? 'YYMMDD-PB-XXXX' : hint, // Add IC format hint
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