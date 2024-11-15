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

  Future<void> _signUp() async {
    try {
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

      // Check if the role is 'Student'
      if (_role == 'Student') {
        // Add data to the "Student" table
        DatabaseReference studentRef = FirebaseDatabase.instance.ref("Student/$userId");
        await studentRef.set({
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'icNumber': _icNumberController.text,
          'parentEmail': _studentEmailController.text, // Store Parent Email
        });

        // Check if the parent email exists in the "Parent" table
        DatabaseReference parentRef = FirebaseDatabase.instance.ref("Parent");
        DatabaseEvent event = await parentRef.once();
        bool parentExists = false;
        String parentId = '';

        // Check if the parent email exists
        if (event.snapshot.exists) {
          final parents = event.snapshot.value as Map;
          for (var key in parents.keys) {
            if (parents[key]['email'] == _studentEmailController.text) {
              parentExists = true;
              parentId = key;
              break;
            }
          }
        }

        // If parent exists, add entry to "StudentParent" table to create relationship
        if (parentExists) {
          DatabaseReference studentParentRef = FirebaseDatabase.instance.ref("StudentParent/$userId");
          await studentParentRef.set({
            'studentId': userId,
            'parentId': parentId,
            'parentEmail': _studentEmailController.text, // Store Parent Email
          });
        }
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
      // Print the error message for debugging
      debugPrint('Error during sign up: ${e.toString()}');
      // Optionally, show an error dialog to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Failed'),
            content: Text('Error: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        leading: IconButton( // Back arrow icon
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView( // Added scrollable view
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Name
                const Text(
                  'KAFAJr',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Register as a section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _role = 'Student';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _role == 'Student' ? Colors.pinkAccent : Colors.grey[300],
                      ),
                      child: const Text('Student'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _role = 'Parent';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _role == 'Parent' ? Colors.pinkAccent : Colors.grey[300],
                      ),
                      child: const Text('Parent'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Name',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Identity Card Number',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: _icNumberController, // New controller for IC Number
                      decoration: InputDecoration(
                        hintText: 'Enter your Identity Card Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

                // Student Email field (only for Parent role)
                if (_role == 'Student') ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parent Email',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: _studentEmailController,
                        decoration: InputDecoration(
                          hintText: 'Enter the parent\'s email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ],

                // Sign Up button
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}