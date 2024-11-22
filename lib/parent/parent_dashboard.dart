// ignore_for_file: library_private_types_in_public_api, no_leading_underscores_for_local_identifiers

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
                              'Welcome! \n$userFullName',
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
        Column(
          children: [
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
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
            ),
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Children's Result Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<String>>(
                    future: _getStudentEmails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return const Text('Error fetching emails');
                      } else {
                        List<String> studentEmails = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Student Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
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
            const SizedBox(height: 20),
            Expanded(
              child: _selectedStudentEmail != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildScoreSummary(_selectedStudentEmail!),
                    )
                  : const SizedBox(),
            ),
          ],
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
            
            print('Debug - All Progress Data: ${data.toString()}'); // Debug print

            data.forEach((key, value) {
                if (value['studentId'] == studentId) {
                    String examType = value['examDescription'] ?? 'Unknown';
                    print('Debug - Found exam: $examType for student: $studentId'); // Debug print
                    
                    // Initialize the list if it doesn't exist
                    if (!examScores.containsKey(examType)) {
                        examScores[examType] = [];
                    }
                    
                    // Add the score
                    examScores[examType]!.add({
                        'subjectId': value['subjectId'],
                        'score': value['score'],
                    });
                }
            });

            print('Debug - Final examScores: ${examScores.toString()}'); // Debug print
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedExamTypes.map((examType) {
                  return _buildExamTypeSummary(examType, examScores[examType]!);
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
          return const SizedBox(); // Hide individual loading indicators
        }

        Map<String, String> subjectNames = snapshot.data ?? {};
        
        // Calculate summary for this exam type
        double average = scores.isEmpty ? 0 : 
            scores.map((s) => s['score'] as int).reduce((a, b) => a + b) / scores.length;

        // Find highest score with subject
        var highestScore = scores.isEmpty ? null : 
            scores.reduce((a, b) => (a['score'] as int) > (b['score'] as int) ? a : b);
        
        // Find lowest score with subject
        var lowestScore = scores.isEmpty ? null : 
            scores.reduce((a, b) => (a['score'] as int) < (b['score'] as int) ? a : b);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examType,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Average Score: ${average.toStringAsFixed(2)}'),
                if (highestScore != null)
                  Text('Highest Score: ${highestScore['score']} (${subjectNames[highestScore['subjectId']] ?? 'Unknown Subject'})'),
                if (lowestScore != null)
                  Text('Lowest Score: ${lowestScore['score']} (${subjectNames[lowestScore['subjectId']] ?? 'Unknown Subject'})'),
                Text('Total Subjects: ${scores.length}'),
                const SizedBox(height: 12),
                _buildProgressIndicator(average),
                const SizedBox(height: 8),
                Text(
                  'Grade: ${_getGrade(average)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getGradeColor(average),
                  ),
                ),
              ],
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
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getGradeColor(score)),
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
}