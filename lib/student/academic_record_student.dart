// ignore_for_file: library_private_types_in_public_api, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ViewAcademicRecordPage extends StatefulWidget {
  const ViewAcademicRecordPage({super.key});

  @override
  _ViewAcademicRecordPageState createState() => _ViewAcademicRecordPageState();
}

class _ViewAcademicRecordPageState extends State<ViewAcademicRecordPage> {
  final DatabaseReference _progressRef = FirebaseDatabase.instance.ref().child('Progress');
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref().child('User');

  String _selectedExam = 'Choose Exam';
  String _selectedStudentId = '';
  String _studentName = '';
  Map<String, String> subjectCodes = {};
  List<Map<String, String>> exams = [];
  Map<String, Map<String, String>> studentsProgress = {};
  Map<String, Map<String, String>> studentProgressByExam = {};

  @override
  void initState() {
    super.initState();
    _selectedStudentId = _getLoggedInStudentId();
    _fetchExams();
    _fetchSubjects();
    _fetchStudentName();
  }

  String _getLoggedInStudentId() {
    // Get the current user from Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? ''; // Return the user's ID or an empty string if not logged in
  }

  Future<void> _fetchExams() async {
    try {
      final snapshot = await _examRef.get();
      if (snapshot.exists) {
        final examData = snapshot.value as Map<Object?, Object?>?;
        if (examData != null) {
          setState(() {
            exams = [
              {'id': 'Choose Exam', 'title': 'Choose Exam', 'description': 'Choose Exam'}
            ] + examData.entries.map((entry) {
              final examMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'id': entry.key?.toString() ?? 'Unknown',
                'title': examMap['title']?.toString() ?? 'Unknown',
                'description': examMap['description']?.toString() ?? 'Unknown',
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching exams: $e');
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final snapshot = await _subjectRef.get();
      if (snapshot.exists) {
        final subjectData = snapshot.value as Map<Object?, Object?>?;
        if (subjectData != null) {
          setState(() {
            subjectCodes = subjectData.entries.fold<Map<String, String>>(
              {},
              (map, entry) {
                final subjectMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
                final subjectId = entry.key?.toString() ?? 'Unknown';
                final subjectCode = subjectMap['code']?.toString() ?? 'Unknown';
                map[subjectId] = subjectCode;
                return map;
              },
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  Future<void> _fetchStudentName() async {
    try {
      final snapshot = await _userRef.child(_selectedStudentId).get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map<Object?, Object?>;
        setState(() {
          _studentName = userData['fullName']?.toString() ?? 'Unknown Student';
        });
      }
    } catch (e) {
      print('Error fetching student name: $e');
    }
  }

  Future<void> _fetchStudentProgressByExam(String examId) async {
    try {
      // First, ensure we have the student name
      await _fetchStudentName();  // Add this line to refresh the student name

      final exam = exams.firstWhere((exam) => exam['id'] == examId);
      final examDescription = exam['description'];

      final snapshot = await _progressRef
          .orderByChild('examDescription')
          .equalTo(examDescription)
          .get();

      if (snapshot.exists) {
        final progressData = snapshot.value as Map<Object?, Object?>;

        final filteredProgress = progressData.entries.fold<Map<String, Map<String, String>>>(
          {},
          (map, entry) {
            final progress = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            final studentId = progress['studentId'] ?? '-';
            final subjectId = progress['subjectId'] ?? '-';
            final subjectCode = subjectCodes[subjectId] ?? 'Unknown';

            if (studentId == _selectedStudentId) { // Only include progress for the logged-in student
              if (!map.containsKey(studentId)) {
                map[studentId] = {
                  'examDescription': examDescription ?? 'Unknown', // Ensure examDescription is set here
                };
              }

              map[studentId]![subjectCode] = progress['score']?.toString() ?? '-';
            }
            return map;
          },
        );

        setState(() {
          studentsProgress = filteredProgress;
          studentProgressByExam[examId] = studentsProgress[_selectedStudentId] ?? {};
        });

        // Debug print to check values
        print('Student Name: $_studentName');
        print('Selected Exam: $_selectedExam');
        print('Students Progress: $studentsProgress');
        print('Student Progress by Exam: $studentProgressByExam');
      } else {
        setState(() {
          studentsProgress = {};
          studentProgressByExam = {};
        });
      }
    } catch (e) {
      print('Error fetching student progress by exam: $e');
    }
  }

  // Add helper method to get color based on score
  Color _getScoreColor(double score) {
    if (score >= 80) {
      return const Color(0xFF4CAF50); // Green for A
    } else if (score >= 60) {
      return const Color(0xFF2196F3); // Blue for B
    } else if (score >= 40) {
      return const Color(0xFFFFA726); // Orange for C
    } else {
      return const Color(0xFFE53935); // Red for D
    }
  }

  Widget _buildGraph() {
    if (studentProgressByExam.isEmpty) return Container();

    final subjectList = subjectCodes.values.toList();
    
    return Column(
      children: [
        // Subject Legend Card
        Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0C6B58).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: const Color(0xFF0C6B58).withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Subject Legend',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0C6B58),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubjectLegendItem('SR', 'Sirah'),
                          _buildSubjectLegendItem('AS', 'Amali Solat'),
                          _buildSubjectLegendItem('US', 'Ulum Syari\'ah'),
                          _buildSubjectLegendItem('JK', 'Jawi & Khat'),
                        ],
                      ),
                    ),
                    // Right column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubjectLegendItem('LQ', 'Lughatul Quran'),
                          _buildSubjectLegendItem('BAQ', 'Bidang Al-Quran'),
                          _buildSubjectLegendItem('AD', 'Adab'),
                          _buildSubjectLegendItem('PCHI', 'Penghayatan Cara Hidup Islam'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Scrollable Subject Cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: subjectList.map((subjectCode) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  width: 350,
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject: $subjectCode',
                            style: const TextStyle(
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
                                barGroups: () {
                                  // Use actual exams from the data structure
                                  final examsList = exams.where((exam) => 
                                    exam['id'] != 'Choose Exam' && 
                                    exam['description'] != null
                                  ).toList();

                                  return List.generate(
                                    examsList.length,
                                    (index) => BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: double.tryParse(
                                            studentProgressByExam[examsList[index]['id']]?[subjectCode] ?? '0'
                                          ) ?? 0,
                                          color: _getScoreColor(double.tryParse(
                                            studentProgressByExam[examsList[index]['id']]?[subjectCode] ?? '0'
                                          ) ?? 0),
                                          width: 30,
                                          borderRadius: BorderRadius.circular(4),
                                          backDrawRodData: BackgroundBarChartRodData(
                                            show: true,
                                            toY: 100,
                                            color: Colors.grey[200],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }(),
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
                                        final examsList = exams.where((exam) => 
                                          exam['id'] != 'Choose Exam' && 
                                          exam['description'] != null
                                        ).toList();
                                        
                                        if (value >= 0 && value < examsList.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              examsList[value.toInt()]['description'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 40,
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    tooltipPadding: const EdgeInsets.all(8),
                                    tooltipMargin: 8,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final examsList = exams.where((exam) => 
                                        exam['id'] != 'Choose Exam' && 
                                        exam['description'] != null
                                      ).toList();
                                      
                                      final examType = examsList[group.x]['description'] ?? '';
                                      final value = rod.toY.round();
                                      final grade = _getGradeText(value.toString());
                                      return BarTooltipItem(
                                        '$examType\n$value% (Grade $grade)',
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
                          // Update exam abbreviation legend to be dynamic
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              exams.where((exam) => exam['id'] != 'Choose Exam')
                                  .map((exam) => 
                                    '${exam['description']}: ${exam['title']}')
                                  .join('\n'),
                              style: const TextStyle(
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
                ),
              );
            }).toList(),
          ),
        ),
      ],
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

  // Add helper widget for subject legend items
  Widget _buildSubjectLegendItem(String code, String name) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0C6B58).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF0C6B58).withOpacity(0.2),
              ),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C6B58),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
            'View Academic Records',
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
                labelText: 'Choose Exam',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFF0C6B58)),
                ),
              ),
              value: _selectedExam,
              items: exams.map((exam) {
                return DropdownMenuItem<String>(
                  value: exam['id'],
                  child: Text(exam['title'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedExam = value!;
                  if (_selectedExam != 'Choose Exam') {
                    _fetchStudentProgressByExam(_selectedExam);
                  } else {
                    studentProgressByExam = {};
                  }
                });
              },
            ),
            const SizedBox(height: 16.0),
            if (_selectedExam != 'Choose Exam')
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
                          _studentName.isNotEmpty ? _studentName : 'Loading...',
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
            if (studentProgressByExam.isNotEmpty) _buildGraph(),
            if (studentProgressByExam.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
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
                            columns: [
                              const DataColumn(
                                label: Text(''),
                              ),
                              ...subjectCodes.values.map((code) => DataColumn(
                                label: Container(
                                  alignment: Alignment.center,
                                  width: 100,
                                  child: Text(
                                    code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )),
                            ],
                            rows: studentProgressByExam.entries.map((entry) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    entry.value['examDescription'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  )),
                                  ...subjectCodes.values.map((code) => DataCell(
                                    Container(
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: _getScoreColor(double.tryParse(entry.value[code] ?? '0') ?? 0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              entry.value[code] ?? '-',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _getGradeText(entry.value[code]),
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
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}