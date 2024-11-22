// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Add this import
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddExamSubjectPage extends StatefulWidget {
  final String examId;

  const AddExamSubjectPage({super.key, required this.examId});

  @override
  _AddExamSubjectPageState createState() => _AddExamSubjectPageState();
}

class _AddExamSubjectPageState extends State<AddExamSubjectPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _file;
  String? _selectedSubject;
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
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

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadFileAndSubmit() async {
    if (_titleController.text.isEmpty || _selectedSubject == null || _file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and upload a file.')),
      );
      return;
    }

    try {
      // Upload the file to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('exams/${widget.examId}/${DateTime.now().millisecondsSinceEpoch}.pdf');
      final uploadTask = storageRef.putFile(_file!);

      // Get the download URL after the file is uploaded
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Store the download URL in the Realtime Database
      final newSubjectRef = _examRef.child(widget.examId).child('subjects').push();
      await newSubjectRef.set({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'subject': _selectedSubject,
        'fileUrl': downloadUrl,
      });

      Navigator.pop(context);
    } catch (e) {
      print('Error uploading file: $e'); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: ${e.toString()}')), // Show error message
      );
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
            'Add Exam Subject',
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
                                _file != null 
                                    ? _file!.path.split('/').last
                                    : 'No file chosen',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_file == null) ...[
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
                            _file != null ? 'Change' : 'Choose File',
                            style: const TextStyle(color: Colors.pinkAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_file != null)
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
                              'File ready to upload',
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
                                _file = null;
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
            SizedBox( // {{ edit_3 }}
              width: double.infinity, // Make the button take the full width
              child: ElevatedButton(
                onPressed: _uploadFileAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0), // Add border radius here
                  ),
                ),
                child: const Text( // Change text color to white
                  'Submit',
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
