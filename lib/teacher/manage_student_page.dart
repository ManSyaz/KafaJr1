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

            // Sort students alphabetically by fullName
            students.sort((a, b) => (a['fullName'] ?? '').compareTo(b['fullName'] ?? ''));

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
      }).toList()..sort((a, b) => (a['fullName'] ?? '').compareTo(b['fullName'] ?? ''));
    });
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Text('List of Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('Total Students: ${filteredStudents.length}', style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          
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
          
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No Students Added'
                              : 'No Students Found',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredStudents.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF69B4),
                              Color(0xFFFF1493),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            colorScheme: ColorScheme.fromSwatch().copyWith(
                              secondary: Colors.white,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: ExpansionTile(
                              backgroundColor: Colors.transparent,
                              collapsedBackgroundColor: Colors.transparent,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '${index + 1}. ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      student['fullName'] ?? 'No Name',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => _navigateToEditStudent(student),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteStudent(student['uid']),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.expand_more,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Container(
                                  color: Colors.white.withOpacity(0.1),
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      _buildInfoRow(
                                        icon: Icons.person_outlined,
                                        label: 'Full Name:',
                                        value: student['fullName'] ?? 'Not provided',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        icon: Icons.email_outlined,
                                        label: 'Identity Card Number:',
                                        value: student['icNumber'] ?? 'Not provided',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        icon: Icons.email_outlined,
                                        label: 'Email:',
                                        value: student['email'] ?? 'Not provided',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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