// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EnterScorePage extends StatefulWidget {
  final String examId;

  const EnterScorePage({super.key, required this.examId});

  @override
  _EnterScorePageState createState() => _EnterScorePageState();
}

class _EnterScorePageState extends State<EnterScorePage> {
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref().child('Student');
  final DatabaseReference _progressRef = FirebaseDatabase.instance.ref().child('Progress');
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam'); // New reference for Exam

  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String? _examDescription; // Variable to store exam description
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    _loadExamDescription(); // Load the exam description when page loads
    _loadSubjects();
  }

  // Load exam description based on examId
  Future<void> _loadExamDescription() async {
  final snapshot = await _examRef.child(widget.examId).get(); // Get the exam data using examId
  if (snapshot.exists && snapshot.value != null) { // Check if snapshot exists and is not null
    final examData = snapshot.value as Map<dynamic, dynamic>; // Cast snapshot.value as a map
    setState(() {
      _examDescription = examData['description'] ?? 'No description available';
    });
  } else {
    setState(() {
      _examDescription = 'No description available'; // Fallback if exam description is not found
    });
  }
}

  Future<void> _loadSubjects() async {
    final snapshot = await _subjectRef.get();
    if (snapshot.exists) {
      final subjectsData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _subjects = subjectsData.entries
            .map((entry) => {
                  "id": entry.key,
                  "name": entry.value['name'],
                })
            .toList();
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first['id'];
          _selectedSubjectName = _subjects.first['name'];
          _loadStudents();
        }
      });
    }
  }

  Future<void> _loadStudents() async {
    final snapshot = await _studentRef.get();
    if (snapshot.exists) {
      final studentsData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _students = studentsData.entries
            .map((entry) => {
                  "id": entry.key,
                  "name": entry.value['fullName'] ?? 'Unnamed Student',
                })
            .toList();
        _scoreControllers = {
          for (var student in _students)
            student['id']: TextEditingController()
        };
      });
    }
  }

  void _submitScores() async {
    if (_selectedSubjectId != null) {
      try {
        for (var student in _students) {
          String studentId = student['id'];
          double? score = double.tryParse(_scoreControllers[studentId]!.text);
          if (score != null) {
            await _progressRef.push().set({
              'studentId': studentId,
              'subjectId': _selectedSubjectId,
              'percentage': score,
              'examDescription': _examDescription,
            });
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scores saved successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error saving scores: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving scores: $e')),
        );
      }
    }
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
            'Enter Score',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the retrieved exam description
            Text(
              _examDescription ?? 'Loading...', // If description is not loaded yet, show "Loading..."
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              onChanged: (newValue) {
                setState(() {
                  _selectedSubjectId = newValue;
                  _selectedSubjectName = _subjects
                      .firstWhere((subject) => subject['id'] == newValue)['name'];
                  _loadStudents();
                });
              },
              items: _subjects.map<DropdownMenuItem<String>>((subject) {
                return DropdownMenuItem<String>(
                  value: subject['id'],
                  child: Text(subject['name']),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Choose Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Subject: ${_selectedSubjectName ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'List of Student',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  String studentName = _students[index]['name'];
                  String studentId = _students[index]['id'];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Text(studentName),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _scoreControllers[studentId],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter Score',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
