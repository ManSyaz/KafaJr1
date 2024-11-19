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

  String _selectedFilter = 'All';
  String _selectedSubject = 'Choose Subject';
  String _fullName = '';
  String _selectedStudentId = '';
  Map<String, String> studentNames = {};
  List<Map<String, String>> subjects = [];
  Map<String, Map<String, String>> studentsProgress = {};
  Map<String, String>? studentProgress;

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

    final examTypes = ['UP1', 'PPT', 'UP2', 'PAT', 'PUPK'];
    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFFC107), // Amber
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
    ];

    final dataEntries = examTypes.asMap().entries.map((entry) {
      final index = entry.key;
      final examType = entry.value;
      final yValue = double.tryParse(studentProgress![examType] ?? '0') ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: yValue,
            color: colors[index % colors.length],
            width: 20,
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
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
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
                              child: Text(
                                examTypes[index],
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
                        final examType = examTypes[group.x.toInt()];
                        final value = rod.toY.round();
                        return BarTooltipItem(
                          '$examType\n$value%',
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
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
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

              // Student Filter Section
              if (_selectedFilter == 'Student') ...[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by IC Number',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
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
                                    headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                                  ),
                                ),
                                child: DataTable(
                                  columnSpacing: 24,
                                  horizontalMargin: 12,
                                  columns: const [
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: Text(
                                          'UP1',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: Text(
                                          'PPT',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: Text(
                                          'UP2',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: Text(
                                          'PAT',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 100,
                                        child: Text(
                                          'PUPK',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: [
                                    DataRow(
                                      cells: [
                                        DataCell(_buildScoreCell(studentProgress!['UP1'])),
                                        DataCell(_buildScoreCell(studentProgress!['PPT'])),
                                        DataCell(_buildScoreCell(studentProgress!['UP2'])),
                                        DataCell(_buildScoreCell(studentProgress!['PAT'])),
                                        DataCell(_buildScoreCell(studentProgress!['PUPK'])),
                                      ],
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
                if (studentsProgress.isNotEmpty)
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
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
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
                                  ...['UP1', 'PPT', 'UP2', 'PAT', 'PUPK'].map((type) => DataColumn(
                                    label: Container(
                                      width: 100,
                                      alignment: Alignment.center,
                                      child: Text(
                                        type,
                                        style: const TextStyle(fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )).toList(),
                                ],
                                rows: studentsProgress.entries.map((entry) {
                                  final progress = entry.value;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(
                                        progress['name'] ?? '-',
                                        style: const TextStyle(fontSize: 14),
                                      )),
                                      DataCell(_buildScoreCell(progress['UP1'])),
                                      DataCell(_buildScoreCell(progress['PPT'])),
                                      DataCell(_buildScoreCell(progress['UP2'])),
                                      DataCell(_buildScoreCell(progress['PAT'])),
                                      DataCell(_buildScoreCell(progress['PUPK'])),
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