// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class ManageAcademicRecordPage extends StatefulWidget {
  const ManageAcademicRecordPage({super.key});

  @override
  _ManageAcademicRecordPageState createState() =>
      _ManageAcademicRecordPageState();
}

class _ManageAcademicRecordPageState
    extends State<ManageAcademicRecordPage> {
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref().child('Student');
  final DatabaseReference _progressRef =
      FirebaseDatabase.instance.ref().child('Progress');
  final DatabaseReference _examRef =
      FirebaseDatabase.instance.ref().child('Exam');
  final DatabaseReference _subjectRef =
      FirebaseDatabase.instance.ref().child('Subject');

  String _selectedFilter = 'All';
  String _selectedExam = 'Choose Exam';
  String _fullName = '';
  String _selectedStudentId = '';
  Map<String, String> studentNames = {};
  Map<String, String> subjectCodes = {};
  List<Map<String, String>> exams = [];
  Map<String, Map<String, String>> studentsProgress = {};
  Map<String, Map<String, String>> studentProgressByExam = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExams();
    _fetchStudents();
    _fetchSubjects();
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
            ] +
                examData.entries.map((entry) {
                  final examMap =
                      Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
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
                final studentMap =
                    Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
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
                final subjectMap =
                    Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
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

  Future<void> _fetchStudentProgressByExam(String examId) async {
    try {
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

            if (!map.containsKey(studentId)) {
              map[studentId] = {
                'name': studentNames[studentId] ?? 'Unknown',
              };
            }

            map[studentId]![subjectCode] = progress['score']?.toString() ?? '-';
            return map;
          },
        );

        setState(() {
          studentsProgress = filteredProgress;
          studentProgressByExam[examId] = studentsProgress[_selectedStudentId] ?? {};
        });

        // Debug print
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

  Future<void> _searchStudentByIC() async {
    final icNumber = _searchController.text;
    try {
        final snapshot = await _userRef.get();
        if (snapshot.exists) {
            final userData = snapshot.value as Map<Object?, Object?>?;
            if (userData != null) {
                final Map<String, dynamic> userMap = Map<String, dynamic>.from(userData);

                // Find the student by IC number
                final matchedStudent = userMap.entries.firstWhere(
                    (entry) {
                        final studentMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
                        final studentIC = studentMap['icNumber']?.toString() ?? '';
                        return studentIC == icNumber; // Match by IC number
                    },
                    orElse: () => const MapEntry('', {}),
                );

                if (matchedStudent.value.isNotEmpty) {
                    final studentId = matchedStudent.key;
                    final studentMap = Map<String, dynamic>.from(matchedStudent.value as Map<Object?, Object?>);
                    setState(() {
                        _fullName = studentMap['fullName'] ?? 'Unknown';
                        _selectedStudentId = studentId;
                        _selectedExam = 'Choose Exam'; // Reset exam selection
                        studentProgressByExam = {}; // Clear previous data
                    });
                } else {
                    setState(() {
                        _fullName = 'Student not found';
                        studentProgressByExam = {};
                    });
                }
            }
        }
    } catch (e) {
        print('Error searching for student by IC: $e');
        setState(() {
            _fullName = 'Error occurred';
            studentProgressByExam = {};
        });
    }
  }

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
    final dataEntries = subjectList.asMap().entries.map((entry) {
      final index = entry.key;
      final code = entry.value;
      final yValue = double.tryParse(studentProgressByExam[_selectedExam]?[code] ?? '0') ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: yValue,
            color: _getScoreColor(yValue), // Use grade color based on score
            width: subjectList.length <= 3 ? 40 : (subjectList.length <= 5 ? 30 : 20),
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Performance',
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
              height: 400,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: subjectList.length <= 3 ? 40.0 : 16.0,
                ),
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
                            if (index >= 0 && index < subjectList.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  subjectList[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
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
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                          final subject = subjectList[group.x.toInt()];
                          final value = rod.toY.round();
                          final grade = _getGradeText(value.toString());
                          return BarTooltipItem(
                            '$subject\n$value% (Grade $grade)',
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
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildScoreCell(String? score) {
    return Container(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: _getScoreColor(double.tryParse(score ?? '0') ?? 0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              score ?? '-',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getGradeText(score),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Container(
          padding: const EdgeInsets.only(right: 48.0), // Adjust right padding for space
          alignment: Alignment.center, // Center the title
          child: const Text(
            'Academic Records',
            style: TextStyle(color: Colors.white), // Change text color
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Change back icon color
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleButtons(
                isSelected: [_selectedFilter == 'All', _selectedFilter == 'Student'],
                onPressed: (index) {
                  setState(() {
                    _selectedFilter = index == 0 ? 'All' : 'Student';
                    _fullName = '';
                    _selectedStudentId = '';
                    _selectedExam = 'Choose Exam';
                    studentProgressByExam = {};
                    studentsProgress = {};
                  });
                },
                selectedColor: Colors.white,
                fillColor: Colors.pinkAccent,
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.0),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Text('All'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Text('Student'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              if (_selectedFilter == 'Student') ...[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by IC Number',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.pinkAccent),
                    ),
                  ),
                  onSubmitted: (value) {
                    _searchStudentByIC();
                  },
                ),
                const SizedBox(height: 16.0),
                if (_fullName.isNotEmpty && _selectedStudentId.isNotEmpty) ...[
                  Text(
                    'Full Name: \n$_fullName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Choose Exam',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0), // Rounded corners
                        borderSide: const BorderSide(color: Colors.pinkAccent), // Border color
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
                          studentProgressByExam = {}; // Clear progress if no exam is selected
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  if (_selectedExam != 'Choose Exam' && studentProgressByExam.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assessment_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Academic Record Found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No exam scores recorded for ${exams.firstWhere((exam) => exam['id'] == _selectedExam)['title']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else if (studentProgressByExam.isNotEmpty)
                    _buildGraph(),
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
                                                columns: subjectCodes.values.map((code) => DataColumn(
                                                    label: SizedBox(
                                                        width: 100,
                                                        child: Text(
                                                            code,
                                                            textAlign: TextAlign.center,
                                                            style: const TextStyle(fontSize: 14),
                                                        ),
                                                    ),
                                                )).toList(),
                                                rows: [
                                                    DataRow(
                                                        cells: subjectCodes.values.map((code) => 
                                                            DataCell(_buildScoreCell(studentProgressByExam[_selectedExam]?[code]))
                                                        ).toList(),
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                  ],
                ],
              ],
              if (_selectedFilter == 'All') ...[
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Choose Exam',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0), // Rounded corners
                      borderSide: const BorderSide(color: Colors.pinkAccent), // Border color
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
                        studentsProgress = {}; // Clear progress if no exam is selected
                      }
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                if (_selectedExam != 'Choose Exam' && studentsProgress.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Academic Records Found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No exam scores recorded for ${exams.firstWhere((exam) => exam['id'] == _selectedExam)['title']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (studentsProgress.isNotEmpty) ...[
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'All Students Scores',
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
                                    label: Text(
                                      'Name',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  ...subjectCodes.values.map((code) => DataColumn(
                                    label: Container(
                                      width: 100,
                                      alignment: Alignment.center,
                                      child: Text(
                                        code,
                                        style: const TextStyle(fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )),
                                ],
                                rows: studentsProgress.entries.map((entry) {
                                  final progress = entry.value;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(
                                        progress['name'] ?? '-',
                                        style: const TextStyle(fontSize: 14),
                                      )),
                                      ...subjectCodes.values.map((code) => 
                                        DataCell(_buildScoreCell(progress[code]))
                                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}