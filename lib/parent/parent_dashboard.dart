import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kafa_jr_1/auth/login_page.dart';

import 'manage_profile.dart';
import 'view_progress_student.dart';
import 'view_academic_record.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to login page after logout
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()), // Adjust the route as needed
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
        selectedItemColor: Colors.pinkAccent,
        onTap: _onItemTapped, // Handle tap on bottom navigation items
      ),
    );
  }

  Widget _buildDashboard() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            backgroundColor: Colors.pinkAccent,
            flexibleSpace: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top), // Status bar height
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
                            return Text(
                              'Welcome! $userFullName',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 35, color: Colors.white),
                        onPressed: _logout, // Call logout function
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDashboardButton(context, 'Students\nProgress', const Color.fromARGB(255, 236, 191, 57), const ViewProgressStudentPage()),
                  _buildDashboardButton(context, 'Academic\nRecord', Color.fromARGB(255, 216, 127, 231), const ViewAcademicRecordPage()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardButton(BuildContext context, String title, Color color, Widget targetPage) {
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
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}