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
        iconTheme: const IconThemeData(color: Colors.white), // {{ edit_1 }}
        title: Container(
          padding: const EdgeInsets.only(right:48.0),
          alignment: Alignment.center,
          child: const Text(
            'Manage Subjects',
            style: TextStyle(color: Colors.white),
          ),
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
          const Align( // {{ edit_1 }}
            alignment: Alignment.centerLeft, // Align to the left
            child: Padding(
              padding: EdgeInsets.only(left: 16.0), // Add left padding
              child: Text('List of Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return Card( // {{ edit_1 }}
                  color: Color.fromARGB(255, 121, 108, 108), // Change the card color here
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add margin for spacing
                  child: ListTile(
                    title: Text( // {{ edit_2 }}
                      subject['name'],
                      style: const TextStyle( // Add your desired text style here
                        fontSize: 16, // Example font size
                        fontWeight: FontWeight.bold, // Example font weight
                        color: Color.fromARGB(255, 255, 255, 255), // Example text color
                      ),
                    ),
                    subtitle: Text( // {{ edit_3 }}
                      subject['code'],
                      style: const TextStyle( // Add your desired text style here
                        fontSize: 14, // Example font size
                        color: Color.fromARGB(255, 212, 212, 212), // Example text color
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
