// ignore_for_file: library_private_types_in_public_api, no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kafa_jr_1/auth/login_page.dart';

import 'manage_profile.dart';
import 'view_progress_student.dart';
import 'view_academic_record.dart';
import 'notification_page.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _unreadNotificationCount = 0;
  StreamSubscription<DatabaseEvent>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
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

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // First get the parent ID from User table
      FirebaseDatabase.instance
          .ref()
          .child('User')
          .child(user.uid)
          .once()
          .then((userSnapshot) {
        if (userSnapshot.snapshot.value != null) {
          _notificationSubscription = FirebaseDatabase.instance
              .ref()
              .child('Noti')
              .orderByChild('parentId')
              .equalTo(user.uid) // This is the parent's ID from auth
              .onValue
              .listen((event) {
            if (event.snapshot.value != null) {
              Map<dynamic, dynamic> notifications = event.snapshot.value as Map<dynamic, dynamic>;
              int unreadCount = notifications.values
                  .where((notification) => notification['isRead'] == false)
                  .length;
              setState(() {
                _unreadNotificationCount = unreadCount;
              });
            } else {
              setState(() {
                _unreadNotificationCount = 0;
              });
            }
          });
        }
      });
    }
  }

  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('User');
  int _selectedIndex = 0; // Track the selected index for bottom navigation
  String? _selectedStudentEmail; // Track the selected student email

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
            icon: Icon(Icons.home),
            label: 'Home',
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
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications, size: 35, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const NotificationPage(),
                                      ),
                                    );
                                  },
                                ),
                                if (_unreadNotificationCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        _unreadNotificationCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, size: 35, color: Colors.white),
                              onPressed: _handleLogout,
                            ),
                          ],
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
        
        // Content with RefreshIndicator
        Positioned(
          top: 115, // Position below AppBar
          left: 0,
          right: 0,
          bottom: 0,
          child: RefreshIndicator(
            onRefresh: () async {
              // Refresh all data sources
              _setupNotificationListener();
              setState(() {
                _selectedStudentEmail = null; // Reset selected student to force refresh
              });
              return Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFF0C6B58),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDashboardButton(
                          context,
                          'Students\nProgress',
                          const Color.fromARGB(255, 236, 191, 57),
                          const ViewProgressStudentPage(),
                          Icons.trending_up,
                        ),
                        _buildDashboardButton(
                          context,
                          'Academic\nRecord',
                          const Color.fromARGB(255, 216, 127, 231),
                          const ViewAcademicRecordPage(),
                          Icons.book,
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                const Color(0xFF0C6B58).withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF0C6B58).withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.assessment_rounded,
                                    color: Color(0xFF0C6B58),
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Result Overview",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<List<String>>(
                                future: _getStudentEmails(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Align(
                                      alignment: Alignment.centerLeft,
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasError) {
                                    return const Text('Error fetching emails');
                                  } else {
                                    List<String> studentEmails = snapshot.data ?? [];
                                    return DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Select Student Email',
                                        hintText: 'Choose the Email',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                          borderSide: const BorderSide(color: Color(0xFF0C6B58)),
                                        ),
                                      ),
                                      value: _selectedStudentEmail,
                                      isExpanded: true,
                                      items: studentEmails.map((String email) {
                                        return DropdownMenuItem<String>(
                                          value: email,
                                          child: Text(email),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedStudentEmail = newValue;
                                        });
                                      },
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300, // Fixed height for score summary
                      child: _selectedStudentEmail != null
                          ? _buildScoreSummary(_selectedStudentEmail!)
                          : const SizedBox(),
                    ),
                    // Add extra padding at the bottom
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.black),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _getStudentEmails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch student data from the database
        DatabaseEvent event = await FirebaseDatabase.instance.ref('Student').once();
        DataSnapshot snapshot = event.snapshot; // Access the snapshot from the event

        if (snapshot.exists) {
          Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
          List<String> emails = [];
          data.forEach((key, value) {
            if (value['parentEmail'] == user.email) {
              emails.add(value['email']); // Add the student's email
            }
          });
          return emails;
        } else {
          print('No data found in Student node');
        }
      } catch (e) {
        print('Error fetching student emails: $e'); // Print the error
      }
    }
    return [];
  }

  Future<String?> _getStudentIdByEmail(String email) async {
    try {
      DatabaseEvent event = await FirebaseDatabase.instance.ref('Student').once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        for (var entry in data.entries) {
          if (entry.value['email'] == email) {
            return entry.key; // Return the student ID
          }
        }
      }
    } catch (e) {
      print('Error fetching student ID: $e');
    }
    return null;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getStudentScores(String studentId) async {
    Map<String, List<Map<String, dynamic>>> examScores = {};
    
    try {
        DatabaseEvent event = await FirebaseDatabase.instance.ref('Progress').once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.exists) {
            Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
            
            // Create a map to track unique subject IDs for each exam type
            Map<String, Set<String>> uniqueSubjects = {};

            data.forEach((key, value) {
                if (value['studentId'] == studentId) {
                    String examType = value['examDescription'] ?? 'Unknown';
                    String subjectId = value['subjectId'] ?? '';
                    
                    // Initialize sets and lists if they don't exist
                    if (!examScores.containsKey(examType)) {
                        examScores[examType] = [];
                        uniqueSubjects[examType] = {};
                    }
                    
                    // Only add the score if we haven't recorded this subject for this exam type
                    if (!uniqueSubjects[examType]!.contains(subjectId)) {
                        uniqueSubjects[examType]!.add(subjectId);
                        examScores[examType]!.add({
                            'subjectId': subjectId,
                            'score': value['score'],
                        });
                    }
                }
            });
        }
    } catch (e) {
        print('Error fetching scores: $e');
    }
    return examScores;
  }

  Widget _buildScoreSummary(String studentEmail) {
    return FutureBuilder<String?>(
      future: _getStudentIdByEmail(studentEmail),
      builder: (context, studentIdSnapshot) {
        if (!studentIdSnapshot.hasData || studentIdSnapshot.data == null) {
          return const Text('Student not found');
        }

        return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _getStudentScores(studentIdSnapshot.data!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            Map<String, List<Map<String, dynamic>>> examScores = snapshot.data ?? {};

            if (examScores.isEmpty) {
              return const Center(
                child: Text(
                  'No exam records found',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            List<String> sortedExamTypes = examScores.keys.toList()
              ..sort((a, b) {
                List<String> order = ['UP1', 'UP2', 'PPT', 'PUPKK'];
                return order.indexOf(a).compareTo(order.indexOf(b));
              });

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sortedExamTypes.map((examType) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildExamTypeSummary(examType, examScores[examType]!),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>> _getSubjectNames() async {
    Map<String, String> subjectNames = {};
    try {
      DatabaseEvent event = await FirebaseDatabase.instance.ref('Subject').once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          subjectNames[key] = value['name'] ?? 'Unknown Subject';
        });
      }
    } catch (e) {
      print('Error fetching subject names: $e');
    }
    return subjectNames;
  }

  Widget _buildExamTypeSummary(String examType, List<Map<String, dynamic>> scores) {
    return FutureBuilder<Map<String, String>>(
      future: _getSubjectNames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        Map<String, String> subjectNames = snapshot.data ?? {};
        double average = scores.isEmpty ? 0 : 
            scores.map((s) => s['score'] as int).reduce((a, b) => a + b) / scores.length;
        var highestScore = scores.isEmpty ? null : 
            scores.reduce((a, b) => (a['score'] as int) > (b['score'] as int) ? a : b);
        var lowestScore = scores.isEmpty ? null : 
            scores.reduce((a, b) => (a['score'] as int) < (b['score'] as int) ? a : b);

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFF0C6B58).withOpacity(0.1),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        examType,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C6B58),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getGradeColor(average).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getGrade(average),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(average),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProgressIndicator(average),
                  const SizedBox(height: 16),
                  _buildScoreDetail('Average Score', average.toStringAsFixed(2), Icons.analytics),
                  if (highestScore != null)
                    _buildScoreDetail('Highest Score', 
                      '${highestScore['score']} (${subjectNames[highestScore['subjectId']] ?? 'Unknown Subject'})',
                      Icons.arrow_upward),
                  if (lowestScore != null)
                    _buildScoreDetail('Lowest Score', 
                      '${lowestScore['score']} (${subjectNames[lowestScore['subjectId']] ?? 'Unknown Subject'})',
                      Icons.arrow_downward),
                  _buildScoreDetail('Total Subjects', scores.length.toString(), Icons.book),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: double.infinity,
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getGradeColor(score)),
            ),
          ),
        ),
      ],
    );
  }

  String _getGrade(double averageScore) {
    if (averageScore >= 80 && averageScore <= 100) {
      return 'A (Excellent)';
    } else if (averageScore >= 60 && averageScore < 80) {
      return 'B (Good)';
    } else if (averageScore >= 40 && averageScore < 60) {
      return 'C (Satisfying)';
    } else if (averageScore >= 1 && averageScore < 40) {
      return 'D (Not Satisfactory)';
    } else {
      return 'N/A'; // For scores that are 0 or negative
    }
  }

  Color _getGradeColor(double averageScore) {
    if (averageScore >= 80) {
      return Colors.green; // Excellent
    } else if (averageScore >= 60) {
      return Colors.blue; // Good
    } else if (averageScore >= 40) {
      return Colors.orange; // Satisfying
    } else {
      return Colors.red; // Not Satisfactory
    }
  }

  Widget _buildScoreDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0C6B58)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}