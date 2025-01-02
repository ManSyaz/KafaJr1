enum NotificationType {
  examResult,
  attendance,
  announcement,
  academicProgress
}

class SchoolNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String parentId;
  final String studentId;
  final Map<String, dynamic>? data; // For storing examId, subjectId, etc.

  SchoolNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.parentId,
    required this.studentId,
    this.data,
  });

  factory SchoolNotification.fromJson(String id, dynamic json) {
    final Map<dynamic, dynamic> data = json as Map<dynamic, dynamic>;
    return SchoolNotification(
      id: id,
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      type: _parseNotificationType(data['type']?.toString()),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      isRead: data['isRead'] ?? false,
      parentId: data['parentId']?.toString() ?? '',
      studentId: data['studentId']?.toString() ?? '',
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'examResult':
        return NotificationType.examResult;
      case 'attendance':
        return NotificationType.attendance;
      case 'academicProgress':
        return NotificationType.academicProgress;
      default:
        return NotificationType.announcement;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'parentId': parentId,
      'studentId': studentId,
      'data': data,
    };
  }

  SchoolNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? parentId,
    String? studentId,
    Map<String, dynamic>? data,
  }) {
    return SchoolNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      data: data ?? this.data,
    );
  }
} 