import 'dart:io';

import 'package:gal/gal.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class RecordingService {
  static const String recordingsBoxName = 'recordings';
  static const String recordingsRecoveryBoxName = 'recordings_recovery';

  Future<Box<Map>> _getRecordingsBox() async {
    if (!Hive.isBoxOpen(recordingsBoxName)) {
      return await Hive.openBox<Map>(recordingsBoxName);
    }
    return Hive.box<Map>(recordingsBoxName);
  }

  Future<Box<Map>> _getRecoveryBox() async {
    if (!Hive.isBoxOpen(recordingsRecoveryBoxName)) {
      return await Hive.openBox<Map>(recordingsRecoveryBoxName);
    }
    return Hive.box<Map>(recordingsRecoveryBoxName);
  }

  Future<void> markRecordingInProgress({
    required String tempPath,
    required String scriptId,
    required String scriptTitle,
  }) async {
    final box = await _getRecoveryBox();
    await box.put('active', {
      'tempPath': tempPath,
      'scriptId': scriptId,
      'scriptTitle': scriptTitle,
      'startedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearRecordingInProgress() async {
    final box = await _getRecoveryBox();
    await box.delete('active');
  }

  Future<int> recoverInterruptedRecordings() async {
    final box = await _getRecoveryBox();
    final active = box.get('active');
    if (active == null) return 0;

    final data = Map<String, dynamic>.from(active);
    final tempPath = data['tempPath'] as String?;
    if (tempPath == null || tempPath.isEmpty) {
      await clearRecordingInProgress();
      return 0;
    }

    final tempFile = File(tempPath);
    if (!await tempFile.exists()) {
      await clearRecordingInProgress();
      return 0;
    }

    final scriptId = (data['scriptId'] as String?) ?? 'unknown';
    final scriptTitle = (data['scriptTitle'] as String?) ?? 'Recovered Recording';

    await saveRecording(
      sourcePath: tempPath,
      scriptId: scriptId,
      scriptTitle: scriptTitle,
    );
    await clearRecordingInProgress();
    return 1;
  }

  Future<Map<String, dynamic>> saveRecording({
    required String sourcePath,
    required String scriptId,
    required String scriptTitle,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Recording file not found');
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'mp4';
    final localPath = '${recordingsDir.path}/rec_$id.$ext';
    final localFile = await sourceFile.copy(localPath);

    final record = <String, dynamic>{
      'id': id,
      'scriptId': scriptId,
      'scriptTitle': scriptTitle,
      'path': localFile.path,
      'createdAt': DateTime.now().toIso8601String(),
      'savedToGallery': false,
      'galleryError': null,
      'title': scriptTitle,
      'tags': <String>[],
      'isBestTake': false,
    };

    final box = await _getRecordingsBox();
    await box.put(id, record);

    bool savedToGallery = false;
    String? galleryError;
    try {
      await Gal.putVideo(
        localFile.path,
        album: 'Solo Teleprompter',
      ).timeout(const Duration(seconds: 8));
      savedToGallery = true;
    } catch (e) {
      galleryError = e.toString();
    }
    record['savedToGallery'] = savedToGallery;
    record['galleryError'] = galleryError;
    await box.put(id, record);

    if (sourcePath != localFile.path && await sourceFile.exists()) {
      await sourceFile.delete();
    }
    return record;
  }

  Future<List<Map<String, dynamic>>> getRecordings() async {
    final box = await _getRecordingsBox();
    final items = box.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    items.sort((a, b) => (b['createdAt'] as String)
        .compareTo(a['createdAt'] as String));
    return items;
  }

  Future<void> deleteRecording(String id) async {
    final box = await _getRecordingsBox();
    final data = box.get(id);
    if (data != null) {
      final map = Map<String, dynamic>.from(data);
      final path = map['path'] as String?;
      if (path != null) {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      }
    }
    await box.delete(id);
  }

  Future<void> updateRecording(String id, Map<String, dynamic> patch) async {
    final box = await _getRecordingsBox();
    final data = box.get(id);
    if (data == null) return;
    final existing = Map<String, dynamic>.from(data);
    existing.addAll(patch);
    await box.put(id, existing);
  }

  Future<Map<String, dynamic>> createDerivedTake({
    required String sourceRecordingId,
    required Map<String, dynamic> exportSettings,
  }) async {
    final box = await _getRecordingsBox();
    final sourceData = box.get(sourceRecordingId);
    if (sourceData == null) {
      throw Exception('Source recording not found');
    }
    final source = Map<String, dynamic>.from(sourceData);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final derived = Map<String, dynamic>.from(source)
      ..['id'] = id
      ..['createdAt'] = DateTime.now().toIso8601String()
      ..['sourceRecordingId'] = sourceRecordingId
      ..['isDerived'] = true
      ..['exportProfile'] = exportSettings
      ..['title'] = '${(source['title'] as String? ?? 'Recording')} (Styled)';
    await box.put(id, derived);
    return derived;
  }
}
