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
    final fileName = url.split('/').last.split('?').first; // Remove query parameters
    final file = File('${directory.path}/$fileName');

    try {
      debugPrint('Attempting to download PDF from URL: $url');
      debugPrint('Saving to path: ${file.path}');

      // Always download fresh copy for Firebase Storage URLs
      if (url.contains('firebasestorage.googleapis.com')) {
        debugPrint('Downloading from Firebase Storage...');
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          // Check if the response is actually a PDF
          final contentType = response.headers['content-type'];
          final contentLength = response.contentLength ?? response.bodyBytes.length;
          
          debugPrint('Content-Type: $contentType');
          debugPrint('Content-Length: $contentLength bytes');

          if (contentLength > 0) {
            await file.writeAsBytes(response.bodyBytes);
            debugPrint('File saved successfully');
            
            // Verify the file exists and has content
            if (await file.exists() && (await file.length()) > 0) {
              return file;
            } else {
              throw Exception('Downloaded file is empty or invalid');
            }
          } else {
            throw Exception('Downloaded file is empty (content length: $contentLength)');
          }
        } else {
          throw Exception('Failed to download file: Status ${response.statusCode}');
        }
      } else {
        // For non-Firebase URLs, keep existing caching logic
        if (await file.exists()) {
          final fileStats = await file.stat();
          final fileAge = DateTime.now().difference(fileStats.modified);
          if (fileAge.inMinutes < 30) {
            debugPrint('Using cached file');
            return file;
          }
        }

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          return file;
        } else {
          throw Exception('Failed to download file: Status ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error downloading PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C6B58),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _pdfFile = _downloadFile(widget.fileUrl);
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<File>(
        future: _pdfFile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF0C6B58),
                  ),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            );
          }
          
          if (snapshot.hasError) {
            debugPrint('FutureBuilder error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading PDF: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B58),
                    ),
                    onPressed: () {
                      setState(() {
                        _pdfFile = _downloadFile(widget.fileUrl);
                      });
                    },
                    child: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            final file = snapshot.data!;
            debugPrint('Loading PDF from path: ${file.path}');
            return PDFView(
              filePath: file.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageSnap: true,
              onError: (error) {
                debugPrint('PDF View Error: $error');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error loading PDF'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              onPageError: (page, error) {
                debugPrint('PDF Page $page Error: $error');
              },
            );
          }

          return const Center(child: Text('No PDF found.'));
        },
      ),
    );
  }
}
