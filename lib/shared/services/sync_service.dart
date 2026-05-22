import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../shared/models/script.dart';
import '../../features/scripts/repositories/script_repository.dart';
import '../services/hive_service.dart';

/// Service for syncing data between Firestore and local storage
class SyncService {
  final ScriptRepository _scriptRepository;
  final HiveService _hiveService;
  final Connectivity _connectivity;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService({
    required ScriptRepository scriptRepository,
    required HiveService hiveService,
    Connectivity? connectivity,
  })  : _scriptRepository = scriptRepository,
        _hiveService = hiveService,
        _connectivity = connectivity ?? Connectivity();

  /// Start automatic sync
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) async {
        final hasConnection = result != ConnectivityResult.none;
        if (hasConnection && !_isSyncing) {
          await syncScripts();
        }
      },
    );

    // Set up periodic sync
    _syncTimer = Timer.periodic(interval, (_) async {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result != ConnectivityResult.none;
      if (hasConnection && !_isSyncing) {
        await syncScripts();
      }
    });
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivitySubscription = null;
    _syncTimer = null;
  }

  /// Sync scripts for a team
  Future<void> syncScripts({String? teamId}) async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    
    try {
      // Check connectivity
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result != ConnectivityResult.none;
      
      if (!hasConnection) {
        return; // Skip sync if offline
      }

      if (teamId != null) {
        await _syncTeamScripts(teamId);
      }
      
      await _hiveService.saveLastSyncTime(DateTime.now());
    } catch (e) {
      // Log error but don't throw
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync scripts for a specific team
  Future<void> _syncTeamScripts(String teamId) async {
    // Get scripts from Firestore
    final scriptsStream = _scriptRepository.getScriptsForTeam(teamId);
    
    // Listen to first emission
    final scripts = await scriptsStream.first;
    
    // Save all scripts to local storage
    for (final script in scripts) {
      await _hiveService.saveScript(script);
    }
  }

  /// Get script (try local first, then remote)
  Future<Script?> getScript(String scriptId, {String? teamId}) async {
    // Try local first
    final localScript = await _hiveService.getScript(scriptId);
    if (localScript != null) {
      return localScript;
    }

    // Try remote if connected
    final result = await _connectivity.checkConnectivity();
    final hasConnection = result != ConnectivityResult.none;
    
    if (hasConnection) {
      final remoteScript = await _scriptRepository.getScript(scriptId);
      if (remoteScript != null) {
        // Cache locally
        await _hiveService.saveScript(remoteScript);
      }
      return remoteScript;
    }

    return null;
  }

  /// Get all scripts (local and remote combined)
  Future<List<Script>> getScripts(String teamId) async {
    // Get local scripts
    final localScripts = await _hiveService.getScriptsByTeam(teamId);
    
    // Check connectivity
    final result = await _connectivity.checkConnectivity();
    final hasConnection = result != ConnectivityResult.none;
    
    if (!hasConnection) {
      return localScripts;
    }

    // Get remote scripts
    try {
      final remoteScripts = await _scriptRepository
          .getScriptsForTeam(teamId)
          .first;
      
      // Merge and cache
      final scriptMap = <String, Script>{};
      
      // Add local scripts
      for (final script in localScripts) {
        scriptMap[script.id] = script;
      }
      
      // Update with remote scripts (they're more recent)
      for (final script in remoteScripts) {
        scriptMap[script.id] = script;
        await _hiveService.saveScript(script);
      }
      
      return scriptMap.values.toList();
    } catch (e) {
      // Return local scripts if remote fetch fails
      return localScripts;
    }
  }

  /// Check if online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    return await _hiveService.getLastSyncTime();
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }
}
