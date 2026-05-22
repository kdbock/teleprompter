import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
class Team with _$Team {
  const factory Team({
    required String id,
    required String name,
    required String ownerId,
    required Map<String, UserRole> members, // userId -> role
    required DateTime createdAt,
    DateTime? updatedAt,
    String? description,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] as String,
      ownerId: data['ownerId'] as String,
      members: (data['members'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, UserRole.values.byName(value as String)),
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      description: data['description'] as String?,
    );
  }
}

extension TeamX on Team {
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'members': members.map((key, value) => MapEntry(key, value.name)),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'description': description,
    };
  }

  /// Get role for a specific user
  UserRole? getRoleForUser(String userId) => members[userId];

  /// Check if user is a member
  bool hasMember(String userId) => members.containsKey(userId);

  /// Check if user is the owner
  bool isOwner(String userId) => ownerId == userId;
}
