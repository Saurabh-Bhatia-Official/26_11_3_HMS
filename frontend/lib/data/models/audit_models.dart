import 'dart:convert';

/// System Audit Log record model for security, HIPAA/compliance tracking.
class AuditLogModel {
  final int id;
  final String userName;
  final String action;
  final String entity;
  final String details;
  final String timestamp;
  final int userId;
  final String ipAddress;
  final String createdAt;

  const AuditLogModel({
    required this.id,
    required this.userName,
    required this.action,
    required this.entity,
    required this.details,
    required this.timestamp,
    this.userId = 0,
    this.ipAddress = '',
    this.createdAt = '',
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as int? ?? 0,
      userName: (map['user_name'] ?? map['username']) as String? ?? 'system',
      action: map['action'] as String? ?? '',
      entity: map['entity'] as String? ?? '',
      details: map['details'] as String? ?? '',
      timestamp: (map['timestamp'] ?? map['created_at']) as String? ?? '',
      userId: map['user_id'] as int? ?? 0,
      ipAddress: map['ip_address'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'user_name': userName,
        'action': action,
        'entity': entity,
        'details': details,
        'timestamp': timestamp,
        'user_id': userId,
        'ip_address': ipAddress,
        'created_at': createdAt,
      };

  String toJson() => jsonEncode(toMap());

  factory AuditLogModel.fromJson(String source) =>
      AuditLogModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  AuditLogModel copyWith({
    int? id,
    String? userName,
    String? action,
    String? entity,
    String? details,
    String? timestamp,
    int? userId,
    String? ipAddress,
    String? createdAt,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      ipAddress: ipAddress ?? this.ipAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userName == other.userName &&
          action == other.action &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^ userName.hashCode ^ action.hashCode ^ timestamp.hashCode;

  @override
  String toString() =>
      'AuditLogModel($timestamp | $userName: $action on $entity - $details)';
}

/// In-app system and clinical notification model
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type; // info, warning, alert, success
  final bool isRead;
  final String createdAt;
  final String? linkRoute;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'info',
    this.isRead = false,
    required this.createdAt,
    this.linkRoute,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'info',
      isRead: (map['is_read'] is int)
          ? (map['is_read'] as int) == 1
          : (map['is_read'] as bool? ?? false),
      createdAt: map['created_at'] as String? ?? '',
      linkRoute: map['link_route'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt,
        'link_route': linkRoute,
      };

  String toJson() => jsonEncode(toMap());

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

