// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_student_page.dart';
import 'edit_student_page.dart';
import 'upload_students_page.dart';

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
              // Convert fullName to uppercase if it exists
              if (studentInfo['fullName'] != null) {
                studentInfo['fullName'] = studentInfo['fullName'].toString().toUpperCase();
              }
              return {
                'uid': entry.key,
                ...studentInfo,
              };
            }).toList();

            // Sort students alphabetically by fullName
            students.sort((a, b) => (a['fullName'] ?? '').compareTo(b['fullName'] ?? ''));

            filteredStudents = students;
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
    
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this student? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false; // If dialog is dismissed, default to false

    if (!confirmDelete) return;
    
    try {
      // First, query all progress records for this student
      final progressRef = FirebaseDatabase.instance.ref().child('Progress');
      final progressSnapshot = await progressRef
          .orderByChild('studentId')
          .equalTo(uid)
          .get();
      
      if (progressSnapshot.exists) {
        // Delete all progress records for this student
        final progressData = progressSnapshot.value as Map<Object?, Object?>;
        for (var key in progressData.keys) {
          await progressRef.child(key.toString()).remove();
        }
      }

      // Then delete the student record and user record
      await _studentRef.child(uid).remove();
      await FirebaseDatabase.instance.ref().child('User').child(uid).remove();
      
      // Show success snackbar with updated design
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Student successfully deleted',
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
      }
      
      _fetchStudents(); // Refresh the list
    } catch (e) {
      print('Error deleting student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting student: $e',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
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
      }
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

  void _navigateToUploadStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadStudentsPage()),
    ).then((_) {
      _fetchStudents(); // Refresh the list after adding students
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
        backgroundColor: const Color(0xFF0C6B58),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'Manage Students',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh student data
          await _fetchStudents();
          return Future.delayed(const Duration(milliseconds: 500));
        },
        color: const Color(0xFF0C6B58),
        child: ListView(  // Changed from Column to ListView
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C6B58),
                        minimumSize: const Size(double.infinity, 50),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C6B58),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: _navigateToUploadStudents,
                      child: const Icon(
                        Icons.upload_file,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Color(0xFF0C6B58)),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0C6B58)),
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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      padding: const EdgeInsets.all(16.0),
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0C6B58),
                                Color(0xFF094A3D),
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
                          child: _buildStudentCard(student, index),
                        );
                      },
                    ),
            ),
            // Add extra padding at the bottom
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return Theme(
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
              _buildActionButton(
                icon: Icons.edit,
                onPressed: () => _navigateToEditStudent(student),
              ),
              _buildActionButton(
                icon: Icons.delete,
                onPressed: () => _deleteStudent(student['uid']),
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
                    icon: Icons.assignment_ind_outlined,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}