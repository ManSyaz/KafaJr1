// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditNotePage extends StatefulWidget {
  final String noteId;

  const EditNotePage({super.key, required this.noteId});

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('Content');
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  String _selectedSubject = '';
  String _title = '';
  String _description = '';
  String? _fileUrl;
  File? _pickedFile;

  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchNoteDetails();
    _fetchSubjects();
  }

  Future<void> _fetchNoteDetails() async {
    try {
      final snapshot = await _notesRef.child(widget.noteId).get();
      if (snapshot.exists) {
        final noteData = snapshot.value as Map<Object?, Object?>;
        setState(() {
          _selectedSubject = noteData['subject'] as String;
          _title = noteData['title'] as String;
          _description = noteData['description'] as String;
          _fileUrl = noteData['fileUrl'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching note details: $e');
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final snapshot = await _subjectRef.get();
      if (snapshot.exists) {
        final subjectData = snapshot.value as Map<Object?, Object?>?;
        if (subjectData != null) {
          setState(() {
            _subjects = subjectData.entries.map((entry) {
              final subjectMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return subjectMap['name'] as String;
            }).toList();
            if (_subjects.isNotEmpty && _selectedSubject.isEmpty) {
              _selectedSubject = _subjects.first;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      setState(() {
        _pickedFile = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadFileToStorage(File file) async {
    try {
      final storageRef = _storage.ref().child('notes/${DateTime.now().millisecondsSinceEpoch}.pdf');
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _updateNote() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String? fileUrl = _fileUrl;
      if (_pickedFile != null) {
        fileUrl = await _uploadFileToStorage(_pickedFile!);
      }

      try {
        await _notesRef.child(widget.noteId).update({
          'subject': _selectedSubject,
          'title': _title,
          'description': _description,
          'fileUrl': fileUrl,
        });
        Navigator.pop(context);
      } catch (e) {
        print('Error updating note: $e');
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
            'Edit Notes',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSubject = newValue!;
                  });
                },
                items: _subjects.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a subject';
                  }
                  return null;
                },
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
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
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
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
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
                                  _pickedFile != null 
                                      ? _pickedFile!.path.split('/').last
                                      : _fileUrl != null 
                                          ? 'Current file: ${_fileUrl!.split('/').last}'
                                          : 'No file chosen',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_pickedFile == null && _fileUrl == null) ...[
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
                            onPressed: _uploadFile,
                            child: Text(
                              _pickedFile != null || _fileUrl != null ? 'Change' : 'Choose File',
                              style: const TextStyle(color: Colors.pinkAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_pickedFile != null || _fileUrl != null)
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
                                _pickedFile != null ? 'New file ready to upload' : 'Current file',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (_pickedFile != null || _fileUrl != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.grey.shade600,
                                onPressed: () {
                                  setState(() {
                                    _pickedFile = null;
                                    if (_fileUrl != null) _fileUrl = null;
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
                  onPressed: _updateNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Add border radius here
                    ),
                  ),
                  child: const Text( // {{ edit_4 }}
                    'Save',
                    style: TextStyle(color: Colors.white), // Change text color to white
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
