// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class PDFViewerPage extends StatefulWidget {
  final String fileUrl;

  const PDFViewerPage({super.key, required this.fileUrl});

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late Future<File> _pdfFile;

  @override
  void initState() {
    super.initState();
    _pdfFile = _downloadFile(widget.fileUrl);
  }

  Future<File> _downloadFile(String url) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/temp.pdf');

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to load PDF');
      }
    } catch (e) {
      throw Exception('Error downloading PDF: $e');
    }

    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('PDF Viewer'),
      ),
      body: FutureBuilder<File>(
        future: _pdfFile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final file = snapshot.data!;
            return PDFView(
              filePath: file.path,
            );
          }
          return const Center(child: Text('No PDF found.'));
        },
      ),
    );
  }
}
