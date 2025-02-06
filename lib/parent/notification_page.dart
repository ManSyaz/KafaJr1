import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DatabaseReference _notificationRef = FirebaseDatabase.instance.ref().child('Noti');

  Stream<List<SchoolNotification>> _getNotifications() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return _notificationRef
          .orderByChild('parentId')
          .equalTo(user.uid)
          .onValue
          .map((event) {
        if (event.snapshot.value == null) return [];

        // Safely cast the data
        try {
          final Map<dynamic, dynamic> data = 
              event.snapshot.value as Map<dynamic, dynamic>;
          
          return data.entries.map((entry) {
            return SchoolNotification.fromJson(
              entry.key.toString(),
              entry.value,
            );
          }).toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        } catch (e) {
          print('Error parsing notifications: $e');
          return [];
        }
      });
    }
    return Stream.value([]);
  }

  // Add this method to handle notification deletion
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationRef.child(notificationId).remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Inbox',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0C6B58),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0C6B58).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            // Force refresh by setting state
            setState(() {});
            return Future.delayed(const Duration(milliseconds: 500));
          },
          color: const Color(0xFF0C6B58),
          child: StreamBuilder<List<SchoolNotification>>(
            stream: _getNotifications(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ListView( // Wrap with ListView to enable pull-to-refresh
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView( // Wrap with ListView to enable pull-to-refresh
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C6B58)),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return ListView( // Wrap with ListView to enable pull-to-refresh
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: () => _showNotificationDetails(notification),
                    onDelete: () => _deleteNotification(notification.id),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(SchoolNotification notification) {
    // Mark notification as read
    _notificationRef.child(notification.id).update({'isRead': true});

    // Get additional data based on notification type
    if (notification.type == NotificationType.examResult) {
      _showExamResultDetails(notification);
    } else {
      // Show default notification details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('MMM dd, yyyy hh:mm a').format(notification.timestamp)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showExamResultDetails(SchoolNotification notification) {
    // Fetch subject and exam details as before
    // ... existing code for showing exam result details ...
  }
}

class NotificationCard extends StatelessWidget {
  final SchoolNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final DatabaseReference _subjectRef = FirebaseDatabase.instance.ref().child('Subject');
  final DatabaseReference _studentRef = FirebaseDatabase.instance.ref().child('Student');

  NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  Future<Map<String, String>> _getAdditionalInfo() async {
    String subjectName = '';
    String studentName = '';

    // Get subject name if subjectId exists
    if (notification.data?['subjectId'] != null) {
      final subjectSnapshot = await _subjectRef.child(notification.data!['subjectId']).get();
      if (subjectSnapshot.exists) {
        final subjectData = subjectSnapshot.value as Map<dynamic, dynamic>;
        subjectName = subjectData['name'] ?? '';
      }
    }

    // Get student name if studentId exists
    final studentSnapshot = await _studentRef.child(notification.studentId).get();
    if (studentSnapshot.exists) {
      final studentData = studentSnapshot.value as Map<dynamic, dynamic>;
      studentName = studentData['fullName'] ?? '';
    }
  
    return {
      'subjectName': subjectName,
      'studentName': studentName,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getAdditionalInfo(),
      builder: (context, snapshot) {
        final additionalInfo = snapshot.data ?? {'subjectName': '', 'studentName': ''};
        final examTitle = notification.data?['examTitle'] ?? '';
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C6B58).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: const Color(0xFF0C6B58),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your Child's Latest Score is Here!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (additionalInfo['studentName']!.isNotEmpty)
                            Text(
                              'Student: ${additionalInfo['studentName']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          if (examTitle.isNotEmpty)
                            Text(
                              'Exam: $examTitle',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          if (additionalInfo['subjectName']!.isNotEmpty)
                            Text(
                              'Subject: ${additionalInfo['subjectName']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy hh:mm a').format(notification.timestamp),
                            style: TextStyle(
                              fontSize: 13,
                              color: notification.isRead ? Colors.grey : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Notification'),
                            content: const Text('Are you sure you want to delete this notification?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0C6B58),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.examResult:
        return Icons.assignment;
      case NotificationType.attendance:
        return Icons.calendar_today;
      case NotificationType.announcement:
        return Icons.announcement;
      case NotificationType.academicProgress:
        return Icons.trending_up;
    }
  }
}