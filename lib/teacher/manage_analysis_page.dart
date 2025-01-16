import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class ManageAnalysisPage extends StatefulWidget {
  const ManageAnalysisPage({super.key});

  @override
  State<ManageAnalysisPage> createState() => _ManageAnalysisPageState();
}

class _ManageAnalysisPageState extends State<ManageAnalysisPage> {
  String? selectedSubject;
  String? selectedExam;
  Map<String, dynamic> subjects = {};
  Map<String, dynamic> exams = {};
  Map<String, int> gradeDistribution = {};
  bool isLoading = false;
  bool hasAnalyzed = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _loadExams();
  }

  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseDatabase.instance.ref().child('Subject').get();
    if (snapshot.exists) {
      setState(() {
        subjects = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  Future<void> _loadExams() async {
    final snapshot = await FirebaseDatabase.instance.ref().child('Exam').get();
    if (snapshot.exists) {
      setState(() {
        exams = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  Future<void> _analyzeGrades() async {
    if (selectedSubject == null || selectedExam == null) return;

    setState(() {
      isLoading = true;
      gradeDistribution = {};
      hasAnalyzed = true;
    });

    try {
      final progressRef = FirebaseDatabase.instance.ref().child('Progress');
      final snapshot = await progressRef
          .orderByChild('subjectId')
          .equalTo(selectedSubject)
          .get();

      if (snapshot.exists) {
        final progresses = Map<String, dynamic>.from(snapshot.value as Map);
        
        progresses.forEach((_, value) {
          final progress = Map<String, dynamic>.from(value as Map);
          if (progress['examId'] == selectedExam) {
            final score = progress['score'] as int;
            final grade = _calculateGrade(score);
            gradeDistribution[grade] = (gradeDistribution[grade] ?? 0) + 1;
          }
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _calculateGrade(int score) {
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        title: Container(
          alignment: Alignment.center,
          child: const Text(
            'Grade Analysis',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              fontSize: 22
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Choose Subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, 
                    vertical: 12.0
                  ),
                ),
                value: selectedSubject,
                items: subjects.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubject = value;
                    selectedExam = null;
                    gradeDistribution.clear();
                  });
                },
              ),
              const SizedBox(height: 16.0),
              
              // Exam Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Choose Examination',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, 
                    vertical: 12.0
                  ),
                ),
                value: selectedExam,
                items: exams.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value['title']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedExam = value;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              
              // Analyze Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C6B58),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, 
                      vertical: 12.0
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _analyzeGrades,
                  child: const Text(
                    'Analyze',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Loading Indicator or Graph
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (hasAnalyzed && gradeDistribution.isEmpty)
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
                        'No Marks Found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The marks have not been entered yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (gradeDistribution.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grade Distribution',
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
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: gradeDistribution.values
                                  .reduce((a, b) => a > b ? a : b)
                                  .toDouble(),
                              barGroups: [
                                _createBarGroup(0, 'A', gradeDistribution['A'] ?? 0),
                                _createBarGroup(1, 'B', gradeDistribution['B'] ?? 0),
                                _createBarGroup(2, 'C', gradeDistribution['C'] ?? 0),
                                _createBarGroup(3, 'D', gradeDistribution['D'] ?? 0),
                              ],
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey[300],
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const grades = ['A', 'B', 'C', 'D'];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          grades[value.toInt()],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildGradeSummary('A', gradeDistribution['A'] ?? 0, const Color(0xFF4CAF50)),
                            _buildGradeSummary('B', gradeDistribution['B'] ?? 0, const Color(0xFF2196F3)),
                            _buildGradeSummary('C', gradeDistribution['C'] ?? 0, const Color(0xFFFFA726)),
                            _buildGradeSummary('D', gradeDistribution['D'] ?? 0, const Color(0xFFE53935)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Total Students: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${gradeDistribution.values.fold(0, (sum, count) => sum + count)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0C6B58),
                              ),
                            ),
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

  BarChartGroupData _createBarGroup(int x, String grade, int count) {
    Color getGradeColor(String grade) {
      switch (grade) {
        case 'A':
          return const Color(0xFF4CAF50);
        case 'B':
          return const Color(0xFF2196F3);
        case 'C':
          return const Color(0xFFFFA726);
        case 'D':
          return const Color(0xFFE53935);
        default:
          return const Color(0xFF9E9E9E);
      }
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: count.toDouble(),
          color: getGradeColor(grade),
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: gradeDistribution.values
                .reduce((a, b) => a > b ? a : b)
                .toDouble(),
            color: Colors.grey[200],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeSummary(String grade, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            grade,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            'Students',
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
} 