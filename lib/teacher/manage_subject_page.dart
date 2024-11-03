// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_subject_page.dart';
import 'edit_subject_page.dart';

class ManageSubjectPage extends StatefulWidget {
  const ManageSubjectPage({super.key});

  @override
  _ManageSubjectPageState createState() => _ManageSubjectPageState();
}

class _ManageSubjectPageState extends State<ManageSubjectPage> {
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> filteredSubjects = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      final snapshot = await _subjectRef.get();
      if (snapshot.exists) {
        final subjectData = snapshot.value as Map<Object?, Object?>?;
        if (subjectData != null) {
          final Map<String, dynamic> subjectMap = Map<String, dynamic>.from(subjectData);
          setState(() {
            subjects = subjectMap.entries.map((entry) {
              final subjectMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'key': entry.key,
                ...subjectMap,
              };
            }).toList();
            filteredSubjects = List.from(subjects);
          });
        }
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  Future<void> _deleteSubject(String key) async {
    try {
      await _subjectRef.child(key).remove();
      _fetchSubjects();
    } catch (e) {
      print('Error deleting subject: $e');
    }
  }

  void _navigateToAddSubjectPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSubjectPage()),
    ).then((_) => _fetchSubjects());
  }

  void _navigateToEditSubjectPage(String key, Map<String, dynamic> subjectData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSubjectPage(
          subjectKey: key,
          subjectData: subjectData,
        ),
      ),
    ).then((_) => _fetchSubjects());
  }

  void _filterSubjects(String query) {
    setState(() {
      searchQuery = query;

      filteredSubjects = subjects.where((subject) {
        final subjectName = subject['name']?.toLowerCase() ?? '';
        return subjectName.contains(query.toLowerCase());
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
            'Manage Subjects',
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
              onPressed: _navigateToAddSubjectPage,
              child: const Text(
                'Add New Subject',
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
            child: Text('List of Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),

          // Search bar for filtering subjects
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: _filterSubjects,
              decoration: InputDecoration(
                labelText: 'Search Subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredSubjects.length,
              itemBuilder: (context, index) {
                final subject = filteredSubjects[index];
                return Card(
                  color: const Color.fromARGB(255, 121, 108, 108),
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      subject['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    subtitle: Text(
                      subject['code'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 212, 212, 212),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () => _navigateToEditSubjectPage(subject['key'], subject),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSubject(subject['key']),
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
