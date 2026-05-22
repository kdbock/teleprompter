import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/team_repository.dart';
import '../../../shared/models/team.dart';
import '../../auth/providers/auth_providers.dart';

/// Provider for TeamRepository
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository();
});

/// Provider for current user's teams
final userTeamsProvider = StreamProvider<List<Team>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  final teamRepository = ref.watch(teamRepositoryProvider);
  return teamRepository.getTeamsForUser(currentUser.id);
});

/// Provider for a specific team
final teamProvider = FutureProvider.family<Team?, String>((ref, teamId) async {
  final teamRepository = ref.watch(teamRepositoryProvider);
  return await teamRepository.getTeam(teamId);
});

/// Provider for current team (based on user's currentTeamId)
final currentTeamProvider = StreamProvider<Team?>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null || currentUser.currentTeamId == null) {
    yield null;
    return;
  }

  final teamRepository = ref.watch(teamRepositoryProvider);
  final team = await teamRepository.getTeam(currentUser.currentTeamId!);
  yield team;
});
