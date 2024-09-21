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
        title: const Text('Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                decoration: const InputDecoration(
                  labelText: 'Select Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
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
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
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
              ElevatedButton(
                onPressed: _uploadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                child: const Text('Upload File'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _updateNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
