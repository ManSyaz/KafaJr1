// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../pdf_viewer_page.dart'; // Import the PDF viewer page

class ViewNotesPage extends StatefulWidget {
  const ViewNotesPage({super.key});

  @override
  _ViewNotesPageState createState() => _ViewNotesPageState();
}

class _ViewNotesPageState extends State<ViewNotesPage> {
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('Content');
  // ignore: unused_field
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<String, dynamic>> _notesList = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      final snapshot = await _notesRef.get();
      if (snapshot.exists) {
        final notesData = snapshot.value as Map<Object?, Object?>?;
        if (notesData != null) {
          setState(() {
            _notesList = notesData.entries.map((entry) {
              final noteMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'id': entry.key,
                ...noteMap,
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'Notes',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16.0),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                'List of Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _notesList.length,
              itemBuilder: (context, index) {
                final note = _notesList[index];
                return Card(
                  color: const Color.fromARGB(255, 121, 108, 108), // Change the card color here
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add margin for spacing
                  child: ListTile(
                    title: Text(
                      note['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      note['description'] ?? 'No Description',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    trailing: note['fileUrl'] != null && note['fileUrl'].isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PDFViewerPage(fileUrl: note['fileUrl']),
                                ),
                              );
                            },
                          )
                        : null, // Show view button only if fileUrl exists
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}