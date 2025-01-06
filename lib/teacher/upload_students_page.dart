import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

class UploadStudentsPage extends StatefulWidget {
  const UploadStudentsPage({super.key});

  @override
  State<UploadStudentsPage> createState() => _UploadStudentsPageState();
}

class _UploadStudentsPageState extends State<UploadStudentsPage> {
  Uint8List? _excelBytes;
  String? _fileName;
  bool _isUploading = false;
  List<Map<String, String>> _previewData = [];
  double _uploadProgress = 0.0;

  Future<void> _pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _excelBytes = result.files.first.bytes;
        _fileName = result.files.first.name;
        _loadExcelPreview();
      });
    }
  }

  void _loadExcelPreview() {
    if (_excelBytes == null) return;

    try {
      final excelData = excel_lib.Excel.decodeBytes(_excelBytes!);
      
      if (excelData.tables.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file is empty')),
        );
        return;
      }

      final sheet = excelData.tables[excelData.tables.keys.first]!;
      _previewData.clear();

      // Skip header row
      for (var row = 1; row < sheet.maxRows; row++) {
        if (sheet.row(row).isEmpty) continue;

        // Ensure we have all required columns
        if (sheet.row(row).length < 4) continue;

        final studentData = {
          'fullName': sheet.row(row)[0]?.value?.toString().trim() ?? '',
          'icNumber': sheet.row(row)[1]?.value?.toString().trim() ?? '',
          'email': sheet.row(row)[2]?.value?.toString().trim() ?? '',
          'parentEmail': sheet.row(row)[3]?.value?.toString().trim() ?? '',
        };

        // Only add if essential data is present
        if (studentData['fullName']!.isNotEmpty && 
            studentData['icNumber']!.isNotEmpty && 
            studentData['email']!.isNotEmpty) {
          _previewData.add(studentData);
        }
      }

      setState(() {}); // Refresh UI with preview data

      if (_previewData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid student data found in the file')),
        );
      }
    } catch (e) {
      print('Error reading Excel file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error reading Excel file. Please check the file format.')),
      );
    }
  }

  Future<void> _uploadStudents() async {
    if (_previewData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Excel file first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      final auth = FirebaseAuth.instance;

      List<String> failedStudents = [];
      List<String> updatedStudents = [];
      List<String> skippedStudents = [];
      int totalStudents = _previewData.length;
      int processedStudents = 0;

      // First, get all existing students
      final existingStudentsSnapshot = await databaseRef.child('Student').get();
      Map<String, dynamic> existingStudents = {};
      
      if (existingStudentsSnapshot.exists) {
        final data = existingStudentsSnapshot.value as Map<Object?, Object?>;
        data.forEach((key, value) {
          if (value is Map) {
            final studentData = Map<String, dynamic>.from(value as Map);
            existingStudents[studentData['email'].toString()] = {
              'uid': key,
              ...studentData,
            };
          }
        });
      }

      for (var student in _previewData) {
        try {
          final studentEmail = student['email']!;
          
          // Check if student already exists
          if (existingStudents.containsKey(studentEmail)) {
            final existingStudent = existingStudents[studentEmail];
            final existingUid = existingStudent['uid'];
            
            // Check if data needs to be updated
            bool needsUpdate = existingStudent['fullName'] != student['fullName'] ||
                             existingStudent['icNumber'] != student['icNumber'] ||
                             existingStudent['parentEmail'] != student['parentEmail'];
            
            if (needsUpdate) {
              // Update existing student data
              await Future.wait([
                databaseRef.child('User').child(existingUid).update({
                  'fullName': student['fullName'],
                  'icNumber': student['icNumber'],
                }),
                databaseRef.child('Student').child(existingUid).update({
                  'fullName': student['fullName'],
                  'icNumber': student['icNumber'],
                  'parentEmail': student['parentEmail'],
                }),
              ]);
              updatedStudents.add(student['fullName']!);
            } else {
              skippedStudents.add(student['fullName']!);
            }
          } else {
            // Create new student account
            final userCredential = await auth.createUserWithEmailAndPassword(
              email: studentEmail,
              password: student['icNumber']!,
            );

            await Future.wait([
              databaseRef.child('User').child(userCredential.user!.uid).set({
                'email': student['email'],
                'fullName': student['fullName'],
                'icNumber': student['icNumber'],
                'role': 'student',
              }),
              databaseRef.child('Student').child(userCredential.user!.uid).set({
                'fullName': student['fullName'],
                'icNumber': student['icNumber'],
                'email': student['email'],
                'parentEmail': student['parentEmail'],
                'createdAt': ServerValue.timestamp,
              }),
            ]);
          }
        } catch (e) {
          failedStudents.add('${student['fullName']} (${e.toString()})');
        } finally {
          processedStudents++;
          if (mounted) {
            setState(() {
              _uploadProgress = (processedStudents / totalStudents) * 100;
            });
          }
        }
      }

      if (!mounted) return;

      // Prepare result message
      String resultMessage = '';
      if (updatedStudents.isNotEmpty) {
        resultMessage += '${updatedStudents.length} students updated.\n';
      }
      if (skippedStudents.isNotEmpty) {
        resultMessage += '${skippedStudents.length} students skipped (no changes).\n';
      }
      if (failedStudents.isEmpty) {
        resultMessage += 'Upload completed successfully.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultMessage)),
        );
        Navigator.pop(context, true);
      } else {
        resultMessage += '\nFailed to upload ${failedStudents.length} students.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultMessage),
            duration: const Duration(seconds: 5),
          ),
        );
        print('Failed students:');
        failedStudents.forEach(print);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C6B58),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Upload Students',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Upload Section
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Excel File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.cloud_upload_outlined,
                              color: Color(0xFF0C6B58),
                            ),
                            title: Text(
                              _fileName != null
                                  ? _fileName!
                                  : 'No file chosen',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: _fileName == null
                                ? Text(
                                    'Excel files only (.xlsx, .xls)',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: TextButton(
                              onPressed: _pickExcelFile,
                              child: Text(
                                _fileName != null ? 'Change' : 'Choose File',
                                style: const TextStyle(color: Color(0xFF0C6B58)),
                              ),
                            ),
                          ),
                          if (_excelBytes != null)
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade400,
                                  size: 20,
                                ),
                                title: const Text(
                                  'File ready to upload',
                                  style: TextStyle(fontSize: 13),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () =>
                                      setState(() => _excelBytes = null),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Preview Section
              if (_previewData.isNotEmpty) ...[
                const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: _previewData.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade200,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final student = _previewData[index];
                        return ListTile(
                          title: Text(
                            student['fullName']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${student['email']}\nIC: ${student['icNumber']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Upload Button
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0C6B58),
                      Color(0xFF094A3D),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0C6B58).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadStudents,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Uploading ${_uploadProgress.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Upload Students',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 