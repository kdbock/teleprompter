import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'script.freezed.dart';
part 'script.g.dart';

@freezed
class Script with _$Script {
  const factory Script({
    required String id,
    required String teamId,
    required String title,
    required String content,
    required String createdBy,
    required DateTime createdAt,
    String? lastEditedBy,
    DateTime? lastEditedAt,
    @Default(false) bool isPublished,
    DateTime? publishedAt,
    @Default([]) List<String> tags,
    String? notes,
  }) = _Script;

  factory Script.fromJson(Map<String, dynamic> json) => _$ScriptFromJson(json);

  factory Script.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Script(
      id: doc.id,
      teamId: data['teamId'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastEditedBy: data['lastEditedBy'] as String?,
      lastEditedAt: data['lastEditedAt'] != null
          ? (data['lastEditedAt'] as Timestamp).toDate()
          : null,
      isPublished: data['isPublished'] as bool? ?? false,
      publishedAt: data['publishedAt'] != null
          ? (data['publishedAt'] as Timestamp).toDate()
          : null,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      notes: data['notes'] as String?,
    );
  }
}

extension ScriptX on Script {
  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'title': title,
      'content': content,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastEditedBy': lastEditedBy,
      'lastEditedAt':
          lastEditedAt != null ? Timestamp.fromDate(lastEditedAt!) : null,
      'isPublished': isPublished,
      'publishedAt':
          publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'tags': tags,
      'notes': notes,
    };
  }

  /// Get word count
  int get wordCount => content.split(RegExp(r'\s+')).length;

  /// Get estimated reading time in seconds (assuming 150 words per minute)
  int get estimatedReadingTime => (wordCount / 150 * 60).ceil();
}
