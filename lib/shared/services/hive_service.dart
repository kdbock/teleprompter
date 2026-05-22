import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/script.dart';

/// Service for managing local Hive storage
class HiveService {
  static const String scriptsBoxName = 'scripts';
  static const String userBoxName = 'user';
  static const String settingsBoxName = 'settings';

  /// Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters if needed
    // For now, we'll use JSON serialization
  }

  /// Get scripts box
  Future<Box<Map>> getScriptsBox() async {
    if (!Hive.isBoxOpen(scriptsBoxName)) {
      return await Hive.openBox<Map>(scriptsBoxName);
    }
    return Hive.box<Map>(scriptsBoxName);
  }

  /// Get user box
  Future<Box<Map>> getUserBox() async {
    if (!Hive.isBoxOpen(userBoxName)) {
      return await Hive.openBox<Map>(userBoxName);
    }
    return Hive.box<Map>(userBoxName);
  }

  /// Get settings box
  Future<Box<dynamic>> getSettingsBox() async {
    if (!Hive.isBoxOpen(settingsBoxName)) {
      return await Hive.openBox(settingsBoxName);
    }
    return Hive.box(settingsBoxName);
  }

  /// Save script locally
  Future<void> saveScript(Script script) async {
    final box = await getScriptsBox();
    await box.put(script.id, script.toJson());
  }

  /// Get script from local storage
  Future<Script?> getScript(String scriptId) async {
    final box = await getScriptsBox();
    final data = box.get(scriptId);
    if (data == null) return null;
    
    try {
      return Script.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      return null;
    }
  }

  /// Get all scripts from local storage
  Future<List<Script>> getAllScripts() async {
    final box = await getScriptsBox();
    final scripts = <Script>[];
    
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          scripts.add(Script.fromJson(Map<String, dynamic>.from(data)));
        } catch (e) {
          // Skip invalid entries
        }
      }
    }
    
    return scripts;
  }

  /// Delete script from local storage
  Future<void> deleteScript(String scriptId) async {
    final box = await getScriptsBox();
    await box.delete(scriptId);
  }

  /// Clear all scripts
  Future<void> clearScripts() async {
    final box = await getScriptsBox();
    await box.clear();
  }

  /// Save last sync timestamp
  Future<void> saveLastSyncTime(DateTime time) async {
    final box = await getSettingsBox();
    await box.put('lastSyncTime', time.toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final box = await getSettingsBox();
    final timeStr = box.get('lastSyncTime');
    if (timeStr == null) return null;
    
    try {
      return DateTime.parse(timeStr);
    } catch (e) {
      return null;
    }
  }

  /// Check if script exists locally
  Future<bool> hasScript(String scriptId) async {
    final box = await getScriptsBox();
    return box.containsKey(scriptId);
  }

  /// Get scripts by team ID
  Future<List<Script>> getScriptsByTeam(String teamId) async {
    final allScripts = await getAllScripts();
    return allScripts.where((script) => script.teamId == teamId).toList();
  }

  /// Close all boxes
  static Future<void> closeAll() async {
    await Hive.close();
  }
}
