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
        'fileUrl': downloadUrl, // Store the URL instead of the local path
      });

      Navigator.pop(context);
    } catch (e) {
      print('Error uploading file: $e');
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
            Container( // {{ edit_1 }}
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), // Border color
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
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
                  border: InputBorder.none, // Remove default border
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Padding inside the dropdown
                ),
              ),
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
            SizedBox( // {{ edit_2 }}
              width: double.infinity, // Make the button take the full width
              child: ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0), // Add border radius here
                  ),
                ),
                child: const Text( // Change text color to white
                  'Upload File',
                  style: TextStyle(color: Colors.white), // Change text color to white
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_file != null) Text('Selected File: ${_file!.path}'),
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
