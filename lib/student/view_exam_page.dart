import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../pdf_viewer_page.dart'; // Import the PDF viewer page
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'dart:io'; // Ensure this import is present
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class ViewExamPage extends StatefulWidget {
  const ViewExamPage({super.key});

  @override
  _ViewExamPageState createState() => _ViewExamPageState();
}

class _ViewExamPageState extends State<ViewExamPage> {
  final DatabaseReference _examRef = FirebaseDatabase.instance.ref().child('Exam');
  List<Map<String, dynamic>> _exams = [];
  List<String> _examCategories = []; // List of exam categories for filtering
  final List<String> _selectedCategories = []; // List to hold selected categories

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final snapshot = await _examRef.get();
      if (snapshot.exists) {
        final examData = snapshot.value as Map<Object?, Object?>?;
        if (examData != null) {
          setState(() {
            _exams = examData.entries.map((entry) {
              final examMap = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              return {
                'id': entry.key,
                'description': examMap['description'] ?? 'No Description',
                'title': examMap['title'] ?? 'No Description',
                'subjects': examMap['subjects'] ?? {},
                'category': examMap['description'] ?? 'Unknown',
              };
            }).toList();

            // Extract unique categories for filtering
            _examCategories = _exams.map((exam) => exam['category'] as String).toSet().toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching exams: $e');
    }
  }

  List<Map<String, dynamic>> get filteredExams {
    if (_selectedCategories.isEmpty) {
      return _exams; // Return all exams if no category is selected
    }
    return _exams.where((exam) => _selectedCategories.contains(exam['category'])).toList(); // Filter exams by selected categories
  }

  void _navigateToSubjects(Map<String, dynamic> exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectListPage(subjects: exam['subjects']),
      ),
    );
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
            'Examination',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh exam data
          await _fetchExams();
          return Future.delayed(const Duration(milliseconds: 500));
        },
        color: const Color(0xFF0C6B58),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  'List of Exams',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Exam filter chips
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "All" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategories.isEmpty,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.clear();
                          }
                        });
                      },
                      selectedColor: const Color(0xFF0C6B58),
                      backgroundColor: Colors.grey[300],
                      labelStyle: TextStyle(
                        color: _selectedCategories.isEmpty ? Colors.white : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(color: Color(0xFF0C6B58)),
                      ),
                    ),
                  ),
                  // Chips for each exam category
                  ..._examCategories.map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF0C6B58),
                        backgroundColor: Colors.grey[300],
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Color(0xFF0C6B58)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // Exam list or empty state
            filteredExams.isEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategories.isEmpty
                                ? 'No Exams Found'
                                : 'No Exams Found for Selected Category${_selectedCategories.length > 1 ? 'ies' : 'y'}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedCategories.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _selectedCategories.join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredExams.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0C6B58),
                              Color(0xFF094A3D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToSubjects(exam),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.quiz_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exam['title'] ?? 'No Title',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              exam['category'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class SubjectListPage extends StatefulWidget {
  final Map<dynamic, dynamic> subjects;

  const SubjectListPage({super.key, required this.subjects});

  @override
  _SubjectListPageState createState() => _SubjectListPageState();
}

class _SubjectListPageState extends State<SubjectListPage> {
  List<String> selectedSubjects = []; // List to hold selected subjects
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<String> allSubjects = []; // List to hold all subjects
  Map<String, String> subjectCodeToName = {}; // Add this to store subject mappings

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchAllSubjects();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        if (response.payload != null) {
          await OpenFile.open(response.payload!);
        }
      },
    );
  }

  void _viewFile(BuildContext context, String fileUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(fileUrl: fileUrl),
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }
    }
    return false;
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Request permissions first
      if (!await _requestPermissions()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required to download files')),
        );
        return;
      }

      // Ensure the file has a .pdf extension
      String sanitizedFileName = path.basename(fileName);
      if (!sanitizedFileName.toLowerCase().endsWith('.pdf')) {
        sanitizedFileName = '$sanitizedFileName.pdf';
      }

      // Get the Downloads directory path
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = '${directory.path}/$sanitizedFileName';
      
      // Show initial notification
      const androidDetailsInitial = AndroidNotificationDetails(
        'download_channel',
        'File Download',
        channelDescription: 'Shows file download progress',
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: 0,
      );
      const notificationDetailsInitial = NotificationDetails(android: androidDetailsInitial);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Starting Download',
        'Downloading $sanitizedFileName',
        notificationDetailsInitial,
      );

      // Download file
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            int progress = ((received / total) * 100).toInt();
            // Update notification progress
            final androidDetailsProgress = AndroidNotificationDetails(
              'download_channel',
              'File Download',
              channelDescription: 'Shows file download progress',
              importance: Importance.low,
              priority: Priority.low,
              showProgress: true,
              maxProgress: 100,
              progress: progress,
            );
            final notificationDetailsProgress = NotificationDetails(android: androidDetailsProgress);
            flutterLocalNotificationsPlugin.show(
              0,
              'Downloading $sanitizedFileName',
              '$progress% completed',
              notificationDetailsProgress,
            );
          }
        },
      );

      // Show completion notification
      const androidDetailsComplete = AndroidNotificationDetails(
        'download_channel',
        'File Download',
        channelDescription: 'Shows file download progress',
        importance: Importance.high,
        priority: Priority.high,
      );
      const notificationDetailsComplete = NotificationDetails(android: androidDetailsComplete);
      await flutterLocalNotificationsPlugin.show(
        1,
        'Download Complete',
        'Tap to open $sanitizedFileName',
        notificationDetailsComplete,
        payload: filePath,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to: $filePath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(filePath),
          ),
        ),
      );
    } catch (e) {
      print('Download error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _fetchAllSubjects() async {
    try {
      final DatabaseReference subjectRef = FirebaseDatabase.instance.ref().child('Subject');
      final snapshot = await subjectRef.get();
      
      if (snapshot.exists) {
        final subjectData = snapshot.value as Map<Object?, Object?>?;
        if (subjectData != null) {
          setState(() {
            // Store both the code and name mapping
            subjectCodeToName = Map.fromEntries(
              subjectData.entries.map((entry) {
                final subject = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
                return MapEntry(subject['code'] as String, "${subject['code']} - ${subject['name']}");
              }),
            );
            
            // Update allSubjects list with the full subject names
            allSubjects = subjectCodeToName.values.toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  List<MapEntry<dynamic, dynamic>> getFilteredSubjects() {
    if (selectedSubjects.isEmpty) {
      return widget.subjects.entries.toList();
    }
    
    return widget.subjects.entries.where((entry) {
      final subjectValue = entry.value['subject'] as String?;
      if (subjectValue == null) return false;
      
      // Extract the subject code from the exam subject (e.g., "US" from "US - Ulum Syari'ah")
      final examSubjectCode = subjectValue.split(' - ').first;
      
      // Check if any selected subject's code matches the exam subject code
      return selectedSubjects.any((selected) {
        final selectedCode = selected.split(' - ').first;
        return selectedCode == examSubjectCode;
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSubjects = getFilteredSubjects();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Container(
          padding: const EdgeInsets.only(right: 48.0),
          alignment: Alignment.center,
          child: const Text(
            'Exam Subject',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchAllSubjects();
          setState(() {});
          return Future.delayed(const Duration(milliseconds: 500));
        },
        color: const Color(0xFF0C6B58),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                'Choose the Subject',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Subject filter chips
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // "All" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: selectedSubjects.isEmpty,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedSubjects.clear();
                          }
                        });
                      },
                      selectedColor: const Color(0xFF0C6B58),
                      backgroundColor: Colors.grey[300],
                      labelStyle: TextStyle(
                        color: selectedSubjects.isEmpty ? Colors.white : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(color: Color(0xFF0C6B58)),
                      ),
                    ),
                  ),
                  ...allSubjects.map((subject) {
                    final isSelected = selectedSubjects.contains(subject);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(subject),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSubjects.add(subject);
                            } else {
                              selectedSubjects.remove(subject);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF0C6B58),
                        backgroundColor: Colors.grey[300],
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Color(0xFF0C6B58)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Show empty state if no subjects match the filter
            if (filteredSubjects.isEmpty) ...[
              SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.subject,
                        size: 70,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedSubjects.isEmpty
                            ? 'No Subjects Found'
                            : 'No Subjects Found for Selected Filter${selectedSubjects.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedSubjects.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          selectedSubjects.join(', '),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredSubjects.length,
                itemBuilder: (context, index) {
                  final entry = filteredSubjects[index];
                  final subject = entry.value;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0C6B58),
                          Color(0xFF094A3D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.subject,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject['title'] ?? 'No Title',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subject['description'] ?? 'No Description',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          subject['subject'] ?? 'No Subject',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (subject['fileUrl'] != null && subject['fileUrl'].isNotEmpty) ...[
                                  InkWell(
                                    onTap: () => _downloadFile(subject['fileUrl'], subject['title']),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.download,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _viewFile(context, subject['fileUrl']),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Add extra padding at the bottom
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}