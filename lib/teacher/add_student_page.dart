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

  Future<void> _addStudent() async {
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
          const SnackBar(content: Text('Student added successfully')),
        );
        Navigator.pop(context);
        
      } catch (dbError) {
        print('Database Error: $dbError');
        // Even if database write fails, the user was created in Authentication
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student account created but some information may be incomplete. Please try editing the student details.'),
            duration: Duration(seconds: 5),
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
        backgroundColor: Colors.pinkAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'Add New Student',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Student Full Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Student IC Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _icNumberController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Student Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Student Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Parent Email Address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _parentEmailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox( // {{ edit_1 }}
                width: double.infinity, // Make the button take the full width
                child: ElevatedButton(
                  onPressed: _addStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Student',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
