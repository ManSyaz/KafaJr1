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
      MaterialPageRoute(builder: (context) => AddSubjectPage()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Manage Subjects'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
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
          const SizedBox(height: 16.0),
          const Text('List of Subjects', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return ListTile(
                  title: Text(subject['name']),
                  subtitle: Text(subject['code']),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
