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
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

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
        filteredNotes.removeWhere((note) => note['id'] == noteId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Note successfully deleted',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 20,
              right: 20,
              left: 20,
              top: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error deleting note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting note: $e',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 20,
              right: 20,
              left: 20,
              top: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'Manage Notes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh notes data
          await _fetchNotes();
          return Future.delayed(const Duration(milliseconds: 500));
        },
        color: const Color(0xFF0C6B58),
        child: ListView(  // Changed from Column to ListView
          physics: const AlwaysScrollableScrollPhysics(),
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
                  backgroundColor: const Color(0xFF0C6B58),
                  minimumSize: const Size(double.infinity, 50),
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

            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                'List of Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Color(0xFF0C6B58)),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0C6B58)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            
            filteredNotes.isEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.note_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No Notes Added'
                                : 'No Notes Found',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredNotes.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0C6B58),
                              Color(0xFF094A3D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _buildNoteCard(note),
                      );
                    },
                  ),
            // Add extra padding at the bottom
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note['description'] ?? 'No Description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note['subject'] ?? 'No Subject',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note['fileUrl'] != null && note['fileUrl'].isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PDFViewerPage(fileUrl: note['fileUrl']),
                            ),
                          );
                        },
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditNotePage(noteId: note['id']),
                          ),
                        ).then((_) => _fetchNotes());
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _deleteNoteWithFile(note['id'], note['fileUrl']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
