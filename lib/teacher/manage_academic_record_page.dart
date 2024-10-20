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

            map[studentId]![subjectCode] = progress['percentage']?.toString() ?? '-';
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

  Future<void> _searchStudentByName() async {
    final name = _searchController.text;
    try {
      final snapshot = await _userRef.get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map<Object?, Object?>?;
        if (userData != null) {
          final Map<String, dynamic> userMap = Map<String, dynamic>.from(userData);

          final lowerCaseName = name.toLowerCase();
          final matchedStudent = userMap.entries.firstWhere(
            (entry) {
              final studentMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              final fullName = studentMap['fullName']?.toString().toLowerCase() ?? '';
              return fullName.contains(lowerCaseName);
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
      print('Error searching for student: $e');
      setState(() {
        _fullName = 'Error occurred';
        studentProgressByExam = {};
      });
    }
  }

  Widget _buildGraph() {
    if (studentProgressByExam.isEmpty) return Container(); // No data to display

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
            color: const Color.fromARGB(255, 222, 105, 243), // Light purple color
            width: 50, // Reduced width of the bar
            borderRadius: BorderRadius.zero, // Make the bars square
          ),
        ],
      );
    }).toList();

    // Debug prints
    print('Subject Codes: ${subjectCodes.values}');
    print('Student Progress by Exam: $studentProgressByExam');
    print('Data Entries: $dataEntries');

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.start, // Align bars to the left
          maxY: 100,
          barGroups: dataEntries,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < subjectList.length) {
                    return Text(
                      subjectList[index],
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final subjectCode = subjectList[group.x.toInt()];
                final value = rod.toY.round();
                return BarTooltipItem(
                  '$subjectCode\n$value%',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
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
                    labelText: 'Search by Full Name',
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchStudentByName,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.pinkAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                if (_fullName.isNotEmpty && _selectedStudentId.isNotEmpty) ...[
                  Text('Full Name: $_fullName'),
                  const SizedBox(height: 16.0), // Added space here
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
                  if (studentProgressByExam.isNotEmpty) _buildGraph(),
                  if (studentProgressByExam.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16.0, // Reduced column spacing
                        columns: [
                          const DataColumn(label: Text('Subject', style: TextStyle(fontSize: 12))),
                          ...exams.where((exam) => exam['id'] != 'Choose Exam').map((exam) => DataColumn(
                            label: Text(exam['description'] ?? 'Unknown', style: const TextStyle(fontSize: 12)),
                          )),
                        ],
                        rows: subjectCodes.values.map((code) {
                          return DataRow(cells: [
                            DataCell(Text(code, style: const TextStyle(fontSize: 12))),
                            ...exams.where((exam) => exam['id'] != 'Choose Exam').map((exam) {
                              final examId = exam['id']!;
                              final progress = studentProgressByExam[examId]?[code] ?? '-';
                              return DataCell(Text(progress, style: const TextStyle(fontSize: 12)));
                            }),
                          ]);
                        }).toList(),
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
                if (studentsProgress.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16.0, // Reduced column spacing
                      columns: [
                        const DataColumn(label: Text('Name', style: TextStyle(fontSize: 12))),
                        ...subjectCodes.values.map((code) => DataColumn(
                          label: Text(code, style: const TextStyle(fontSize: 12)),
                        )),
                      ],
                      rows: studentsProgress.entries.map((entry) {
                        final studentName = entry.value['name'] ?? '-';
                        return DataRow(cells: [
                          DataCell(Text(studentName, style: const TextStyle(fontSize: 12))),
                          ...subjectCodes.values.map((code) => DataCell(
                            Text(entry.value[code] ?? '-', style: const TextStyle(fontSize: 12)),
                          )),
                        ]);
                      }).toList(),
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