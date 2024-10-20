// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_student_page.dart';
import 'edit_student_page.dart';

class ManageStudentPage extends StatefulWidget {

  const ManageStudentPage({super.key});

  @override
  _ManageStudentPageState createState() => _ManageStudentPageState();
}

class _ManageStudentPageState extends State<ManageStudentPage> {
  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref().child('Student');

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = []; // List for filtered students

  String searchQuery = ''; // Search query

  @override
  void initState() {

    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final snapshot = await _studentRef.get();
      if (snapshot.exists) {
        final studentData = snapshot.value as Map<Object?, Object?>?;
        if (studentData != null) {
          final Map<String, dynamic> studentMap = Map<String, dynamic>.from(studentData);
          setState(() {
            students = studentMap.entries.map((entry) {
              final studentInfo = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'uid': entry.key,

                ...studentInfo,
              };
            }).toList();
            filteredStudents = students; // Initialize filtered list
          });
        }
      }
    } catch (e) {

      print('Error fetching students: $e');
    }
  }

  Future<void> _deleteStudent(String uid) async {
    if (uid.isEmpty) {
      print('Invalid UID provided for deletion');

      return;
    }
    try {
      await _studentRef.child(uid).remove();
      await FirebaseDatabase.instance.ref().child('User').child(uid).remove();
      _fetchStudents(); // Refresh the list

    } catch (e) {
      print('Error deleting student: $e');
    }
  }

  void _navigateToAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStudentPage()),
    ).then((_) {
      _fetchStudents(); // Refresh the list after adding a new student
    });
  }

  void _navigateToEditStudent(Map<String, dynamic> student) {
    Navigator.push(

      context,
      MaterialPageRoute(
        builder: (context) => EditStudentPage(studentId: student['uid']),
      ),
    ).then((_) {

      _fetchStudents(); // Refresh the list after editing a student
    });
  }

  void _filterStudents(String query) {
    setState(() {
      searchQuery = query;

      filteredStudents = students.where((student) {
        final fullName = student['fullName']?.toLowerCase() ?? '';
        return fullName.contains(query.toLowerCase());
      }).toList();
    });
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
            'Manage Students',

            style: TextStyle(color: Colors.white),
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(

            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                minimumSize: const Size(double.infinity, 50), // Make the button take the full width

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onPressed: _navigateToAddStudent,
              child: const Text(
                'Add New Student',

                style: TextStyle(
                  fontSize: 18,

                  fontWeight: FontWeight.bold,
                  color: Colors.white,

                ),

              ),
            ),
          ),
          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(

              onChanged: _filterStudents,
              decoration: InputDecoration(
                labelText: 'Search Student',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),

              ),
            ),
          ),

          const Padding(

            padding: EdgeInsets.only(left: 16.0),

            child: Text('List of Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,

              itemBuilder: (context, index) {
                final student = filteredStudents[index];

                return Card(

                  color: const Color.fromARGB(255, 121, 108, 108),
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      student['fullName'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        IconButton(

                          icon: const Icon(Icons.edit, color: Colors.green),

                          onPressed: () => _navigateToEditStudent(student),
                        ),

                        IconButton(

                          icon: const Icon(Icons.delete, color: Color.fromARGB(255, 255, 17, 0)),

                          onPressed: () => _deleteStudent(student['uid']),
                        ),
                      ],

                    ),

                  ),

                );

              },

            ),

          ),

        ],

      ),

    );

  }

}