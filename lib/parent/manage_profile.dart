// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kafa_jr_1/auth/login_page.dart';

class ManageProfilePage extends StatefulWidget {
  const ManageProfilePage({super.key});

  @override
  _ManageProfilePageState createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> {
  final DatabaseReference _parentRef = FirebaseDatabase.instance.ref().child('Parent'); // Reference to Parent table
  final User? _user = FirebaseAuth.instance.currentUser;

  String _fullName = '';
  String _icNumber = '';
  String _email = '';
  // ignore: unused_field
  final String _currentPassword = ''; // New variable for current password
  final String _newPassword = ''; // New variable for new password
  final String _confirmPassword = ''; // New variable for confirm password
  final _formKey = GlobalKey<FormState>();

  // Add TextEditingControllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController(); // Controller for current password
  final TextEditingController _newPasswordController = TextEditingController(); // Controller for new password
  final TextEditingController _confirmPasswordController = TextEditingController(); // Controller for confirm password

  // Add a boolean to track if the user wants to change their password
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchParentData();
  }

  Future<void> _fetchParentData() async {
    if (_user != null) {
      DatabaseEvent event = await _parentRef.child(_user.uid).once();
      DataSnapshot snapshot = event.snapshot; // Access the snapshot from the DatabaseEvent
      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;
        setState(() {
          _fullName = data['fullName']?.toString() ?? '';
          _icNumber = data['icNumber']?.toString() ?? '';
          _email = data['email']?.toString() ?? '';
          // Update the controllers with fetched data
          _fullNameController.text = _fullName;
          _icNumberController.text = _icNumber;
          _emailController.text = _email;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPassword != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm password do not match.')),
      );
      return;
    }

    try {
      // Re-authenticate the user
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: _currentPasswordController.text,
      );

      // Change the password
      await userCredential.user!.updatePassword(_newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );

      // Clear the password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error changing password: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Update the Parent table
      await _parentRef.child(_user!.uid).update({
        'fullName': _fullNameController.text,
        'icNumber': _icNumberController.text,
        'email': _emailController.text,
      });

      // Assuming you have a reference to the User table
      final DatabaseReference userRef = FirebaseDatabase.instance.ref().child('User');

      // Update the User table
      await userRef.child(_user.uid).update({
        'fullName': _fullNameController.text,
        'icNumber': _icNumberController.text,
        'email': _emailController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to login page or perform any other action after logout
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()), // Adjust the route as needed
    );
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is removed from the widget tree
    _fullNameController.dispose();
    _icNumberController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose(); // Dispose current password controller
    _newPasswordController.dispose(); // Dispose new password controller
    _confirmPasswordController.dispose(); // Dispose confirm password controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Welcome! $_fullName',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Full Name Title
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Full Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.pinkAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 16),

                // IC Number Title
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'IC Number',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextFormField(
                  controller: _icNumberController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.pinkAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your IC number' : null,
                ),
                const SizedBox(height: 16),

                // Email Title
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.pinkAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                  validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 20),

                // Toggle for changing password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change Password'),
                    Switch(
                      value: _isChangingPassword,
                      onChanged: (value) {
                        setState(() {
                          _isChangingPassword = value;
                        });
                      },
                    ),
                  ],
                ),

                // Password Fields (only shown if _isChangingPassword is true)
                if (_isChangingPassword) ...[
                  const SizedBox(height: 16),
                  // Current Password Title
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Current Password',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.pinkAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter your current password' : null,
                  ),
                  const SizedBox(height: 16),

                  // New Password Title
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'New Password',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.pinkAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter your new password' : null,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Title
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Confirm New Password',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.pinkAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please confirm your new password' : null,
                  ),
                ],

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    await _saveProfile(); // Save profile data
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}