import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import '../../features/scripts/repositories/script_repository.dart';

/// Provider for HiveService
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final scriptRepository = ref.watch(scriptRepositoryProvider);
  final hiveService = ref.watch(hiveServiceProvider);
  
  final syncService = SyncService(
    scriptRepository: scriptRepository,
    hiveService: hiveService,
  );
  
  // Start auto sync
  syncService.startAutoSync();
  
  // Clean up on dispose
  ref.onDispose(() {
    syncService.dispose();
  });
  
  return syncService;
});

/// Provider for connectivity status
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Provider to check if online
final isOnlineProvider = FutureProvider<bool>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.isOnline();
});

/// Provider for last sync time
final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  final hiveService = ref.watch(hiveServiceProvider);
  return await hiveService.getLastSyncTime();
});

/// Provider for ScriptRepository (re-export from script providers)
final scriptRepositoryProvider = Provider<ScriptRepository>((ref) {
  return ScriptRepository();
});
