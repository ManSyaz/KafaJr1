import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref().child('Student'); // Reference to Student table
  final User? _user = FirebaseAuth.instance.currentUser;

  String _fullName = '';
  String _phoneNumber = '';
  String _username = '';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    if (_user != null) {
      DatabaseEvent event = await _studentRef.child(_user.uid).once();
      DataSnapshot snapshot = event.snapshot; // Access the snapshot from the DatabaseEvent
      if (snapshot.exists) {
        final data = snapshot.value as Map<Object?, Object?>;
        setState(() {
          _fullName = data['fullName']?.toString() ?? '';
          _phoneNumber = data['phoneNumber']?.toString() ?? '';
          _username = data['username']?.toString() ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await _studentRef.child(_user!.uid).update({
        'fullName': _fullName,
        'phoneNumber': _phoneNumber,
        'username': _username,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to login page or perform any other action after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Welcome! $_fullName',
          style: const TextStyle(color: Colors.white), // Change text color to white
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), // Logout icon
            onPressed: _logout, // Call logout function
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _fullName,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pinkAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                onChanged: (value) => _fullName = value,
                validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _phoneNumber,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pinkAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                onChanged: (value) => _phoneNumber = value,
                validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pinkAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                onChanged: (value) => _username = value,
                validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pinkAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                ),
                obscureText: true,
                onChanged: (value) {
                  // Handle password change if needed
                },
                validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent, // Set button color to pink accent
                  minimumSize: Size(double.infinity, 50), // Full width
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
    );
  }
}