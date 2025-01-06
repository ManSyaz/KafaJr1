// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// For jsonEncode
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';

class EnterScorePage extends StatefulWidget {
  final String examId;

  const EnterScorePage({super.key, required this.examId});

  @override
  _EnterScorePageState createState() => _EnterScorePageState();
}

class _EnterScorePageState extends State<EnterScorePage> {
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref().child('Student');// New reference for Parent
  final DatabaseReference _progressRef = FirebaseDatabase.instance.ref().child('Progress');
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam'); // New reference for Exam
  final DatabaseReference _notificationRef = FirebaseDatabase.instance.ref().child('Noti');
  final DatabaseReference _parentRef = FirebaseDatabase.instance.ref().child('Parent'); // Add Parent reference

  String? _selectedSubjectId;
  String? _examDescription; // Variable to store exam description
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  Map<String, TextEditingController> _scoreControllers = {};
  String? _selectedExamId;
  final TextEditingController _searchController = TextEditingController();

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
        _selectedExamId = widget.examId;
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
                  "name": entry.value['name'] ?? 'Unknown Subject', // Added null fallback
                })
            .toList();
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first['id'];
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
                  "username": entry.value['username'] ?? '',
                })
            .toList();
        _students.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        _filteredStudents = List.from(_students); // Initialize filtered list
        _scoreControllers = {
          for (var student in _students) student['id']!: TextEditingController()
        };
      });
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _filteredStudents = _students
          .where((student) =>
              student['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _submitScores() async {
    bool hasInvalidScores = false;
    String errorMessage = '';

    // Validate all scores before submitting
    for (var student in _students) {
      String studentId = student['id']!;
      String scoreText = _scoreControllers[studentId]!.text;
      
      if (scoreText.isNotEmpty) {
        double? score = double.tryParse(scoreText);
        if (score == null) {
          hasInvalidScores = true;
          errorMessage = 'Please enter valid numbers for all scores';
          break;
        }
        if (score < 0 || score > 100) {
          hasInvalidScores = true;
          errorMessage = 'All scores must be between 0 and 100';
          break;
        }
      }
    }

    if (hasInvalidScores) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
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
      return;
    }

    if (_selectedSubjectId != null && _selectedExamId != null) {
        try {
            // First, get existing scores for this exam
            final existingScoresSnapshot = await _progressRef
                .orderByChild('examId')
                .equalTo(_selectedExamId)
                .once();

            Map<String, String> existingScoreKeys = {};
            if (existingScoresSnapshot.snapshot.value != null) {
                final data = existingScoresSnapshot.snapshot.value as Map<dynamic, dynamic>;
                data.forEach((key, value) {
                    // Create a unique identifier for each student-subject combination
                    String identifier = '${value['studentId']}-${value['subjectId']}';
                    existingScoreKeys[identifier] = key;
                });
            }

            for (var student in _students) {
                String studentId = student['id']!;
                double? score = double.tryParse(_scoreControllers[studentId]!.text);
                
                if (score != null) {
                    // Create identifier for current score
                    String identifier = '$studentId-$_selectedSubjectId';
                    
                    // Check if an entry already exists for this student-subject-exam combination
                    if (existingScoreKeys.containsKey(identifier)) {
                        // Update existing score
                        await _progressRef.child(existingScoreKeys[identifier]!).update({
                            'score': score,
                            'timestamp': ServerValue.timestamp,
                        });
                    } else {
                        // Create new entry
                        String newKey = _progressRef.push().key!;
                        await _progressRef.child(newKey).set({
                            'examId': _selectedExamId,
                            'studentId': studentId,
                            'score': score,
                            'examDescription': _examDescription,
                            'subjectId': _selectedSubjectId,
                            'timestamp': ServerValue.timestamp,
                        });
                    }
                }
            }

            // Replace email notification with in-app notification
            for (var student in _students) {
                String studentId = student['id']!;
                double? score = double.tryParse(_scoreControllers[studentId]!.text);
                
                if (score != null) {
                    // Get student data to get parent email
                    final studentSnapshot = await _studentRef.child(studentId).get();
                    if (studentSnapshot.exists) {
                        final studentData = studentSnapshot.value as Map<dynamic, dynamic>;
                        final parentEmail = studentData['parentEmail'];

                        // Get parent ID using parent email
                        final parentSnapshot = await _parentRef
                            .orderByChild('email')
                            .equalTo(parentEmail)
                            .once();
                        
                        if (parentSnapshot.snapshot.value != null) {
                            final parentData = parentSnapshot.snapshot.value as Map<dynamic, dynamic>;
                            final parentId = parentData.entries.first.key;

                            // Get subject name for the notification message
                            final subjectSnapshot = await _subjectRef.child(_selectedSubjectId!).get();
                            final subjectName = (subjectSnapshot.value as Map)['name'] ?? 'Unknown Subject';

                            // Get exam title
                            final examSnapshot = await _examRef.child(_selectedExamId!).get();
                            final examData = examSnapshot.value as Map<dynamic, dynamic>;
                            final examTitle = examData['title'] ?? 'Unknown Exam';

                            // Create notification
                            String notificationId = _notificationRef.push().key!;
                            final notification = SchoolNotification(
                                id: notificationId,
                                title: '$examTitle',
                                message: 'A new score has been added for $subjectName in $examTitle',
                                type: NotificationType.examResult,
                                timestamp: DateTime.now(),
                                isRead: false,
                                parentId: parentId,
                                studentId: studentId,
                                data: {
                                    'examId': _selectedExamId,
                                    'examTitle': examTitle,
                                    'subjectId': _selectedSubjectId,
                                    'score': score,
                                }
                            );

                            // Save notification
                            await _notificationRef.child(notificationId).set(notification.toJson());
                        }
                    }
                }
            }

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: const Text(
                        'Scores saved successfully',
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          _examDescription ?? 'Loading...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        onChanged: (newValue) {
                          setState(() {
                            _selectedSubjectId = newValue;
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
                          labelText: 'Select Subject',
                          border: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15), // Add spacing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterStudents,
                      decoration: const InputDecoration(
                        hintText: 'Search student...',
                        prefixIcon: Icon(Icons.search, color: Color(0xFF0C6B58)),
                        border: InputBorder.none,
                        labelStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C6B58),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C6B58),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  String studentName = _filteredStudents[index]['name'];
                  String studentId = _filteredStudents[index]['id'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _scoreControllers[studentId],
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                errorMaxLines: 2,
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  double? score = double.tryParse(value);
                                  if (score == null) {
                                    _scoreControllers[studentId]!.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Please enter a valid number',
                                          style: TextStyle(color: Colors.white),
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
                                  } else if (score < 0 || score > 100) {
                                    _scoreControllers[studentId]!.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Score must be between 0 and 100',
                                          style: TextStyle(color: Colors.white),
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
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _submitScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C6B58),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Submit Scores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}