// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditStudentPage extends StatefulWidget {
  final String studentId;

  const EditStudentPage({required this.studentId, super.key});

  @override
  _EditStudentPageState createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref().child('Student');
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('User');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.studentId.isNotEmpty) {
      _fetchStudentInfo();
    } else {
      print('Invalid studentId provided');
    }
  }

  Future<void> _fetchStudentInfo() async {
    try {
      DataSnapshot studentSnapshot = await _studentRef.child(widget.studentId).get();
      DataSnapshot userSnapshot = await _userRef.child(widget.studentId).get();

      if (studentSnapshot.exists && userSnapshot.exists) {
        Map studentData = studentSnapshot.value as Map;
        //Map userData = userSnapshot.value as Map;

        setState(() {
          _usernameController.text = studentData['username'] ?? '';
          _fullNameController.text = studentData['fullName'] ?? '';
          _phoneNumberController.text = studentData['phoneNumber'] ?? '';
          // Password won't be fetched or shown for security reasons
        });

        _currentUser = _auth.currentUser;
      } else {
        print('Student or user data not found');
      }
    } catch (e) {
      print('Error fetching student info: $e');
    }
  }

  Future<void> _saveStudentInfo() async {
    try {
      String newUsername = _usernameController.text;
      String newPassword = _passwordController.text;

      if (_currentUser != null) {
        // Skip the email update if it's causing issues
        if (newUsername.isNotEmpty && newUsername != _currentUser!.email) {
          try {
            // Before updating the email, check if the email provider is enabled
            // You might skip this block if the email update is non-essential
            // await _currentUser!.updateEmail(newUsername);
            // Optionally, send a verification email
            // await _currentUser!.sendEmailVerification();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email not updated due to Firebase restrictions.')),
            );
          } catch (e) {
            print('Error updating email: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update email: ${e.toString()}')),
            );
            return; // Exit early to prevent further issues
          }
        }

        if (newPassword.isNotEmpty) {
          try {
            await _currentUser!.updatePassword(newPassword);
          } catch (e) {
            print('Error updating password: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update password: ${e.toString()}')),
            );
          }
        }

        // Update student information in the database
        await _studentRef.child(widget.studentId).update({
          'username': newUsername,
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneNumberController.text,
        });

        await _userRef.child(widget.studentId).update({
          'username': newUsername,
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneNumberController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student information updated successfully')),
        );
      }
    } catch (e) {
      print('Error updating student info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update student information: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        iconTheme: const IconThemeData(color: Colors.white), // {{ edit_1 }}
        title: Container(
          padding: const EdgeInsets.only(right:48.0),
          alignment: Alignment.center,
          child: const Text(
            'Edit Student',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username (Email)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter new password (leave blank to keep current password)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox( // {{ edit_1 }}
              width: double.infinity, // Make the button take the full width
              child: ElevatedButton(
                onPressed: _saveStudentInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
