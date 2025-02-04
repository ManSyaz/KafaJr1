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
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');

  String _selectedSubject = 'Choose Subject';
  String _selectedStudentId = '';
  Map<String, String> studentNames = {};
  List<Map<String, String>> subjects = [];
  Map<String, Map<String, String>> studentsProgress = {};
  List<Map<String, dynamic>> examTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
    _fetchSubjects();
    _fetchStudents();
    _selectedStudentId = _getLoggedInStudentId();
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

    print('Selected Student ID: $_selectedStudentId'); // Debugging line
    print('Fetching progress for subject ID: $subjectId'); // Debugging line

    try {
      final snapshot = await _progressRef
          .orderByChild('studentId')
          .equalTo(_selectedStudentId)
          .get();

      if (snapshot.exists) {
        final progressData = snapshot.value as Map<Object?, Object?>;
        print('Progress Data: $progressData'); // Debugging line

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
              String score = progress['score']?.toString() ?? '0';

              // Store the score for the exam description
              map[studentId]![examDescription] = score;
            }
            return map;
          },
        );

        setState(() {
          studentsProgress = filteredProgress; // Update state with fetched data
        });
      } else {
        print('No snapshot exists for student ID: $_selectedStudentId'); // Debugging line
      }
    } catch (e) {
      print('Error fetching student progress: $e');
    }
  }

  Future<void> _fetchExams() async {
    try {
      final snapshot = await _examRef.get();
      if (snapshot.exists) {
        final examData = snapshot.value as Map<Object?, Object?>;
        setState(() {
          examTypes = examData.entries.map((entry) {
            final exam = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            return {
              'id': entry.key.toString(),
              'description': exam['description'] ?? '',
              'title': exam['title'] ?? '',
            };
          }).toList();
          
          // Sort by description to maintain consistent order
          examTypes.sort((a, b) => a['description'].compareTo(b['description']));
        });
      }
    } catch (e) {
      print('Error fetching exams: $e');
    }
  }

  Widget _buildGraph() {
    if (studentsProgress.isEmpty) return Container();

    final dataEntries = examTypes.asMap().entries.map((entry) {
      final index = entry.key;
      final examType = entry.value['description'];
      final yValue = double.tryParse(studentsProgress.values.first[examType] ?? '0') ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: yValue,
            color: _getScoreColor(yValue),
            width: 30,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Colors.grey[200],
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      width: 350,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exam Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 16.0,
                  children: [
                    _buildLegendItem('A (≥80)', const Color(0xFF4CAF50)),
                    _buildLegendItem('B (≥60)', const Color(0xFF2196F3)),
                    _buildLegendItem('C (≥40)', const Color(0xFFFFA726)),
                    _buildLegendItem('D (<40)', const Color(0xFFE53935)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barGroups: dataEntries,
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < examTypes.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Tooltip(
                                  message: examTypes[index]['title'],
                                  child: Text(
                                    examTypes[index]['description'],
                                    style: TextStyle(
                                      fontSize: examTypes.length <= 5 ? 12 : 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 40,
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final examType = examTypes[group.x.toInt()];
                          final value = rod.toY.round();
                          final grade = _getGradeText(value.toString());
                          return BarTooltipItem(
                            '${examType['title']}\n$value% (Grade $grade)',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: const Text(
                  'PAT: Peperiksaan Awal Tahun\n'
                  'PPT: Peperiksaan Pertengahan Tahun\n'
                  'PUPKK: Percubaan Ujian Penilaian KAFA',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add helper functions for grade and color
  String _getGradeText(String? scoreStr) {
    final score = double.tryParse(scoreStr ?? '0') ?? 0;
    if (score >= 80 && score <= 100) {
      return 'A';
    } else if (score >= 60 && score < 80) {
      return 'B';
    } else if (score >= 40 && score < 60) {
      return 'C';
    } else if (score >= 1 && score < 40) {
      return 'D';
    } else {
      return 'N/A';
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDataTable() {
    if (studentsProgress.isEmpty) return Container();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Scores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                  ),
                ),
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 12,
                  columns: examTypes.map((exam) => DataColumn(
                    label: Container(
                      alignment: Alignment.center,
                      width: 100,
                      child: Tooltip(
                        message: exam['title'],
                        child: Text(
                          exam['description'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )).toList(),
                  rows: studentsProgress.entries.map((entry) {
                    return DataRow(
                      cells: examTypes.map((exam) => DataCell(
                        Container(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _getScoreColor(double.tryParse(entry.value[exam['description']] ?? '0') ?? 0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  entry.value[exam['description']] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getGradeText(entry.value[exam['description']]),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add helper widget for legend items
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the student's name using the selected ID
    String studentName = studentNames[_selectedStudentId] ?? 'Unknown Student';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'View Student Progress',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFF0C6B58)),
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
                    studentsProgress = {};
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            // Display student name card only after subject is selected
            if (_selectedStudentId.isNotEmpty && _selectedSubject != 'Choose Subject')
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF0C6B58)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (studentsProgress.isNotEmpty) ...[
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildGraph(),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 350,
                  child: _buildDataTable(),
                ),
              ),
            ],
            if (studentsProgress.isEmpty && _selectedSubject != 'Choose Subject')
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No data available for the selected subject.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}