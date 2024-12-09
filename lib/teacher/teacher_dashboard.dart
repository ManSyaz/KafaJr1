// ignore_for_file: library_private_types_in_public_api, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kafa_jr_1/auth/login_page.dart';

import 'manage_student_progress_page.dart';
import 'manage_academic_record_page.dart';
import 'manage_student_page.dart';
import 'manage_subject_page.dart';
import 'manage_notes_page.dart';
import 'manage_examination_page.dart';
import 'manage_profile.dart'; // Import the ManageProfilePage

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    // Show floating welcome message when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Login successful!', 
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
    });
  }

  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('User');
  int _selectedIndex = 0; // Track the selected index for bottom navigation

  Future<Map<String, dynamic>> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DataSnapshot snapshot = await _userRef.child(user.uid).once().then((event) => event.snapshot);
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {};
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    
    // Show logout message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Logout successful!', 
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

    // Navigate to login page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget _getSelectedPage() {
      switch (_selectedIndex) {
        case 0:
          return _buildDashboard(); // Your existing dashboard content
        case 1:
          return const ManageProfilePage(); // Navigate to ManageProfilePage
        // Add other cases for different pages if needed
        default:
          return _buildDashboard();
      }
    }

    return Scaffold(
      body: _getSelectedPage(), // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0C6B58),
        onTap: _onItemTapped, // Handle tap on bottom navigation items
      ),
    );
  }

  Widget _buildDashboard() {
    return Stack(
      children: [
        // Pattern container overlapping everything
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/kafapattern.png'),
              repeat: ImageRepeat.repeat,
              opacity: 0.2,
            ),
          ),
        ),
        
        // AppBar with higher z-index for interactivity
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(  // Add Material widget to ensure touch events work
            color: Colors.transparent,
            child: AppBar(
              backgroundColor: const Color(0xFF0C6B58),
              flexibleSpace: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getUserData(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Loading...');
                            } else if (snapshot.hasError) {
                              return const Text('Error');
                            } else {
                              var userData = snapshot.data!;
                              String userFullName = userData['fullName'] ?? 'User';
                              return Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      userFullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, size: 35, color: Colors.white),
                          onPressed: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              toolbarHeight: 250.0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
            ),
          ),
        ),
        
        // Rest of the dashboard content
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDashboardButton(
                    context,
                    'Students\nProgress',
                    const Color.fromARGB(255, 236, 191, 57),
                    const ManageStudentProgressPage(),
                    Icons.trending_up,
                  ),
                  _buildDashboardButton(
                    context,
                    'Academic\nRecord',
                    const Color.fromARGB(255, 216, 127, 231),
                    const ManageAcademicRecordPage(),
                    Icons.book,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDashboardButton(
                    context,
                    'Student',
                    const Color.fromARGB(255, 120, 165, 241),
                    const ManageStudentPage(),
                    Icons.person,
                  ),
                  _buildDashboardButton(
                    context,
                    'Subject',
                    const Color.fromARGB(255, 72, 214, 181),
                    const ManageSubjectPage(),
                    Icons.subject,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDashboardButton(
                    context,
                    'Notes',
                    const Color.fromARGB(255, 123, 184, 74),
                    const ManageNotesPage(),
                    Icons.note,
                  ),
                  _buildDashboardButton(
                    context,
                    'Examination',
                    Colors.orangeAccent,
                    const ManageExaminationPage(),
                    Icons.assignment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardButton(BuildContext context, String title, Color color, Widget targetPage, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        },
        child: Container(
          height: 100,
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.black),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}