// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ViewProgressStudentPage extends StatefulWidget {
  const ViewProgressStudentPage({super.key});

  @override
  _ViewProgressStudentPageState createState() => _ViewProgressStudentPageState();
}

class _ViewProgressStudentPageState extends State<ViewProgressStudentPage> {
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('Student');
  final DatabaseReference _progressRef = FirebaseDatabase.instance.ref().child('Progress');
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');

  String _selectedSubject = 'Choose Subject';
  String _selectedStudentId = '';
  Map<String, String> studentNames = {};
  List<Map<String, String>> subjects = [];
  Map<String, Map<String, String>> studentsProgress = {};

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchStudents();
    _selectedStudentId = _getLoggedInStudentId(); // Set the selected student ID
  }

  String _getLoggedInStudentId() {
    // Get the current user from Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? ''; // Return the user's ID or an empty string if not logged in
  }

  Future<void> _fetchSubjects() async {
    try {
      final snapshot = await _subjectRef.get();
      if (snapshot.exists) {
        final subjectData = snapshot.value as Map<Object?, Object?>?;
        if (subjectData != null) {
          setState(() {
            subjects = [
              {'id': 'Choose Subject', 'name': 'Choose Subject'}
            ] + subjectData.entries.map((entry) {
              final subjectMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'id': entry.key?.toString() ?? 'Unknown',
                'name': subjectMap['name']?.toString() ?? 'Unknown',
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final snapshot = await _userRef.get();
      if (snapshot.exists) {
        final studentData = snapshot.value as Map<Object?, Object?>?;
        if (studentData != null) {
          setState(() {
            studentNames = studentData.entries.fold<Map<String, String>>(
              {},
              (map, entry) {
                final studentMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
                final studentId = entry.key?.toString() ?? 'Unknown';
                final studentName = studentMap['fullName']?.toString() ?? 'Unknown';
                map[studentId] = studentName;
                return map;
              },
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> _fetchStudentProgressBySubject(String subjectId) async {
    if (_selectedStudentId.isEmpty) return; // Ensure student ID is set

    try {
      final snapshot = await _progressRef
          .orderByChild('studentId')
          .equalTo(_selectedStudentId)
          .get();

      if (snapshot.exists) {
        final progressData = snapshot.value as Map<Object?, Object?>;
        final filteredProgress = progressData.entries.fold<Map<String, Map<String, String>>>(
          {},
          (map, entry) {
            final progress = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            if (progress['subjectId'] == subjectId) { // Compare subject ID
              final studentId = progress['studentId'] ?? '-';
              if (!map.containsKey(studentId)) {
                map[studentId] = {
                  'UP1': '-',
                  'PPT': '-',
                  'UP2': '-',
                  'PAT': '-',
                  'PUPK': '-',
                };
              }
              // Update the progress for the corresponding exam description
              String examDescription = progress['examDescription'] ?? '';
              String percentage = progress['percentage']?.toString() ?? '0';

              // Store the percentage for the exam description
              map[studentId]![examDescription] = percentage;
            }
            return map;
          },
        );

        setState(() {
          studentsProgress = filteredProgress; // Update state with fetched data
        });
      }
    } catch (e) {
      print('Error fetching student progress: $e');
    }
  }

  Widget _buildGraph() {
    if (studentsProgress.isEmpty) return Container(); // No data to display

    // Define a single color for all bars
    const Color barColor = Colors.orangeAccent; // Light purple color

    final dataEntries = studentsProgress.entries.expand((entry) {
      final progress = entry.value;
      return [
        BarChartGroupData(
          x: _getExamIndex('UP1') ?? 0,
          barRods: [
            BarChartRodData(
              toY: double.tryParse(progress['UP1'] ?? '0') ?? 0,
              color: barColor, // Use the same color for all bars
              width: 50,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
        BarChartGroupData(
          x: _getExamIndex('PPT') ?? 0,
          barRods: [
            BarChartRodData(
              toY: double.tryParse(progress['PPT'] ?? '0') ?? 0,
              color: barColor, // Use the same color for all bars
              width: 50,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
        BarChartGroupData(
          x: _getExamIndex('UP2') ?? 0,
          barRods: [
            BarChartRodData(
              toY: double.tryParse(progress['UP2'] ?? '0') ?? 0,
              color: barColor, // Use the same color for all bars
              width: 50,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
        BarChartGroupData(
          x: _getExamIndex('PAT') ?? 0,
          barRods: [
            BarChartRodData(
              toY: double.tryParse(progress['PAT'] ?? '0') ?? 0,
              color: barColor, // Use the same color for all bars
              width: 50,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
        BarChartGroupData(
          x: _getExamIndex('PUPK') ?? 0,
          barRods: [
            BarChartRodData(
              toY: double.tryParse(progress['PUPK'] ?? '0') ?? 0,
              color: barColor, // Use the same color for all bars
              width: 50,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      ];
    }).toList();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.start,
          barGroups: dataEntries,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(_getExamDescription(value.toInt())),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: const Color(0xff37434d),
              width: 1,
            ),
          ),
          gridData: const FlGridData(show: false),
          barTouchData: BarTouchData(enabled: true),
        ),
      ),
    );
  }

  String _getExamDescription(int index) {
    switch (index) {
      case 1:
        return 'UP1';
      case 2:
        return 'PPT';
      case 3:
        return 'UP2';
      case 4:
        return 'PAT';
      case 5:
        return 'PUPK';
      default:
        return '';
    }
  }

  int? _getExamIndex(String description) {
    switch (description) {
      case 'UP1':
        return 1;
      case 'PPT':
        return 2;
      case 'UP2':
        return 3;
      case 'PAT':
        return 4;
      case 'PUPK':
        return 5;
      default:
        return null;
    }
  }

  Widget _buildDataTable() {
    if (studentsProgress.isEmpty) return Container(); // No data to display

    return DataTable(
      columns: const [
        DataColumn(label: Text('UP1')),
        DataColumn(label: Text('PPT')),
        DataColumn(label: Text('UP2')),
        DataColumn(label: Text('PAT')),
        DataColumn(label: Text('PUPK')),
      ],
      rows: studentsProgress.entries.map((entry) {
        final progress = entry.value;
        return DataRow(cells: [
          DataCell(Text(progress['UP1'] ?? '-')),
          DataCell(Text(progress['PPT'] ?? '-')),
          DataCell(Text(progress['UP2'] ?? '-')),
          DataCell(Text(progress['PAT'] ?? '-')),
          DataCell(Text(progress['PUPK'] ?? '-')),
        ]);
      }).toList(),
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
            'View Student Progress',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Choose Subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              value: _selectedSubject,
              items: subjects.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject['id'],
                  child: Text(subject['name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                  if (_selectedSubject != 'Choose Subject') {
                    _fetchStudentProgressBySubject(_selectedSubject);
                  } else {
                    studentsProgress = {}; // Clear progress if no subject is selected
                  }
                });
              },
            ),
            const SizedBox(height: 16.0),
            if (studentsProgress.isNotEmpty) _buildGraph(),
            if (studentsProgress.isNotEmpty) _buildDataTable(),
            if (studentsProgress.isEmpty) const Center(child: Text('No data available for the selected subject.')),
          ],
        ),
      ),
    );
  }
}