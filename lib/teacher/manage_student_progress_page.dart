// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
// ignore: unused_import
import 'dart:math';

class ManageStudentProgressPage extends StatefulWidget {
  const ManageStudentProgressPage({super.key});

  @override
  _ManageStudentProgressPageState createState() =>
      _ManageStudentProgressPageState();
}

class _ManageStudentProgressPageState
    extends State<ManageStudentProgressPage> {
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref().child('Student');
  final DatabaseReference _progressRef =
      FirebaseDatabase.instance.ref().child('Progress');
  final DatabaseReference _subjectRef =
      FirebaseDatabase.instance.ref().child('Subject');
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');

  String _selectedFilter = 'All';
  String _selectedSubject = 'Choose Subject';
  String _fullName = '';
  String _selectedStudentId = '';
  Map<String, String> studentNames = {};
  List<Map<String, String>> subjects = [];
  Map<String, Map<String, String>> studentsProgress = {};
  Map<String, String>? studentProgress;
  List<Map<String, dynamic>> examTypes = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExams();
    _fetchSubjects();
    _fetchStudents();
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

  Future<void> _fetchSubjects() async {
    try {
      final snapshot = await _subjectRef.get();
      if (snapshot.exists) {
        final subjectData = snapshot.value as Map<Object?, Object?>?;
        if (subjectData != null) {
          setState(() {
            subjects = [
              {'id': 'Choose Subject', 'name': 'Choose Subject'}
            ] +
                subjectData.entries.map((entry) {
                  final subjectMap =
                      Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
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

  Future<void> _fetchStudentProgressBySubject(String subjectId) async {
    try {
      final snapshot = await _progressRef
          .orderByChild('subjectId')
          .equalTo(subjectId)
          .get();

      if (snapshot.exists) {
        final progressData = snapshot.value as Map<Object?, Object?>;

        final filteredProgress = progressData.entries.fold<Map<String, Map<String, String>>>(
          {},
          (map, entry) {
            final progress = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            final studentId = progress['studentId'] ?? '-';

            if (!map.containsKey(studentId)) {
              map[studentId] = {
                'name': studentNames[studentId] ?? 'Unknown',
                'UP1': '-',
                'PPT': '-',
                'UP2': '-',
                'PAT': '-',
                'PUPK': '-',
              };
            }

            map[studentId]![progress['examDescription'] ?? ''] = progress['score']?.toString() ?? '-';
            return map;
          },
        );

        setState(() {
          studentsProgress = filteredProgress; // Update state with fetched data
        });
      } else {
        setState(() {
          studentsProgress = {}; // Clear progress if no data found
        });
      }
    } catch (e) {
      print('Error fetching student progress by subject: $e');
    }
  }

  Future<void> _searchStudentByICNumber(String icNumber) async {
    try {
      final snapshot = await _userRef.get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map<Object?, Object?>?;
        if (userData != null) {
          final Map<String, dynamic> userMap = Map<String, dynamic>.from(userData);

          final matchedStudent = userMap.entries.firstWhere(
            (entry) {
              final studentMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              final studentICNumber = studentMap['icNumber'] as String?;
              return studentICNumber != null && studentICNumber == icNumber; // Match by IC Number
            },
            orElse: () => const MapEntry<String, dynamic>('none', {}),
          );

          if (matchedStudent.key != 'none') {
            final studentMap = Map<String, dynamic>.from(matchedStudent.value as Map<Object?, Object?>);
            final studentId = matchedStudent.key;
            setState(() {
              _fullName = studentMap['fullName'] ?? 'Unknown';
              _selectedStudentId = studentId;
              _selectedSubject = 'Choose Subject'; // Reset subject selection
              studentProgress = null; // Clear previous progress
              studentsProgress = {}; // Clear previous data
            });
          } else {
            setState(() {
              _fullName = 'Student not found';
              studentProgress = null;
              studentsProgress = {};
            });
          }
        }
      }
    } catch (e) {
      print('Error searching for student by IC Number: $e');
      setState(() {
        _fullName = 'Error occurred';
        studentProgress = null;
        studentsProgress = {};
      });
    }
  }

  Future<void> _fetchStudentProgress() async {
    if (_selectedStudentId.isEmpty || _selectedSubject == 'Choose Subject') {
      return; // Do not fetch if no student or subject is selected
    }

    try {
      final snapshot = await _progressRef
          .orderByChild('studentId')
          .equalTo(_selectedStudentId)
          .get();

      if (snapshot.exists) {
        final progressData = snapshot.value as Map<Object?, Object?>;

        var studentProgress = progressData.entries.fold<Map<String, String>>(
          {},
          (map, entry) {
            final progress = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            if (progress['subjectId'] == _selectedSubject) {
              map[progress['examDescription'] ?? ''] = progress['score']?.toString() ?? '-';
            }
            return map;
          },
        );

        setState(() {
          this.studentProgress = studentProgress; // Update state with fetched progress
        });
      } else {
        setState(() {
          studentProgress = null; // Clear progress if no data found
        });
      }
    } catch (e) {
      print('Error fetching student progress: $e');
    }
  }

  Widget _buildGraph() {
    if (studentProgress == null || studentProgress!.isEmpty) return Container();

    // Define grade colors
    final gradeColors = {
      'A': const Color(0xFF4CAF50), // Green for >= 80
      'B': const Color(0xFF2196F3), // Blue for >= 60
      'C': const Color(0xFFFFA726), // Orange for >= 40
      'D': const Color(0xFFE53935), // Red for < 40
    };

    // Helper function to get color based on score
    Color getGradeColor(double score) {
      if (score >= 80) return gradeColors['A']!;
      if (score >= 60) return gradeColors['B']!;
      if (score >= 40) return gradeColors['C']!;
      return gradeColors['D']!;
    }

    final dataEntries = examTypes.asMap().entries.map((entry) {
      final index = entry.key;
      final examType = entry.value['description'];
      final yValue = double.tryParse(studentProgress![examType] ?? '0') ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: yValue,
            color: getGradeColor(yValue), // Use grade color based on score
            width: examTypes.length <= 3 ? 40 : (examTypes.length <= 5 ? 30 : 20),
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
            // Add grade legend
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 16.0,
                children: [
                  _buildLegendItem('A (≥80)', gradeColors['A']!),
                  _buildLegendItem('B (≥60)', gradeColors['B']!),
                  _buildLegendItem('C (≥40)', gradeColors['C']!),
                  _buildLegendItem('D (<40)', gradeColors['D']!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: examTypes.length <= 3 ? 40.0 : 16.0,
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    minY: 0,
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
                      show: true,
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
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for legend items
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

  // Helper function to get grade text
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

  // Add this method to get colors based on score
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        title: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(right: 48.0),
          child: const Text(
            'Students Progress',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
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
              // Toggle Buttons
              ToggleButtons(
                isSelected: [_selectedFilter == 'All', _selectedFilter == 'Student'],
                onPressed: (index) {
                  setState(() {
                    _selectedFilter = index == 0 ? 'All' : 'Student';
                    _fullName = '';
                    _selectedStudentId = '';
                    _selectedSubject = 'Choose Subject';
                    studentProgress = null;
                    studentsProgress = {};
                  });
                },
                selectedColor: Colors.white,
                fillColor: const Color(0xFF0C6B58),
                color: Colors.black,
                borderColor: const Color(0xFF0C6B58),
                selectedBorderColor: const Color(0xFF0C6B58),
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

              // Student Filter Section
              if (_selectedFilter == 'Student') ...[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by IC Number',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0C6B58)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFF0C6B58)),
                    ),
                  ),
                  onSubmitted: (value) {
                    _searchStudentByICNumber(value);
                  },
                ),
                const SizedBox(height: 16.0),
                if (_fullName.isNotEmpty && _selectedStudentId.isNotEmpty) ...[
                  Text(
                    'Full Name:\n$_fullName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Choose Subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                          _fetchStudentProgress();
                        } else {
                          studentProgress = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  if (studentProgress != null) _buildGraph(),
                  if (studentProgress != null) ...[
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
                            Center(
                              child: SingleChildScrollView(
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
                                      ...examTypes.map((exam) => DataColumn(
                                        label: SizedBox(
                                          width: 100,
                                          child: Tooltip(
                                            message: exam['title'],
                                            child: Text(
                                              exam['description'],
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      )),
                                    ],
                                    rows: [
                                      DataRow(
                                        cells: [
                                          ...examTypes.map((exam) => DataCell(
                                            _buildScoreCell(studentProgress![exam['description']]),
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_selectedSubject != 'Choose Subject') ...[
                    const SizedBox(height: 24),
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
                            'No Progress Found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No exam scores recorded for ${subjects.firstWhere((subject) => subject['id'] == _selectedSubject)['name']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],

              // All Students Section
              if (_selectedFilter == 'All') ...[
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Choose Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                const SizedBox(height: 16.0),
                if (_selectedSubject != 'Choose Subject' && studentsProgress.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Student Progress Found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No exam scores recorded for ${subjects.firstWhere((subject) => subject['id'] == _selectedSubject)['name']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (studentsProgress.isNotEmpty)
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
                                      'Full Name',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  ...examTypes.map((exam) => DataColumn(
                                    label: Container(
                                      width: 100,
                                      alignment: Alignment.center,
                                      child: Tooltip(
                                        message: exam['title'],
                                        child: Text(
                                          exam['description'],
                                          style: const TextStyle(fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
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
                                      ...examTypes.map((exam) => DataCell(
                                        _buildScoreCell(progress[exam['description']]),
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
      ),
    );
  }

  // Add this helper method for building score cells
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
}