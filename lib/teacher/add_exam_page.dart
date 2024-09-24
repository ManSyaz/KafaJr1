import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddExamPage extends StatefulWidget {
  final String? examId;

  const AddExamPage({super.key, this.examId});

  @override
  _AddExamPageState createState() => _AddExamPageState();
}

class _AddExamPageState extends State<AddExamPage> {
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';

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
            'Add New Exam',
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
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) {
                  _description = value!;
                },
              ),
              const SizedBox(height: 16.0),
              SizedBox( // {{ edit_1 }}
                width: double.infinity, // Make the button take the full width
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      try {
                        final examRef = widget.examId == null
                            ? _examRef.push()
                            : _examRef.child(widget.examId!);

                        await examRef.set({
                          'title': _title,
                          'description': _description,
                          'subjects': {},
                        });

                        Navigator.pop(context);
                      } catch (e) {
                        print('Error adding exam: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Add border radius here
                    ),
                  ),
                  child: const Text( // {{ edit_2 }}
                    'Create Exam Folder',
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
