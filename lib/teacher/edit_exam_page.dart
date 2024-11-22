// ignore_for_file: library_private_types_in_public_api

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
        iconTheme: const IconThemeData(color: Colors.white), // {{ edit_1 }}
        title: Container(
          padding: const EdgeInsets.only(right:48.0),
          alignment: Alignment.center,
          child: const Text(
            'Edit Exam Subject',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Select Subject',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
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
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Title',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const SizedBox(height: 16.0),
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Upload PDF File',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined, 
                            color: Colors.grey.shade600, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile != null 
                                    ? _selectedFile!.path.split('/').last
                                    : _currentFileUrl != null 
                                        ? 'Current file: ${_currentFileUrl!.split('/').last}'
                                        : 'No file chosen',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedFile == null && _currentFileUrl == null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'PDF files only',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _pickFile,
                          child: Text(
                            _selectedFile != null || _currentFileUrl != null ? 'Change' : 'Choose File',
                            style: const TextStyle(color: Colors.pinkAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedFile != null || _currentFileUrl != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, 
                              color: Colors.green.shade400, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFile != null ? 'New file ready to upload' : 'Current file',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: Colors.grey.shade600,
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                if (_currentFileUrl != null) _currentFileUrl = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox( // {{ edit_2 }}
              width: double.infinity, // Make the button take the full width
              child: ElevatedButton(
                onPressed: _updateExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0), // Add border radius here
                  ),
                ),
                child: const Text( // Change text color to white
                  'Update Exam',
                  style: TextStyle(color: Colors.white), // Change text color to white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
