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
  if (currentTeam == null) return Stream.value([]);

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return scriptRepository.getScriptsForTeam(currentTeam.id);
});

/// Provider for published scripts in current team
final publishedScriptsProvider = StreamProvider<List<Script>>((ref) {
  final currentTeam = ref.watch(currentTeamProvider).value;
  if (currentTeam == null) return Stream.value([]);

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return scriptRepository.getPublishedScripts(currentTeam.id);
});

/// Provider for draft scripts in current team
final draftScriptsProvider = StreamProvider<List<Script>>((ref) {
  final currentTeam = ref.watch(currentTeamProvider).value;
  if (currentTeam == null) return Stream.value([]);

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return scriptRepository.getDraftScripts(currentTeam.id);
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
  
  if (currentTeam == null) return Stream.value([]);
  
  final scriptRepository = ref.watch(scriptRepositoryProvider);
  
  if (query.isEmpty) {
    return scriptRepository.getScriptsForTeam(currentTeam.id);
  }
  
  return scriptRepository.searchScripts(currentTeam.id, query);
});

/// Provider for script count
final scriptCountProvider = FutureProvider<int>((ref) async {
  final currentTeam = ref.watch(currentTeamProvider).value;
  if (currentTeam == null) return 0;

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return await scriptRepository.getScriptCount(currentTeam.id);
});

/// Provider for published script count
final publishedScriptCountProvider = FutureProvider<int>((ref) async {
  final currentTeam = ref.watch(currentTeamProvider).value;
  if (currentTeam == null) return 0;

  final scriptRepository = ref.watch(scriptRepositoryProvider);
  return await scriptRepository.getPublishedScriptCount(currentTeam.id);
});
