import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditExamPage extends StatefulWidget {
  final String examId;
  final String subjectId;

  const EditExamPage({super.key, required this.examId, required this.subjectId});

  @override
  _EditExamPageState createState() => _EditExamPageState();
}

class _EditExamPageState extends State<EditExamPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  String? _selectedSubject;
  String? _currentFileUrl;
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    _loadExamData();
    _fetchSubjects();
  }

  void _fetchSubjects() async {
    final snapshot = await _subjectRef.get();
    if (snapshot.exists) {
      final subjectData = snapshot.value as Map<dynamic, dynamic>?;
      if (subjectData != null) {
        setState(() {
          subjects = subjectData.entries.map((entry) {
            final subjectInfo = entry.value as Map<dynamic, dynamic>;
            final code = subjectInfo['code'] as String;
            final name = subjectInfo['name'] as String;
            return '$code - $name';
          }).toList();
        });
      }
    }
  }

  void _loadExamData() async {
    final snapshot = await _examRef.child(widget.examId).child('subjects').child(widget.subjectId).get();
    if (snapshot.exists) {
      final subjectData = snapshot.value as Map<Object?, Object?>?;
      if (subjectData != null) {
        setState(() {
          _titleController.text = subjectData['title'] as String? ?? '';
          _descriptionController.text = subjectData['description'] as String? ?? '';
          _selectedSubject = subjectData['subject'] as String? ?? '';
          _currentFileUrl = subjectData['fileUrl'] as String?;
        });
      }
    }
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _updateExam() async {
    if (_titleController.text.isEmpty || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and subject cannot be empty')),
      );
      return;
    }

    try {
      String? fileUrl;

      if (_selectedFile != null) {
        // Delete the old file if a new one is selected
        if (_currentFileUrl != null && _currentFileUrl!.isNotEmpty) {
          final oldRef = _storage.refFromURL(_currentFileUrl!);
          await oldRef.delete();
        }

        // Upload the new file
        final fileName = '${widget.examId}_${widget.subjectId}.pdf';
        final ref = _storage.ref().child('exams').child(fileName);
        final uploadTask = ref.putFile(_selectedFile!);
        final snapshot = await uploadTask;
        fileUrl = await snapshot.ref.getDownloadURL();
      } else {
        fileUrl = _currentFileUrl;
      }

      // Update the exam details in the database
      await _examRef.child(widget.examId).child('subjects').child(widget.subjectId).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'subject': _selectedSubject,
        'fileUrl': fileUrl,
      });

      Navigator.pop(context);
    } catch (e) {
      print('Error updating exam: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Edit Exam Subject'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              hint: const Text('Select Subject'),
              items: subjects.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
              child: const Text('Upload New File'),
            ),
            const SizedBox(height: 16.0),
            if (_selectedFile != null)
              Text('Selected File: ${_selectedFile!.path}'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updateExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
              child: const Text('Update Exam'),
            ),
          ],
        ),
      ),
    );
  }
}
