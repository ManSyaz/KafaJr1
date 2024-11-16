// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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
  String _fullName = '';
  String _selectedStudentId = '';
  Map<String, String> studentNames = {};
  List<Map<String, String>> subjects = [];
  Map<String, Map<String, String>> studentsProgress = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _fetchStudents();
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
                final studentId = entry.key?.toString() ?? 'Unknown'; // This is the unique ID
                final studentIcNumber = studentMap['icNumber']?.toString() ?? 'Unknown'; // Use IC number for searching
                // ignore: unused_local_variable
                final studentNames = studentMap['fullName'];
                map[studentIcNumber] = studentId; // Map IC number to student ID
                map[studentId] = studentNames;
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
        print('Progress Data for Student ID $_selectedStudentId: $progressData'); // Debugging output

        final filteredProgress = progressData.entries.fold<Map<String, Map<String, String>>>(
          {},
          (map, entry) {
            final progress = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            print('Checking progress entry: $progress'); // Debugging output

            // Check if the progress entry matches the subjectId
            if (progress['subjectId'] == subjectId) {
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
              String score = progress['score']?.toString() ?? '0'; // Use score instead of percentage

              // Store the score for the exam description
              map[studentId]![examDescription] = score;
            }
            return map;
          },
        );

        setState(() {
          studentsProgress = filteredProgress; // Update state with fetched data
          if (studentsProgress.isEmpty) {
            print('No progress data available for the selected subject.'); // Debugging output
          }
        });
      } else {
        print('No progress data found for student ID: $_selectedStudentId'); // Debugging output
      }
    } catch (e) {
      print('Error fetching student progress: $e');
    }
  }

  void _searchStudentByIcNumber(String icNumber) {
    final studentId = studentNames.entries.firstWhere(
      (entry) => entry.key.toLowerCase() == icNumber.toLowerCase(),
      orElse: () => const MapEntry('', ''),
    ).value;

    if (studentId.isNotEmpty) {
      setState(() {
        _selectedStudentId = studentId;
        _fullName = studentNames[icNumber] ?? '';
      });
    } else {
      // Handle case where student is not found
      setState(() {
        _fullName = 'Student not found';
        _selectedStudentId = '';
      });
    }
  }

  Widget _buildGraph() {
    if (studentsProgress.isEmpty) return Container(); // No data to display

    // Define a single color for all bars
    const Color barColor = Color.fromARGB(255, 105, 165, 243); // Light purple color

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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by IC Number', // Updated label for IC number
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) {
                _searchStudentByIcNumber(value); // Call the search method for IC number
              },
            ),
            const SizedBox(height: 16.0),
            if (_fullName.isNotEmpty && _selectedStudentId.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Full Name:\n${studentNames[_selectedStudentId] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
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
          ],
        ),
      ),
    );
  }
}