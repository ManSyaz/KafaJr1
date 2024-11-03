// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'add_notes_page.dart';
import 'edit_notes_page.dart';
import '../pdf_viewer_page.dart'; // Import the PDF viewer page

class ManageNotesPage extends StatefulWidget {
  const ManageNotesPage({super.key});

  @override
  _ManageNotesPageState createState() => _ManageNotesPageState();
}

class _ManageNotesPageState extends State<ManageNotesPage> {
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('Content');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<String, dynamic>> _notesList = [];
  List<Map<String, dynamic>> filteredNotes = []; // List for filtered notes
  String searchQuery = ''; // Search query

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
            filteredNotes = List.from(_notesList); // Initialize filtered list with all notes
          });
        }
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }
  }

  void _filterNotes(String query) {
    setState(() {
      searchQuery = query;
      filteredNotes = _notesList.where((note) {
        final title = note['title']?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _deleteNoteWithFile(String noteId, String? fileUrl) async {
    try {
      // Delete the file from Firebase Storage if the URL exists
      if (fileUrl != null && fileUrl.isNotEmpty) {
        final ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      }

      // Delete the note from Firebase Realtime Database
      await _notesRef.child(noteId).remove();

      // Remove the note locally and refresh the UI
      setState(() {
        _notesList.removeWhere((note) => note['id'] == noteId);
      });
    } catch (e) {
      print('Error deleting note: $e');
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
            'Manage Notes',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNotePage()),
                ).then((_) => _fetchNotes());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                minimumSize: const Size(double.infinity, 50), // Make the button take the full width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text(
                'Add New Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Aligning the title and search filter to the left
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'List of Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search bar for filtering notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: _filterNotes,
              decoration: InputDecoration(
                labelText: 'Search Note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                return Card(
                  color: const Color.fromARGB(255, 121, 108, 108),
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note['fileUrl'] != null && note['fileUrl'].isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PDFViewerPage(fileUrl: note['fileUrl']),
                                ),
                              );
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditNotePage(noteId: note['id']),
                              ),
                            ).then((_) => _fetchNotes());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNoteWithFile(note['id'], note['fileUrl']),
                        ),
                      ],
                    ),
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
