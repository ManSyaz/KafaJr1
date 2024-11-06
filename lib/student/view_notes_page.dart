import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../pdf_viewer_page.dart'; // Import the PDF viewer page

class ViewNotesPage extends StatefulWidget {
  const ViewNotesPage({super.key});

  @override
  _ViewNotesPageState createState() => _ViewNotesPageState();
}

class _ViewNotesPageState extends State<ViewNotesPage> {
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('Content');
  List<Map<String, dynamic>> _notesList = [];
  List<String> _subjects = []; // List of subjects
  final List<String> _selectedSubjects = []; // List to hold selected subjects

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _fetchSubjects(); // Fetch subjects when initializing
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

  Future<void> _fetchSubjects() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('Subject').get();
      if (snapshot.exists) {
        final subjectsData = snapshot.value as Map<Object?, Object?>?;
        if (subjectsData != null) {
          setState(() {
            _subjects = subjectsData.entries.map((entry) {
              final subjectMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return subjectMap['name'] as String; // Ensure it's cast to String
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  List<Map<String, dynamic>> get filteredNotes {
    if (_selectedSubjects.isEmpty) {
      return _notesList; // Return all notes if no subject is selected
    }
    return _notesList.where((note) => _selectedSubjects.contains(note['subject'])).toList(); // Filter notes by selected subjects
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
        crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left)
        children: [
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),

          // Subject filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0, // Space between chips
              children: [
                // "All" chip
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedSubjects.isEmpty,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSubjects.clear(); // Clear selected subjects to show all notes
                      }
                    });
                  },
                  selectedColor: Colors.pinkAccent,
                  backgroundColor: Colors.grey[300],
                  labelStyle: const TextStyle(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: Colors.pinkAccent),
                  ),
                ),
                // Chips for each subject
                ..._subjects.map((subject) {
                  final isSelected = _selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSubjects.add(subject); // Add subject to selected list
                        } else {
                          _selectedSubjects.remove(subject); // Remove subject from selected list
                        }
                      });
                    },
                    selectedColor: Colors.pinkAccent,
                    backgroundColor: Colors.grey[300],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: isSelected ? Colors.white : Colors.pinkAccent),
                    ),
                  );
                }).toList(),
              ],
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
                        : null,
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