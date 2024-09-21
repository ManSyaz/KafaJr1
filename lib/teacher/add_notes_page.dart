import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../pdf_viewer_page.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('Content');
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  String _selectedSubject = '';
  String _title = '';
  String _description = '';
  File? _pickedFile;

  List<String> _subjects = [];

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
          setState(() {
            _subjects = subjectData.entries.map((entry) {
              final subjectMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return subjectMap['name'] as String;
            }).toList();
            if (_subjects.isNotEmpty) {
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
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _addNote() async {
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      _formKey.currentState!.save();

      final fileUrl = await _uploadFileToStorage(_pickedFile!);
      if (fileUrl == null) return;

      try {
        await _notesRef.push().set({
          'subject': _selectedSubject,
          'title': _title,
          'description': _description,
          'fileUrl': fileUrl,
        });
        Navigator.pop(context, true); // Pass a value back to indicate a successful operation.
      } catch (e) {
        print('Error adding note: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and upload a file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Add New Note'),
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
              const SizedBox(height: 8.0),
              if (_pickedFile != null) // Show the file name if a file is picked.
                Text('Selected file: ${_pickedFile!.path.split('/').last}'),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                child: const Text('Add Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  _NotesListPageState createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('Content');

  Future<void> _refreshNotes() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Your Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNotePage()),
              );
              if (result == true) {
                _refreshNotes();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _notesRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notes.'));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No notes available.'));
          }

          final notesData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final notes = notesData.entries.toList();

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index].value as Map<dynamic, dynamic>;

              // Check if fileUrl exists
              final bool hasFileUrl = note['fileUrl'] != null && note['fileUrl'].isNotEmpty;

              return ListTile(
                title: Text(note['title']),
                subtitle: Text(note['description']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasFileUrl) // Show the view icon only if fileUrl is present
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                        onPressed: () {
                          if (note['fileUrl'] != null && note['fileUrl'].isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PDFViewerPage(fileUrl: note['fileUrl']),
                              ),
                            );
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () {
                        // Add your edit functionality here
                      },
                    ),
                    // Add delete or any other actions as needed
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
