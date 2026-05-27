import 'dart:io';
// ignore_for_file: deprecated_member_use

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../scripts/providers/script_providers.dart';
import 'recordings_screen.dart';
import '../../../shared/models/script.dart';
import '../../../shared/services/recording_service.dart';

class RecordWithPrompterScreen extends ConsumerStatefulWidget {
  const RecordWithPrompterScreen({super.key, required this.scriptId});

  final String scriptId;

  @override
  ConsumerState<RecordWithPrompterScreen> createState() =>
      _RecordWithPrompterScreenState();
}

class _RecordWithPrompterScreenState
    extends ConsumerState<RecordWithPrompterScreen> {
  final RecordingService _recordingService = RecordingService();
  List<CameraDescription> _cameras = const [];
  CameraController? _cameraController;
  Script? _script;
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isScrolling = false;
  bool _isCountingDown = false;
  bool _controlsExpanded = true;
  bool _isStoppingRecording = false;
  bool _mirrorMode = false;
  bool _touchLocked = false;
  bool _orientationLocked = false;
  bool _handsFreeEnabled = false;
  bool _preflightChecking = false;
  bool _preflightMicReady = false;
  bool _preflightStorageReady = false;
  DateTime? _recordingStartedAt;
  int _countdown = 0;
  String? _error;

  final ScrollController _scrollController = ScrollController();
  double _fontSize = 40;
  double _scrollSpeed = 45; // pixels / second
  double _readLineY = 0.35; // relative vertical position
  final List<({String label, double offset})> _markers = [];
  double? _loopStartOffset;
  double? _loopEndOffset;
  static const List<({String label, double speed})> _speedPresets = [
    (label: 'Slow', speed: 30),
    (label: 'Normal', speed: 45),
    (label: 'Presentation', speed: 65),
  ];
  static const String _settingsBoxName = 'settings';
  static const String _settingsPrefix = 'record_prompter_settings:';
  static const String _positionPrefix = 'record_prompter_position:';
  ResolutionPreset _resolutionPreset = ResolutionPreset.high;
  int _fps = 30;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    if (_orientationLocked) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _cameraController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hasPermissions = await _ensureCapturePermissions();
      if (!hasPermissions) {
        throw Exception('Camera and microphone permissions are required');
      }
      final repo = ref.read(scriptRepositoryProvider);
      final script = await repo.getScript(widget.scriptId);
      if (script == null) {
        throw Exception('Script not found');
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera available');
      }
      final front = _findPreferredCamera(cameras, CameraLensDirection.front);
      final controller = await _createController(front, _resolutionPreset);
      final savedSettings = await _loadSavedSettings();
      final savedOffset = await _loadSavedScrollOffset();

      if (!mounted) return;
      setState(() {
        _cameras = cameras;
        _script = script;
        _cameraController = controller;
        if (savedSettings != null) {
          _fontSize =
              (savedSettings['fontSize'] as num?)?.toDouble() ?? _fontSize;
          _scrollSpeed = (savedSettings['scrollSpeed'] as num?)?.toDouble() ??
              _scrollSpeed;
          _readLineY =
              (savedSettings['readLineY'] as num?)?.toDouble() ?? _readLineY;
        }
        _isLoading = false;
      });
      if (savedOffset != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final max = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(savedOffset.clamp(0.0, max));
        });
      }
      _runPreflightChecks();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _ensureCapturePermissions() async {
    var cameraStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;

    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }

    final granted = cameraStatus.isGranted && micStatus.isGranted;
    if (granted || !mounted) return granted;

    final isPermanentlyDenied = cameraStatus.isPermanentlyDenied ||
        cameraStatus.isRestricted ||
        micStatus.isPermanentlyDenied ||
        micStatus.isRestricted;

    if (isPermanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Camera and microphone access are disabled. Open Settings to enable them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enable camera and microphone permissions to record'),
      ),
    );
    return false;
  }

  Future<void> _runPreflightChecks() async {
    setState(() => _preflightChecking = true);
    bool micReady = false;
    bool storageReady = false;
    try {
      micReady = (await Permission.microphone.status).isGranted;
    } catch (_) {}
    try {
      final tempDir = await getTemporaryDirectory();
      final probe = '${tempDir.path}/preflight_probe.tmp';
      await File(probe).writeAsString('ok');
      await File(probe).delete();
      storageReady = true;
    } catch (_) {}
    // Avoid speech/dictation probing here; on iPad this can interact with
    // keyboard/input assistant internals and destabilize the recording flow.
    if (!mounted) return;
    setState(() {
      _preflightMicReady = micReady;
      _preflightStorageReady = storageReady;
      _preflightChecking = false;
    });
  }

  CameraDescription _findPreferredCamera(
    List<CameraDescription> cameras,
    CameraLensDirection preferred,
  ) {
    return cameras.firstWhere(
      (c) => c.lensDirection == preferred,
      orElse: () => cameras.first,
    );
  }

  Future<CameraController> _createController(
    CameraDescription camera,
    ResolutionPreset preset,
  ) async {
    final controller = CameraController(
      camera,
      preset,
      enableAudio: true,
    );
    await controller.initialize();
    return controller;
  }

  Future<void> _switchCamera() async {
    if (_isRecording || _isStoppingRecording || _cameras.length < 2) return;
    final current = _cameraController;
    if (current == null) return;
    final currentLens = current.description.lensDirection;
    final targetLens = currentLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final target = _findPreferredCamera(_cameras, targetLens);
    try {
      final replacement = await _createController(target, _resolutionPreset);
      await current.dispose();
      if (!mounted) return;
      setState(() => _cameraController = replacement);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not switch camera: $e')));
    }
  }

  Future<void> _setResolution(ResolutionPreset preset) async {
    if (_resolutionPreset == preset || _isRecording || _isStoppingRecording) {
      return;
    }
    final current = _cameraController;
    if (current == null) return;
    try {
      final replacement = await _createController(current.description, preset);
      await current.dispose();
      if (!mounted) return;
      setState(() {
        _cameraController = replacement;
        _resolutionPreset = preset;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change resolution: $e')),
      );
    }
  }

  Future<void> _setFps(int fps) async {
    if (_fps == fps || _isRecording || _isStoppingRecording) return;
    final current = _cameraController;
    if (current == null) return;
    final previousFps = _fps;
    setState(() => _fps = fps);
    try {
      final replacement = await _createController(
        current.description,
        _resolutionPreset,
      );
      await current.dispose();
      if (!mounted) return;
      setState(() => _cameraController = replacement);
    } catch (e) {
      if (!mounted) return;
      setState(() => _fps = previousFps);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FPS $fps unsupported on this setup: $e')),
      );
    }
  }

  String get _settingsKey => '$_settingsPrefix${widget.scriptId}';
  String get _positionKey => '$_positionPrefix${widget.scriptId}';

  Future<Map<String, dynamic>?> _loadSavedSettings() async {
    final box = await Hive.openBox(_settingsBoxName);
    final value = box.get(_settingsKey);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Future<void> _saveSettings() async {
    final box = await Hive.openBox(_settingsBoxName);
    await box.put(_settingsKey, {
      'fontSize': _fontSize,
      'scrollSpeed': _scrollSpeed,
      'readLineY': _readLineY,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<double?> _loadSavedScrollOffset() async {
    final box = await Hive.openBox(_settingsBoxName);
    final value = box.get(_positionKey);
    if (value is num) return value.toDouble();
    return null;
  }

  Future<void> _saveScrollOffset(double offset) async {
    final box = await Hive.openBox(_settingsBoxName);
    await box.put(_positionKey, offset);
  }

  void _setFontSize(double value) {
    setState(() => _fontSize = value);
    _saveSettings();
  }

  void _setScrollSpeed(double value) {
    setState(() => _scrollSpeed = value);
    _saveSettings();
  }

  void _setReadLineY(double value) {
    setState(() => _readLineY = value);
    _saveSettings();
  }

  Future<void> _toggleRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isStoppingRecording) return;
    try {
      if (_isRecording) {
        setState(() => _isStoppingRecording = true);
        final file = await controller
            .stopVideoRecording()
            .timeout(const Duration(seconds: 12));
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _recordingStartedAt = null;
          _isScrolling = false;
        });
        await _recordingService.markRecordingInProgress(
          tempPath: file.path,
          scriptId: widget.scriptId,
          scriptTitle: _script?.title ?? 'Recording',
        );
        String reviewPath = file.path;
        try {
          final record = await _finalizeRecording(file.path);
          reviewPath = record['path'] as String? ?? file.path;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Take saved for review only: $e')),
            );
          }
        }
        if (!mounted) return;
        await _openReviewScreen(reviewPath).timeout(const Duration(seconds: 6));
      } else {
        final hasPermissions = await _ensureCapturePermissions();
        if (!hasPermissions) return;
        if (!_isCountingDown) {
          await _startCountdown();
        }
        if (!mounted || _isRecording) return;
        await _startRecordingWithFallback(controller);
        if (!mounted) return;
        setState(() {
          _isRecording = true;
          _recordingStartedAt = DateTime.now();
        });
        if (!_isScrolling) {
          setState(() => _isScrolling = true);
          _autoScrollLoop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording error: $e')),
      );
      // Attempt to recover camera stack after native/plugin stop failures.
      if (_cameraController != null && !_isRecording) {
        try {
          await _restartCameraControllerForRecovery();
        } catch (_) {}
      }
    } finally {
      if (mounted) {
        setState(() => _isStoppingRecording = false);
      }
    }
  }

  Future<void> _startRecordingWithFallback(CameraController controller) async {
    try {
      try {
        await controller.prepareForVideoRecording();
      } catch (_) {
        // Some device/plugin combos don't require or support this pre-call.
      }
      await controller.startVideoRecording();
      return;
    } catch (_) {
      // Retry with a safer capture config for iOS/device compatibility.
    }

    final fallbackPreset = ResolutionPreset.high;
    const fallbackFps = 30;
    final current = _cameraController;
    if (current == null) {
      throw Exception('Camera controller unavailable');
    }

    final replacement = await _createController(
      current.description,
      fallbackPreset,
    );
    await current.dispose();
    if (!mounted) return;
    setState(() {
      _cameraController = replacement;
      _resolutionPreset = fallbackPreset;
      _fps = fallbackFps;
    });

    try {
      try {
        await replacement.prepareForVideoRecording();
      } catch (_) {}
      await replacement.startVideoRecording();
    } catch (e) {
      throw Exception(
        'Could not start recording on this camera setup. Try 1080p / 30 FPS. Details: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _finalizeRecording(String path) async {
    try {
      final record = await _recordingService
          .saveRecording(
            sourcePath: path,
            scriptId: widget.scriptId,
            scriptTitle: _script?.title ?? 'Recording',
          )
          .timeout(const Duration(seconds: 20));
      await _recordingService.clearRecordingInProgress();
      if (mounted) {
        final inGallery = record['savedToGallery'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              inGallery
                  ? 'Saved to gallery and app recordings'
                  : 'Saved to app recordings (gallery save failed)',
            ),
          ),
        );
      }
      return record;
    } catch (e) {
      throw Exception('Could not finalize recording: $e');
    }
  }

  Future<void> _openReviewScreen(String path) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordingPlayerScreen(
          recording: {
            'path': path,
            'scriptId': widget.scriptId,
            'scriptTitle': _script?.title ?? 'Recording',
          },
        ),
      ),
    );
  }

  Future<void> _restartCameraControllerForRecovery() async {
    final current = _cameraController;
    if (current == null) return;
    final replacement = await _createController(
      current.description,
      _resolutionPreset,
    );
    await current.dispose();
    if (!mounted) return;
    setState(() => _cameraController = replacement);
  }

  Future<void> _startCountdown() async {
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });
    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() {
      _isCountingDown = false;
      _countdown = 0;
    });
  }

  void _toggleScroll() {
    if (_isScrolling) {
      setState(() => _isScrolling = false);
      return;
    }
    setState(() => _isScrolling = true);
    _autoScrollLoop();
  }

  Future<void> _autoScrollLoop() async {
    while (mounted && _isScrolling) {
      if (!_scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        continue;
      }
      final max = _scrollController.position.maxScrollExtent;
      final next =
          (_scrollController.offset + (_scrollSpeed / 60)).clamp(0.0, max);
      final loopStart = _loopStartOffset;
      final loopEnd = _loopEndOffset;
      if (loopStart != null &&
          loopEnd != null &&
          loopEnd > loopStart &&
          next >= loopEnd) {
        _scrollController.jumpTo(loopStart.clamp(0.0, max));
        _saveScrollOffset(loopStart);
      } else {
        _scrollController.jumpTo(next);
        _saveScrollOffset(next);
      }
      if (next >= max) {
        setState(() => _isScrolling = false);
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  void _setLoopStartAtCurrent() {
    if (!_scrollController.hasClients) return;
    setState(() => _loopStartOffset = _scrollController.offset);
  }

  void _setLoopEndAtCurrent() {
    if (!_scrollController.hasClients) return;
    setState(() => _loopEndOffset = _scrollController.offset);
  }

  void _clearLoop() {
    setState(() {
      _loopStartOffset = null;
      _loopEndOffset = null;
    });
  }

  void _addMarker() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    _saveScrollOffset(offset);
    final markerNumber = _markers.length + 1;
    setState(() {
      _markers.add((label: 'M$markerNumber', offset: offset));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added marker M$markerNumber')),
    );
  }

  Future<void> _jumpToMarker() async {
    if (_markers.isEmpty || !_scrollController.hasClients) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _markers.length,
          itemBuilder: (context, index) {
            final marker = _markers[index];
            return ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(marker.label),
              subtitle: Text('Position ${(marker.offset).round()}'),
              onTap: () => Navigator.pop(context, index),
            );
          },
        ),
      ),
    );
    if (selected == null || !_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final target = _markers[selected].offset.clamp(0.0, max);
    _scrollController.jumpTo(target);
    _saveScrollOffset(target);
    setState(() => _isScrolling = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record With Prompter')),
        body: Center(child: Text('Error: $_error')),
      );
    }
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _script == null) {
      return const Scaffold(body: Center(child: Text('Unavailable')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_script!.title)),
      body: Stack(
          children: [
            Positioned.fill(child: CameraPreview(controller)),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha: 0.15)),
              ),
            ),
            Positioned.fill(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scaleByDouble(_mirrorMode ? -1.0 : 1.0, 1.0, 1.0, 1.0),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (_touchLocked) return;
                    if (_isRecording) {
                      _toggleScroll();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 170),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Text(
                        _script!.content,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _fontSize,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _FocusMask(readLineY: _readLineY),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * _readLineY,
              child: const IgnorePointer(
                child: Divider(color: Colors.redAccent, thickness: 2),
              ),
            ),
            if (_isRecording)
              Positioned(
                top: 12,
                left: 12,
                child: _RecordingPill(startedAt: _recordingStartedAt!),
              ),
            if (_isCountingDown)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    alignment: Alignment.center,
                    child: Text(
                      _countdown.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 96,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(
                              () => _handsFreeEnabled = !_handsFreeEnabled),
                          icon: Icon(
                            _handsFreeEnabled
                                ? Icons.settings_remote
                                : Icons.settings_remote_outlined,
                            color: Colors.white,
                          ),
                          tooltip: _handsFreeEnabled
                              ? 'Hands-free on'
                              : 'Hands-free off',
                        ),
                        IconButton(
                          onPressed: _cameras.length > 1 ? _switchCamera : null,
                          icon: const Icon(Icons.cameraswitch,
                              color: Colors.white),
                          tooltip: 'Switch camera',
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _mirrorMode = !_mirrorMode),
                          icon: Icon(
                            _mirrorMode ? Icons.flip : Icons.flip_outlined,
                            color: Colors.white,
                          ),
                          tooltip: _mirrorMode ? 'Mirror on' : 'Mirror off',
                        ),
                        IconButton(
                          onPressed: () async {
                            final next = !_orientationLocked;
                            if (next) {
                              await SystemChrome.setPreferredOrientations(
                                const [
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight,
                                ],
                              );
                            } else {
                              await SystemChrome.setPreferredOrientations(
                                  DeviceOrientation.values);
                            }
                            if (!mounted) return;
                            setState(() => _orientationLocked = next);
                          },
                          icon: Icon(
                            _orientationLocked
                                ? Icons.screen_lock_rotation
                                : Icons.screen_rotation,
                            color: Colors.white,
                          ),
                          tooltip: _orientationLocked
                              ? 'Orientation locked'
                              : 'Lock orientation',
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _touchLocked = !_touchLocked),
                          icon: Icon(
                            _touchLocked ? Icons.lock : Icons.lock_open,
                            color: Colors.white,
                          ),
                          tooltip:
                              _touchLocked ? 'Touch lock on' : 'Touch lock off',
                        ),
                        IconButton(
                          onPressed: () => setState(
                            () => _controlsExpanded = !_controlsExpanded,
                          ),
                          icon: Icon(
                            _controlsExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.tune,
                            color: Colors.white,
                          ),
                          tooltip: _controlsExpanded
                              ? 'Minimize settings'
                              : 'Show settings',
                        ),
                      ],
                    ),
                    if (_controlsExpanded) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Preflight',
                                    style: TextStyle(color: Colors.white)),
                                const Spacer(),
                                TextButton(
                                  onPressed: _preflightChecking
                                      ? null
                                      : _runPreflightChecks,
                                  child: Text(_preflightChecking
                                      ? 'Checking...'
                                      : 'Recheck'),
                                ),
                              ],
                            ),
                            Text(
                              'Camera: ${_cameraController != null ? 'Ready' : 'Not ready'}  •  '
                              'Mic: ${_preflightMicReady ? 'Ready' : 'Check'}  •  '
                              'Storage: ${_preflightStorageReady ? 'Ready' : 'Check'}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Text('Font',
                              style: TextStyle(color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: _fontSize,
                              min: 20,
                              max: 72,
                              divisions: 26,
                              onChanged: _setFontSize,
                            ),
                          ),
                          Text(
                            _fontSize.round().toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Scroll',
                              style: TextStyle(color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: _scrollSpeed,
                              min: 10,
                              max: 120,
                              divisions: 22,
                              onChanged: _setScrollSpeed,
                            ),
                          ),
                          Text(
                            _scrollSpeed.round().toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: _speedPresets.map((preset) {
                          final selected =
                              (_scrollSpeed - preset.speed).abs() < 0.01;
                          return FilledButton.tonal(
                            onPressed: () => _setScrollSpeed(preset.speed),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  selected ? Colors.white24 : Colors.white12,
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: selected
                                    ? Colors.white70
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(preset.label),
                          );
                        }).toList(),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('1080p'),
                            selected:
                                _resolutionPreset == ResolutionPreset.high,
                            onSelected: (_) =>
                                _setResolution(ResolutionPreset.high),
                            selectedColor: Colors.black54,
                            labelStyle: const TextStyle(color: Colors.white),
                            backgroundColor: Colors.black38,
                            side: BorderSide(
                              color: _resolutionPreset == ResolutionPreset.high
                                  ? Colors.white70
                                  : Colors.transparent,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('4K'),
                            selected:
                                _resolutionPreset == ResolutionPreset.veryHigh,
                            onSelected: (_) =>
                                _setResolution(ResolutionPreset.veryHigh),
                            selectedColor: Colors.black54,
                            labelStyle: const TextStyle(color: Colors.white),
                            backgroundColor: Colors.black38,
                            side: BorderSide(
                              color:
                                  _resolutionPreset == ResolutionPreset.veryHigh
                                      ? Colors.white70
                                      : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('30 FPS'),
                            selected: _fps == 30,
                            onSelected: (_) => _setFps(30),
                            selectedColor: Colors.black54,
                            labelStyle: const TextStyle(color: Colors.white),
                            backgroundColor: Colors.black38,
                            side: BorderSide(
                              color: _fps == 30
                                  ? Colors.white70
                                  : Colors.transparent,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('60 FPS'),
                            selected: _fps == 60,
                            onSelected: (_) => _setFps(60),
                            selectedColor: Colors.black54,
                            labelStyle: const TextStyle(color: Colors.white),
                            backgroundColor: Colors.black38,
                            side: BorderSide(
                              color: _fps == 60
                                  ? Colors.white70
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Line',
                              style: TextStyle(color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: _readLineY,
                              min: 0.20,
                              max: 0.70,
                              divisions: 25,
                              onChanged: _setReadLineY,
                            ),
                          ),
                          Text(
                            '${(_readLineY * 100).round()}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _handsFreeEnabled
                              ? 'Hands-free: volume keys enabled'
                              : 'Hands-free: off',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: _setLoopStartAtCurrent,
                            child: const Text('Set Loop Start'),
                          ),
                          FilledButton.tonal(
                            onPressed: _setLoopEndAtCurrent,
                            child: const Text('Set Loop End'),
                          ),
                          FilledButton.tonal(
                            onPressed: (_loopStartOffset != null ||
                                    _loopEndOffset != null)
                                ? _clearLoop
                                : null,
                            child: const Text('Clear Loop'),
                          ),
                        ],
                      ),
                      if (_loopStartOffset != null && _loopEndOffset != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Loop section: ${_loopStartOffset!.round()} → ${_loopEndOffset!.round()}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () {
                            _scrollController.jumpTo(0);
                            _saveScrollOffset(0);
                            setState(() => _isScrolling = false);
                          },
                          icon: const Icon(Icons.first_page),
                          label: const Text('Top'),
                        ),
                        FilledButton.icon(
                          onPressed: _isRecording ? _toggleScroll : null,
                          icon: Icon(
                              _isScrolling ? Icons.pause : Icons.play_arrow),
                          label: Text(_isScrolling ? 'Pause' : 'Scroll'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _addMarker,
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Add Marker'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _markers.isEmpty ? null : _jumpToMarker,
                          icon: const Icon(Icons.bookmarks_outlined),
                          label: Text('Jump (${_markers.length})'),
                        ),
                        FilledButton.icon(
                          onPressed:
                              (_isCountingDown || _isStoppingRecording)
                                  ? null
                                  : _toggleRecording,
                          style: FilledButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : null,
                          ),
                          icon: _isStoppingRecording
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(_isRecording
                                  ? Icons.stop
                                  : Icons.fiber_manual_record),
                          label: Text(
                            _isStoppingRecording
                                ? 'Stopping...'
                                : (_isRecording ? 'Stop' : 'Record + Scroll'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _FocusMask extends StatelessWidget {
  const _FocusMask({required this.readLineY});

  final double readLineY;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final center = h * readLineY;
        const bandHeight = 130.0;
        final topDimBottom = (center - bandHeight / 2).clamp(0.0, h);
        final bottomDimTop = (center + bandHeight / 2).clamp(0.0, h);
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: topDimBottom,
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: bottomDimTop,
              bottom: 0,
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ],
        );
      },
    );
  }
}

class _RecordingPill extends StatefulWidget {
  const _RecordingPill({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_RecordingPill> createState() => _RecordingPillState();
}

class _RecordingPillState extends State<_RecordingPill> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (x) => x),
      builder: (context, _) {
        final elapsed = DateTime.now().difference(widget.startedAt);
        final mm = elapsed.inMinutes.toString().padLeft(2, '0');
        final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fiber_manual_record,
                  color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                'REC $mm:$ss',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
