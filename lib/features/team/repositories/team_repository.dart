import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/team.dart';
import '../../../shared/models/user_role.dart';

/// Repository for team operations
class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new team
  Future<Team> createTeam({
    required String name,
    required String ownerId,
    String? description,
  }) async {
    final now = DateTime.now();
    final teamRef = _firestore.collection('teams').doc();

    final team = Team(
      id: teamRef.id,
      name: name,
      ownerId: ownerId,
      members: {ownerId: UserRole.publisher}, // Owner is publisher by default
      createdAt: now,
      description: description,
    );

    await teamRef.set(team.toFirestore()).timeout(const Duration(seconds: 8));

    // Best-effort profile update: do not block team creation success.
    try {
      await _firestore.collection('users').doc(ownerId).set({
        'currentTeamId': team.id,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
    } catch (_) {
      // User profile pointer can be fixed later; team creation should still continue.
    }

    return team;
  }

  /// Get team by ID
  Future<Team?> getTeam(String teamId) async {
    final doc = await _firestore.collection('teams').doc(teamId).get();
    if (!doc.exists) return null;
    return Team.fromFirestore(doc);
  }

  /// Get teams for a user
  Stream<List<Team>> getTeamsForUser(String userId) {
    return _firestore
        .collection('teams')
        .where('members.$userId', whereIn: [
          UserRole.publisher.name,
          UserRole.editor.name,
          UserRole.creator.name,
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList());
  }

  /// Add member to team
  Future<void> addMember({
    required String teamId,
    required String userId,
    required UserRole role,
  }) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members.$userId': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update member role
  Future<void> updateMemberRole({
    required String teamId,
    required String userId,
    required UserRole role,
  }) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members.$userId': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove member from team
  Future<void> removeMember({
    required String teamId,
    required String userId,
  }) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update team details
  Future<void> updateTeam({
    required String teamId,
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    await _firestore.collection('teams').doc(teamId).update(updates);
  }

  /// Delete team
  Future<void> deleteTeam(String teamId) async {
    // Delete all scripts in this team
    final scriptsQuery = await _firestore
        .collection('scripts')
        .where('teamId', isEqualTo: teamId)
        .get();

    final batch = _firestore.batch();
    for (final doc in scriptsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete team
    batch.delete(_firestore.collection('teams').doc(teamId));

    await batch.commit();
  }
}
