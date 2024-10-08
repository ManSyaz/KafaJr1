// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditSubjectPage extends StatefulWidget {
  final String subjectKey;
  final Map<String, dynamic> subjectData;

  const EditSubjectPage({super.key, 
    required this.subjectKey,
    required this.subjectData,
  });

  @override
  _EditSubjectPageState createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.subjectData['code']);
    _nameController = TextEditingController(text: widget.subjectData['name']);
  }

  Future<void> _updateSubject() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _subjectRef.child(widget.subjectKey).update({
          'code': _codeController.text,
          'name': _nameController.text,
        });
        Navigator.pop(context);
      } catch (e) {
        print('Error updating subject: $e');
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
            'Edit Subject',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subject code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subject name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              SizedBox( // {{ edit_1 }}
                width: double.infinity, // Make the button take the full width
                child: ElevatedButton(
                  onPressed: _updateSubject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  ),
                  child: const Text( // {{ edit_2 }}
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
