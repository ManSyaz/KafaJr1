// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../pdf_viewer_page.dart'; // Import the PDF viewer page

class ViewExamPage extends StatefulWidget {
  const ViewExamPage({super.key});

  @override
  _ViewExamPageState createState() => _ViewExamPageState();
}

class _ViewExamPageState extends State<ViewExamPage> {
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');
  List<Map<String, dynamic>> _exams = [];
  List<String> _examCategories = []; // List of exam categories for filtering
  final List<String> _selectedCategories = []; // List to hold selected categories

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final snapshot = await _examRef.get();
      if (snapshot.exists) {
        final examData = snapshot.value as Map<Object?, Object?>?;
        if (examData != null) {
          setState(() {
            _exams = examData.entries.map((entry) {
              final examMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'id': entry.key,
                'description': examMap['description'] ?? 'No Description',
                'subjects': examMap['subjects'] ?? {},
                'category': examMap['subject'] ?? 'Unknown',
              };
            }).toList();

            // Extract unique categories for filtering
            _examCategories = _exams.map((exam) => exam['category'] as String).toSet().toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching exams: $e');
    }
  }

  List<Map<String, dynamic>> get filteredExams {
    if (_selectedCategories.isEmpty) {
      return _exams; // Return all exams if no category is selected
    }
    return _exams.where((exam) => _selectedCategories.contains(exam['category'])).toList(); // Filter exams by selected categories
  }

  void _navigateToSubjects(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectListPage(subjects: exam['subjects']),
      ),
    );
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
            'Examination',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                'List of Exams',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Exam filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                // "All" chip
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategories.isEmpty,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.clear(); // Clear selected categories to show all exams
                      }
                    });
                  },
                  selectedColor: Colors.pinkAccent,
                  backgroundColor: Colors.grey[300],
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                // Chips for each exam category
                ..._examCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category); // Add category to selected list
                        } else {
                          _selectedCategories.remove(category); // Remove category from selected list
                        }
                      });
                    },
                    selectedColor: Colors.pinkAccent,
                    backgroundColor: Colors.grey[300],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredExams.length,
              itemBuilder: (context, index) {
                final exam = filteredExams[index];
                return Card(
                  color: const Color.fromARGB(255, 121, 108, 108),
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      exam['description'] ?? 'No Description',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _navigateToSubjects(exam),
                      child: const Text('View Subjects'),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class SubjectListPage extends StatefulWidget {
  final Map<dynamic, dynamic> subjects;

  const SubjectListPage({super.key, required this.subjects});

  @override
  _SubjectListPageState createState() => _SubjectListPageState();
}

class _SubjectListPageState extends State<SubjectListPage> {
  List<String> selectedSubjects = []; // List to hold selected subjects

  void _viewFile(BuildContext context, String fileUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(fileUrl: fileUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract unique subjects for filtering
    List<String> subjectNames = List<String>.from(widget.subjects.entries.map((entry) {
      return entry.value['subject']; // Extract the subject field
    }).toSet()); // Use a Set to get unique subjects

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'Exam Subject',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Text(
              'Choose the Subject',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Subject filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                // "All" chip
                FilterChip(
                  label: const Text('All'),
                  selected: selectedSubjects.isEmpty,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedSubjects.clear(); // Clear selected subjects to show all
                      }
                    });
                  },
                  selectedColor: Colors.pinkAccent,
                  backgroundColor: Colors.grey[300],
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                // Chips for each subject
                ...subjectNames.map((subject) {
                  final isSelected = selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSubjects.add(subject); // Add subject to selected list
                        } else {
                          selectedSubjects.remove(subject); // Remove subject from selected list
                        }
                      });
                    },
                    selectedColor: Colors.pinkAccent,
                    backgroundColor: Colors.grey[300],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: widget.subjects.entries.where((entry) {
                  final subject = entry.value['subject'];
                  // Show the subject only if it matches the selected subjects
                  return selectedSubjects.isEmpty || selectedSubjects.contains(subject);
                }).map((entry) {
                  final subject = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(subject['title']),
                      subtitle: Text(subject['description']),
                      trailing: ElevatedButton(
                        onPressed: () => _viewFile(context, subject['fileUrl']),
                        child: const Text('View'),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}