// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../pdf_viewer_page.dart'; // Import the PDF viewer page

class ViewExamPage extends StatefulWidget {
  const ViewExamPage({super.key});

  @override
  _ViewExamPageState createState() => _ViewExamPageState();
}

class _ViewExamPageState extends State<ViewExamPage> {
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final snapshot = await _examRef.get();
      if (snapshot.exists) {
        final examData = snapshot.value as Map<Object?, Object?>?;
        if (examData != null) {
          setState(() {
            _exams = examData.entries.map((entry) {
              final examMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'id': entry.key,
                'description': examMap['description'],
                'subjects': examMap['subjects'],
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching exams: $e');
    }
  }

  void _navigateToSubjects(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectListPage(subjects: exam['subjects']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('View Exams'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: _exams.map((exam) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(exam['description']),
                trailing: ElevatedButton(
                  onPressed: () => _navigateToSubjects(exam),
                  child: const Text('View Subjects'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SubjectListPage extends StatelessWidget {
  final Map<dynamic, dynamic> subjects;

  const SubjectListPage({super.key, required this.subjects});

  void _viewFile(BuildContext context, String fileUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(fileUrl: fileUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Subjects'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: subjects.entries.map((entry) {
            final subject = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(subject['title']),
                subtitle: Text(subject['description']),
                trailing: ElevatedButton(
                  onPressed: () => _viewFile(context, subject['fileUrl']),
                  child: const Text('View'),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}