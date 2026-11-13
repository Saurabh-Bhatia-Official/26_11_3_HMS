import 'dart:convert';

/// System User account model for authentication, roles and authorization.
class UserModel {
  final int id;
  final String uuid;
  final String username;
  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String status;
  final String? lastLoginAt;
  final String? avatarPath;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.uuid,
    required this.username,
    required this.fullName,
    required this.role,
    this.email = '',
    this.phone = '',
    this.status = 'Active',
    this.lastLoginAt,
    this.avatarPath,
    this.isDeleted = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isActive => status.toLowerCase() == 'active' && !isDeleted;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int? ?? 0,
      uuid: map['uuid'] as String? ?? '',
      username: map['username'] as String? ?? '',
      fullName: (map['full_name'] ?? map['name']) as String? ?? '',
      role: map['role'] as String? ?? 'Staff',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',
      lastLoginAt: map['last_login_at'] as String?,
      avatarPath: map['avatar_path'] as String?,
      isDeleted: (map['is_deleted'] is int)
          ? (map['is_deleted'] as int) == 1
          : (map['is_deleted'] as bool? ?? false),
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'username': username,
        'full_name': fullName,
        'role': role,
        'email': email,
        'phone': phone,
        'status': status,
        'last_login_at': lastLoginAt,
        'avatar_path': avatarPath,
        'is_deleted': isDeleted ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  UserModel copyWith({
    int? id,
    String? uuid,
    String? username,
    String? fullName,
    String? role,
    String? email,
    String? phone,
    String? status,
    String? lastLoginAt,
    String? avatarPath,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarPath: avatarPath ?? this.avatarPath,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ role.hashCode;

  @override
  String toString() => 'UserModel(username: $username, role: $role)';
}

/// Role-based access control rule definition
class RolePermissionModel {
  final String role;
  final String module;
  final String action;
  final bool isAllowed;

  const RolePermissionModel({
    required this.role,
    required this.module,
    required this.action,
    this.isAllowed = true,
  });

  factory RolePermissionModel.fromMap(Map<String, dynamic> map) {
    return RolePermissionModel(
      role: map['role'] as String? ?? '',
      module: map['module'] as String? ?? '',
      action: map['action'] as String? ?? '',
      isAllowed: (map['is_allowed'] is int)
          ? (map['is_allowed'] as int) == 1
          : (map['is_allowed'] as bool? ?? true),
    );
  }

  Map<String, dynamic> toMap() => {
        'role': role,
        'module': module,
        'action': action,
        'is_allowed': isAllowed ? 1 : 0,
      };

  String toJson() => jsonEncode(toMap());

  factory RolePermissionModel.fromJson(String source) =>
      RolePermissionModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

