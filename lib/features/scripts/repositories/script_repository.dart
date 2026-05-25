import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../shared/models/script.dart';

/// Repository for script operations
class ScriptRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new script
  Future<Script> createScript({
    required String teamId,
    required String title,
    required String content,
    required String createdBy,
    List<String>? tags,
    String? notes,
  }) async {
    final now = DateTime.now();
    final scriptRef = _firestore.collection('scripts').doc();

    final script = Script(
      id: scriptRef.id,
      teamId: teamId,
      title: title,
      content: content,
      createdBy: createdBy,
      createdAt: now,
      tags: tags ?? [],
      notes: notes,
    );

    try {
      await scriptRef
          .set(script.toFirestore())
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw Exception('Timed out writing script to Firestore');
    } on FirebaseException catch (e) {
      throw Exception('Firestore create failed (${e.code}): ${e.message}');
    }
    return script;
  }

  /// Get script by ID
  Future<Script?> getScript(String scriptId) async {
    final doc = await _firestore.collection('scripts').doc(scriptId).get();
    if (!doc.exists) return null;
    return Script.fromFirestore(doc);
  }

  /// Get all scripts for a team
  Stream<List<Script>> getScriptsForTeam(String teamId) {
    return _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Script.fromFirestore(doc)).toList());
  }

  /// Get published scripts for a team
  Stream<List<Script>> getPublishedScripts(String teamId) {
    return _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Script.fromFirestore(doc)).toList());
  }

  /// Get draft scripts for a team
  Stream<List<Script>> getDraftScripts(String teamId) {
    return _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .where('isPublished', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Script.fromFirestore(doc)).toList());
  }

  /// Get scripts by user
  Stream<List<Script>> getScriptsByUser(String userId, String teamId) {
    return _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Script.fromFirestore(doc)).toList());
  }

  /// Update script
  Future<void> updateScript({
    required String scriptId,
    required String userId,
    String? title,
    String? content,
    List<String>? tags,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'lastEditedBy': userId,
      'lastEditedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (tags != null) updates['tags'] = tags;
    if (notes != null) updates['notes'] = notes;

    try {
      await _firestore
          .collection('scripts')
          .doc(scriptId)
          .update(updates)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw Exception('Timed out updating script in Firestore');
    } on FirebaseException catch (e) {
      throw Exception('Firestore update failed (${e.code}): ${e.message}');
    }
  }

  /// Publish script
  Future<void> publishScript(String scriptId) async {
    await _firestore.collection('scripts').doc(scriptId).update({
      'isPublished': true,
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unpublish script
  Future<void> unpublishScript(String scriptId) async {
    await _firestore.collection('scripts').doc(scriptId).update({
      'isPublished': false,
      'publishedAt': null,
    });
  }

  /// Delete script
  Future<void> deleteScript(String scriptId) async {
    await _firestore.collection('scripts').doc(scriptId).delete();
  }

  /// Search scripts by title or content
  Stream<List<Script>> searchScripts(String teamId, String query) {
    // Note: This is a basic implementation. For production,
    // consider using Algolia or ElasticSearch for full-text search
    final lowerQuery = query.toLowerCase();
    
    return _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Script.fromFirestore(doc))
          .where((script) =>
              script.title.toLowerCase().contains(lowerQuery) ||
              script.content.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  /// Get scripts by tag
  Stream<List<Script>> getScriptsByTag(String teamId, String tag) {
    return _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Script.fromFirestore(doc)).toList());
  }

  /// Duplicate script
  Future<Script> duplicateScript({
    required String scriptId,
    required String userId,
    required String newTitle,
  }) async {
    final original = await getScript(scriptId);
    if (original == null) throw Exception('Script not found');

    return await createScript(
      teamId: original.teamId,
      title: newTitle,
      content: original.content,
      createdBy: userId,
      tags: original.tags,
      notes: original.notes,
    );
  }

  /// Get script count for team
  Future<int> getScriptCount(String teamId) async {
    final snapshot = await _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get published script count for team
  Future<int> getPublishedScriptCount(String teamId) async {
    final snapshot = await _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .where('isPublished', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
