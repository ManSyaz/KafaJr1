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

  String _selectedStudentName = 'Choose Student';
  List<Map<String, String>> studentList = [
    {'id': 'Choose Student', 'name': 'Choose Student'}
  ];

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

            studentList = [
              {'id': 'Choose Student', 'name': 'Choose Student'}
            ] + studentData.entries.map((entry) {
              final studentMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'id': entry.key?.toString() ?? 'Unknown',
                'name': studentMap['fullName']?.toString() ?? 'Unknown',
              };
            }).toList();
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
      final snapshot = await _progressRef
          .orderByChild('examId')
          .equalTo(examId)
          .get();

      if (snapshot.exists) {
        final progressData = snapshot.value as Map<Object?, Object?>;
        Map<String, Map<String, String>> newProgress = {};

        // Initialize the map for the selected exam with all subject codes
        if (_selectedFilter == 'Student') {
          newProgress[examId] = {
            'examDescription': '',
            'examTitle': exams.firstWhere((e) => e['id'] == examId)['title'] ?? '',
          };
          // Initialize all subject scores to '0'
          for (var code in subjectCodes.values) {
            newProgress[examId]![code] = '0';
          }
        }

        // Process each progress entry
        for (var entry in progressData.entries) {
          final progress = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
          final studentId = progress['studentId']?.toString() ?? '-';
          final subjectId = progress['subjectId']?.toString() ?? '-';
          final subjectCode = subjectCodes[subjectId] ?? 'Unknown';
          final score = progress['score']?.toString() ?? '-';

          if (_selectedFilter == 'Student' && studentId == _selectedStudentId) {
            newProgress[examId]!['examDescription'] = progress['examDescription']?.toString() ?? '';
            newProgress[examId]![subjectCode] = score;
          } else if (_selectedFilter == 'All') {
            if (!newProgress.containsKey(studentId)) {
              newProgress[studentId] = {
                'name': studentNames[studentId] ?? 'Unknown',
              };
              // Initialize all subject scores to '0'
              for (var code in subjectCodes.values) {
                newProgress[studentId]![code] = '0';
              }
            }
            newProgress[studentId]![subjectCode] = score;
          }
        }

        setState(() {
          if (_selectedFilter == 'Student') {
            studentProgressByExam = {
              ...studentProgressByExam,
              ...newProgress,
            };
            studentsProgress = studentProgressByExam;
          } else {
            studentsProgress = newProgress;
          }
        });

      } else {
        if (_selectedFilter == 'All') {
          setState(() {
            studentsProgress = {};
          });
        }
      }
    } catch (e) {
      print('Error fetching student progress by exam: $e');
    }
  }

  void _clearExamHistory() {
    setState(() {
      studentProgressByExam = {};
      studentsProgress = {};
    });
  }

  Color _getScoreColor(double score) {
    if (score >= 80) {
      return const Color(0xFF4CAF50); // Green for A
    } else if (score >= 60) {
      return const Color(0xFF2196F3); // Blue for B
    } else if (score >= 40) {
      return const Color(0xFFFFA726); // Orange for C
    } else if (score >= 0) {
      return const Color(0xFFE53935); // Red for D
    } else {
      return Colors.grey; // Red for D
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
                                  // Define the desired order
                                  final examOrder = ['PAT', 'PPT', 'PUPKK'];
                                  
                                  // Create a sorted list of exams based on the desired order
                                  final sortedExams = examOrder.map((examType) {
                                    return exams.firstWhere(
                                      (exam) => exam['description'] == examType,
                                      orElse: () => {'id': '', 'description': examType},
                                    );
                                  }).toList();

                                  return List.generate(
                                    sortedExams.length,
                                    (index) => BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: double.tryParse(
                                            studentProgressByExam[sortedExams[index]['id']]?[subjectCode] ?? '0'
                                          ) ?? 0,
                                          color: _getScoreColor(double.tryParse(
                                            studentProgressByExam[sortedExams[index]['id']]?[subjectCode] ?? '0'
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
                                        final examOrder = ['PAT', 'PPT', 'PUPKK'];
                                        if (value >= 0 && value < examOrder.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              examOrder[value.toInt()],
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
                                      final examOrder = ['PAT', 'PPT', 'PUPKK'];
                                      final examType = examOrder[group.x];
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
                          // Add exam abbreviation legend below the graph
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: const Text(
                              'PAT: Peperiksaan Awal Tahun\n'
                              'PPT: Peperiksaan Pertengahan Tahun\n'
                              'PUPKK: Percubaan Ujian Penilaian Kelas KAFA',
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
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
    if (scoreStr == null || scoreStr == '0') {
      return 'N/A';
    }
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
    // Determine if the score is N/A
    final displayScore = (score == null || score == '0') ? '-' : score;
    final numericScore = double.tryParse(score ?? '0') ?? 0;

    return Container(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: _getScoreColor(numericScore),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayScore,
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

  String _formatLongName(String name) {
    final words = name.split(' ');
    if (words.length <= 3) return name; // Return as is if name is short

    // Find the middle point, preferring to break after "BIN" or "BINTI" if present
    int breakPoint = words.length ~/ 2;
    for (int i = 0; i < words.length; i++) {
      if (words[i].toUpperCase() == 'BIN' || words[i].toUpperCase() == 'BINTI') {
        breakPoint = i;
        break;
      }
    }

    // Join the words with a line break
    final firstLine = words.sublist(0, breakPoint).join(' ');
    final secondLine = words.sublist(breakPoint).join(' ');
    return '$firstLine\n$secondLine';
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'Academic Records',
            style: TextStyle(color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                    _clearExamHistory();
                  });
                },
                selectedColor: Colors.white,
                fillColor: const Color(0xFF0C6B58),
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
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Student',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  value: _selectedStudentName,
                  items: studentList.map((student) {
                    return DropdownMenuItem<String>(
                      value: student['id'],
                      child: Text(
                        student['name'] ?? 'Unknown',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStudentName = value!;
                      if (_selectedStudentName != 'Choose Student') {
                        _selectedStudentId = value;
                        _fullName = studentNames[value] ?? '';
                        _selectedExam = 'Choose Exam';
                        _clearExamHistory(); // Clear history when new student is selected
                      } else {
                        _selectedStudentId = '';
                        _fullName = '';
                        _selectedExam = 'Choose Exam';
                        _clearExamHistory();
                      }
                    });
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
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Color(0xFF0C6B58)),
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
                          _clearExamHistory(); // Clear history when "Choose Exam" is selected
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
                      child: Container(
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
                                      color: Color(0xFF0C6B58),
                                      fontSize: 14,
                                    ),
                                    dataTextStyle: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                                        }
                                        return null;
                                      },
                                    ),
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
                                                    (entry.value[code] == null || entry.value[code] == '0') ? '-' : entry.value[code]!,
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
              ],
              if (_selectedFilter == 'All') ...[
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Choose Exam',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFF0C6B58)),
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
                        _clearExamHistory(); // Clear history when "Choose Exam" is selected
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
                                      DataCell(SizedBox(
                                        width: 200, // Adjust width as needed
                                        child: Text(
                                          _formatLongName(progress['name'] ?? '-'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.2,
                                          ),
                                          softWrap: true,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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