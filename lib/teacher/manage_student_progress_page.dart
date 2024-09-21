import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

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
                    'id': entry.key?.toString() ?? 'nknown',
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

            map[studentId]![progress['examDescription'] ?? ''] = progress['percentage']?.toString() ?? '-';
            return map;
          },
        );

        setState(() {
          studentsProgress = filteredProgress;
        });
      } else {
        setState(() {
          studentsProgress = {};
        });
      }
    } catch (e) {
      print('Error fetching student progress by subject: $e');
    }
  }

  Future<void> _searchStudentByName(String name) async {
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
              final studentName = studentMap['fullName'] as String?;
              return studentName != null && studentName.toLowerCase() == lowerCaseName;
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
              studentProgress = null;
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
      print('Error searching for student: $e');
      setState(() {
        _fullName = 'Error occurred';
        studentProgress = null;
        studentsProgress = {};
      });
    }
  }

  Future<void> _fetchStudentProgress() async {
    if (_selectedStudentId.isEmpty || _selectedSubject == 'Choose Subject') {
      return;
    }

    try {
      final snapshot = await _progressRef
          .orderByChild('studentId')
          .equalTo(_selectedStudentId)
          .get();

      if (snapshot.exists) {
        final progressData = snapshot.value as Map<Object?, Object?>;

        final studentProgressData = progressData.entries.fold<Map<String, String>>(
          {
            'UP1': '-',
            'PPT': '-',
            'UP2': '-',
            'PAT': '-',
            'PUPK': '-',
          },
          (map, entry) {
            final progress = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            if (progress['subjectId'] == _selectedSubject) {
              map[progress['examDescription'] ?? ''] = progress['percentage']?.toString() ?? '-';
            }
            return map;
          },
        );

        setState(() {
          studentProgress = studentProgressData;
        });
      } else {
        setState(() {
          studentProgress = null;
        });
      }
    } catch (e) {
      print('Error fetching student progress: $e');
    }
  }

  Widget _buildGraph() {
    if (studentProgress == null || studentProgress!.isEmpty) return Container(); // No data to display

    final dataEntries = studentProgress!.entries.map((entry) {
      final xValue = _getExamIndex(entry.key); // Convert exam description to an index
      final yValue = double.tryParse(entry.value); // Assuming value is percentage for y-axis

      if (xValue != null && yValue != null) {
        return BarChartGroupData(
          x: xValue,
          barRods: [
            BarChartRodData(
              toY: yValue,
              color: const Color.fromARGB(255, 222, 105, 243), // Light purple color
              width: 50, // Increase the width of the bar
              borderRadius: BorderRadius.zero, // Make the bars square
            ),
          ],
          barsSpace: 4, // Add some space between bars
        );
      } else {
        return null; // Skip invalid entries
      }
    }).where((group) => group != null).cast<BarChartGroupData>().toList();

    // Debug prints
    print('Data Entries: $dataEntries');

    if (dataEntries.isEmpty) {
      print('No valid data entries to display.');
      return Container(); // No valid data to display
    }

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.start, // Align bars to the start
          barGroups: dataEntries,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(_getExamDescription(value.toInt())),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Students Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
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
            if (_selectedFilter == 'Student') ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by Full Name',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _searchStudentByName(value);
                  } else {
                    setState(() {
                      _fullName = '';
                      studentProgress = null;
                      studentsProgress = {};
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),
              if (_fullName.isNotEmpty && _selectedStudentId.isNotEmpty) ...[
                Text('Full Name:\n$_fullName'),
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
                        studentProgress = null; // Clear progress if no subject is selected
                      }
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                if (studentProgress != null) _buildGraph(),
                if (studentProgress != null) ...[
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return DataTable(
                          columnSpacing: constraints.maxWidth / 8,
                          columns: const [
                            DataColumn(label: Text('UP1', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('PPT', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('UP2', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('PAT', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('PUPK', style: TextStyle(fontSize: 12))),
                          ],
                          rows: [
                            DataRow(cells: [
                              DataCell(Text(studentProgress!['UP1'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(studentProgress!['PPT'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(studentProgress!['UP2'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(studentProgress!['PAT'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(studentProgress!['PUPK'] ?? '-', style: const TextStyle(fontSize: 12))),
                            ]),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
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
                      studentsProgress = {}; // Clear progress if no subject is selected
                    }
                  });
                },
              ),
              const SizedBox(height: 16.0),
              if (_selectedSubject != 'Choose Subject') ...[
                const Text(
                  'List of Students',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                if (studentsProgress.isNotEmpty)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return DataTable(
                          columnSpacing: constraints.maxWidth / 12,
                          columns: const [
                            DataColumn(label: Text('Full Name', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('UP1', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('PPT', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('UP2', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('PAT', style: TextStyle(fontSize: 12))),
                            DataColumn(label: Text('PUPK', style: TextStyle(fontSize: 12))),
                          ],
                          rows: studentsProgress.entries.map((entry) {
                            final progress = entry.value;
                            return DataRow(cells: [
                              DataCell(Text(progress['name'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(progress['UP1'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(progress['PPT'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(progress['UP2'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(progress['PAT'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(progress['PUPK'] ?? '-', style: const TextStyle(fontSize: 12))),
                            ]);
                          }).toList(),
                        );
                      },
                    ),
                  )
                else
                  const Text('No data available for the selected subject.'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}