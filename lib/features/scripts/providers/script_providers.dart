import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/script_repository.dart';
import '../../../shared/models/script.dart';
import '../../team/providers/team_providers.dart';

/// Provider for ScriptRepository
final scriptRepositoryProvider = Provider<ScriptRepository>((ref) {
  return ScriptRepository();
});

/// Provider for all scripts in current team
final teamScriptsProvider = StreamProvider<List<Script>>((ref) {
  final currentTeam = ref.watch(currentTeamProvider).value;
  final userTeams = ref.watch(userTeamsProvider).value ?? const [];
  final team = currentTeam ?? (userTeams.isNotEmpty ? userTeams.first : null);
  if (team == null) return Stream.value([]);

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return scriptRepository.getScriptsForTeam(team.id);
});

/// Provider for published scripts in current team
final publishedScriptsProvider = StreamProvider<List<Script>>((ref) {
  final currentTeam = ref.watch(currentTeamProvider).value;
  final userTeams = ref.watch(userTeamsProvider).value ?? const [];
  final team = currentTeam ?? (userTeams.isNotEmpty ? userTeams.first : null);
  if (team == null) return Stream.value([]);

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return scriptRepository.getPublishedScripts(team.id);
});

/// Provider for draft scripts in current team
final draftScriptsProvider = StreamProvider<List<Script>>((ref) {
  final currentTeam = ref.watch(currentTeamProvider).value;
  final userTeams = ref.watch(userTeamsProvider).value ?? const [];
  final team = currentTeam ?? (userTeams.isNotEmpty ? userTeams.first : null);
  if (team == null) return Stream.value([]);

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return scriptRepository.getDraftScripts(team.id);
});

/// Provider for a specific script
final scriptProvider = StreamProvider.family<Script?, String>((ref, scriptId) {
  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return scriptRepository
      .getScript(scriptId)
      .asStream()
      .asyncExpand((script) async* {
    if (script != null) yield script;
  });
});

/// Provider for search query state
final scriptSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered scripts based on search
final filteredScriptsProvider = StreamProvider<List<Script>>((ref) {
  final query = ref.watch(scriptSearchQueryProvider);
  final currentTeam = ref.watch(currentTeamProvider).value;
  final userTeams = ref.watch(userTeamsProvider).value ?? const [];
  final team = currentTeam ?? (userTeams.isNotEmpty ? userTeams.first : null);
  if (team == null) return Stream.value([]);
  
  final scriptRepository = ref.watch(scriptRepositoryProvider);
  
  if (query.isEmpty) {
    return scriptRepository.getScriptsForTeam(team.id);
  }
  
  return scriptRepository.searchScripts(team.id, query);
});

/// Provider for script count
final scriptCountProvider = FutureProvider<int>((ref) async {
  final currentTeam = ref.watch(currentTeamProvider).value;
  final userTeams = ref.watch(userTeamsProvider).value ?? const [];
  final team = currentTeam ?? (userTeams.isNotEmpty ? userTeams.first : null);
  if (team == null) return 0;

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return await scriptRepository.getScriptCount(team.id);
});

/// Provider for published script count
final publishedScriptCountProvider = FutureProvider<int>((ref) async {
  final currentTeam = ref.watch(currentTeamProvider).value;
  final userTeams = ref.watch(userTeamsProvider).value ?? const [];
  final team = currentTeam ?? (userTeams.isNotEmpty ? userTeams.first : null);
  if (team == null) return 0;

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return await scriptRepository.getPublishedScriptCount(team.id);
});

/// Provider for recently created/edited scripts for home quick access
final recentScriptsProvider = Provider<AsyncValue<List<Script>>>((ref) {
  final scriptsAsync = ref.watch(teamScriptsProvider);
  return scriptsAsync.whenData((scripts) {
    final sorted = [...scripts]
      ..sort((a, b) {
        final aTime = a.lastEditedAt ?? a.createdAt;
        final bTime = b.lastEditedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    return sorted.take(5).toList();
  });
});
