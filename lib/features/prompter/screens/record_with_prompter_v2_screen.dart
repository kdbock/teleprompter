import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../scripts/providers/script_providers.dart';
import '../../../shared/models/script.dart';
import '../../../shared/services/recording_service.dart';
import 'recordings_screen.dart';

enum RecordV2State {
  idle,
  starting,
  recording,
  stopping,
  reviewing,
  error,
}

class RecordWithPrompterV2Screen extends ConsumerStatefulWidget {
  const RecordWithPrompterV2Screen({super.key, required this.scriptId});

  final String scriptId;

  @override
  ConsumerState<RecordWithPrompterV2Screen> createState() =>
      _RecordWithPrompterV2ScreenState();
}

class _RecordWithPrompterV2ScreenState
    extends ConsumerState<RecordWithPrompterV2Screen> {
  final RecordingService _recordingService = RecordingService();
  final ScrollController _scrollController = ScrollController();
  List<CameraDescription> _cameras = const [];
  CameraController? _cameraController;
  ResolutionPreset _resolutionPreset = ResolutionPreset.high;
  Script? _script;
  RecordV2State _state = RecordV2State.idle;
  bool _isScrolling = false;
  bool _countdownEnabled = true;
  int _countdownSeconds = 3;
  int _countdownRemaining = 0;
  bool _mirrorMode = false;
  bool _touchLocked = false;
  final double _scrollSpeed = 45;
  double _fontSize = 40;
  double? _loopStartOffset;
  double? _loopEndOffset;
  final List<({String label, double offset})> _markers = [];
  String? _error;
  String _stage = 'boot';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _setStage('request_permissions');
    final permissionsGranted = await _ensureCapturePermissions();
    if (!permissionsGranted) {
      if (!mounted) return;
      setState(() {
        _state = RecordV2State.error;
        _error = 'Camera and microphone permissions are required.';
      });
      return;
    }

    _setStage('load_script');
    final script = await ref.read(scriptRepositoryProvider).getScript(widget.scriptId);
    if (script == null) {
      if (!mounted) return;
      setState(() {
        _state = RecordV2State.error;
        _error = 'Script not found.';
      });
      return;
    }

    _setStage('init_camera');
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera available');
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        _resolutionPreset,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameras = cameras;
        _cameraController = controller;
        _script = script;
        _state = RecordV2State.idle;
        _error = null;
      });
      _setStage('ready');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = RecordV2State.error;
        _error = 'Camera init failed: $e';
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

    return cameraStatus.isGranted && micStatus.isGranted;
  }

  Future<void> _onRecordStopPressed() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      if (_state == RecordV2State.idle) {
        if (_countdownEnabled && _countdownSeconds > 0) {
          final ok = await _runCountdown();
          if (!ok || !mounted || _state != RecordV2State.idle) return;
        }
        _setStage('start_recording');
        setState(() => _state = RecordV2State.starting);
        try {
          await controller.prepareForVideoRecording();
        } catch (_) {}
        await controller.startVideoRecording().timeout(const Duration(seconds: 8));
        if (!mounted) return;
        setState(() => _state = RecordV2State.recording);
        _setStage('recording');
        _isScrolling = true;
        unawaited(_autoScrollLoop());
        return;
      }

      if (_state == RecordV2State.recording) {
        _setStage('stop_recording');
        setState(() => _state = RecordV2State.stopping);
        final file = await controller
            .stopVideoRecording()
            .timeout(const Duration(seconds: 15));
        final reviewPath = await _waitForReadableVideo(file.path);

        _setStage('push_review');
        if (!mounted) return;
        setState(() => _state = RecordV2State.reviewing);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecordingPlayerScreen(
              recording: {
                'path': reviewPath,
                'scriptId': widget.scriptId,
                'scriptTitle': _script?.title ?? 'Recording',
              },
            ),
          ),
        );

        // Persist in background so review is never blocked by storage/gallery paths.
        unawaited(_persistTakeInBackground(reviewPath));

        if (!mounted) return;
        _setStage('back_from_review');
        setState(() {
          _state = RecordV2State.idle;
          _isScrolling = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = RecordV2State.error;
        _error = 'Recording flow failed at $_stage: $e';
      });
    }
  }

  void _setStage(String stage) {
    if (!mounted) return;
    setState(() => _stage = stage);
  }

  Future<bool> _runCountdown() async {
    _setStage('countdown');
    for (var i = _countdownSeconds; i >= 1; i--) {
      if (!mounted || _state != RecordV2State.idle) return false;
      setState(() => _countdownRemaining = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return false;
    setState(() => _countdownRemaining = 0);
    return true;
  }

  Future<void> _persistTakeInBackground(String sourcePath) async {
    try {
      await _recordingService
          .markRecordingInProgress(
            tempPath: sourcePath,
            scriptId: widget.scriptId,
            scriptTitle: _script?.title ?? 'Recording',
          )
          .timeout(const Duration(seconds: 5));
      await _recordingService
          .saveRecording(
            sourcePath: sourcePath,
            scriptId: widget.scriptId,
            scriptTitle: _script?.title ?? 'Recording',
          )
          .timeout(const Duration(seconds: 20));
      await _recordingService.clearRecordingInProgress();
    } catch (_) {
      // Keep UI path deterministic; recovery on next launch can handle leftovers.
    }
  }

  Future<void> _switchCamera() async {
    if (_state != RecordV2State.idle || _cameras.length < 2) return;
    final current = _cameraController;
    if (current == null) return;
    final targetLens = current.description.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final target = _cameras.firstWhere(
      (c) => c.lensDirection == targetLens,
      orElse: () => _cameras.first,
    );
    _setStage('switch_camera');
    try {
      final replacement = CameraController(
        target,
        _resolutionPreset,
        enableAudio: true,
      );
      await replacement.initialize();
      await current.dispose();
      if (!mounted) return;
      setState(() => _cameraController = replacement);
      _setStage('ready');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not switch camera: $e')),
      );
    }
  }

  Future<void> _setResolution(ResolutionPreset preset) async {
    if (_state != RecordV2State.idle || _resolutionPreset == preset) return;
    final current = _cameraController;
    if (current == null) return;
    _setStage('set_resolution');
    try {
      final replacement = CameraController(
        current.description,
        preset,
        enableAudio: true,
      );
      await replacement.initialize();
      await current.dispose();
      if (!mounted) return;
      setState(() {
        _cameraController = replacement;
        _resolutionPreset = preset;
      });
      _setStage('ready');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not set resolution: $e')),
      );
    }
  }

  Future<void> _autoScrollLoop() async {
    while (mounted && _isScrolling && _state == RecordV2State.recording) {
      if (!_scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        continue;
      }
      final max = _scrollController.position.maxScrollExtent;
      final next = (_scrollController.offset + (_scrollSpeed / 60)).clamp(0.0, max);
      final loopStart = _loopStartOffset;
      final loopEnd = _loopEndOffset;
      if (loopStart != null &&
          loopEnd != null &&
          loopEnd > loopStart &&
          next >= loopEnd) {
        _scrollController.jumpTo(loopStart.clamp(0.0, max));
      } else {
        _scrollController.jumpTo(next);
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
    final markerNumber = _markers.length + 1;
    setState(() {
      _markers.add((label: 'M$markerNumber', offset: _scrollController.offset));
    });
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
              title: Text('${marker.label}  (${marker.offset.round()})'),
              onTap: () => Navigator.pop(context, index),
            );
          },
        ),
      ),
    );
    if (selected == null) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(_markers[selected].offset.clamp(0.0, max));
    setState(() => _isScrolling = false);
  }

  Future<String> _waitForReadableVideo(String path) async {
    _setStage('prepare_review_file');
    final file = File(path);
    var previousSize = -1;
    for (var i = 0; i < 12; i++) {
      if (await file.exists()) {
        final size = await file.length();
        if (size > 0 && size == previousSize) return path;
        previousSize = size;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    if (_script == null && _error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_script?.title ?? 'Record')),
      body: Stack(
        children: [
          if (controller != null && controller.value.isInitialized)
            Positioned.fill(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scaleByDouble(_mirrorMode ? -1.0 : 1.0, 1.0, 1.0, 1.0),
                child: CameraPreview(controller),
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(color: Colors.black),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          if (_script != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_touchLocked) return;
                  if (_state == RecordV2State.recording) {
                    setState(() => _isScrolling = !_isScrolling);
                    if (_isScrolling) unawaited(_autoScrollLoop());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 140),
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
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'State: ${_state.name}  •  Stage: $_stage${_error == null ? '' : '\nError: $_error'}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 164,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _state == RecordV2State.idle ? _switchCamera : null,
                    icon: const Icon(Icons.cameraswitch),
                    label: const Text('Switch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => _mirrorMode = !_mirrorMode),
                    icon: Icon(_mirrorMode ? Icons.flip : Icons.flip_outlined),
                    label: const Text('Mirror'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => _touchLocked = !_touchLocked),
                    icon: Icon(_touchLocked ? Icons.lock : Icons.lock_open),
                    label: Text(_touchLocked ? 'Locked' : 'Touch'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _state == RecordV2State.recording
                        ? () {
                            setState(() => _isScrolling = !_isScrolling);
                            if (_isScrolling) unawaited(_autoScrollLoop());
                          }
                        : null,
                    icon: Icon(_isScrolling ? Icons.pause : Icons.play_arrow),
                    label: Text(_isScrolling ? 'Pause Scroll' : 'Start Scroll'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 124,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _setLoopStartAtCurrent,
                    child: const Text('Loop Start'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _setLoopEndAtCurrent,
                    child: const Text('Loop End'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: (_loopStartOffset != null || _loopEndOffset != null)
                        ? _clearLoop
                        : null,
                    child: const Text('Clear Loop'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _addMarker,
                    child: const Text('Add Marker'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _markers.isEmpty ? null : _jumpToMarker,
                    child: Text('Jump (${_markers.length})'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 84,
            child: SegmentedButton<ResolutionPreset>(
              segments: const [
                ButtonSegment<ResolutionPreset>(
                  value: ResolutionPreset.medium,
                  label: Text('720p'),
                ),
                ButtonSegment<ResolutionPreset>(
                  value: ResolutionPreset.high,
                  label: Text('1080p'),
                ),
                ButtonSegment<ResolutionPreset>(
                  value: ResolutionPreset.veryHigh,
                  label: Text('4K*'),
                ),
              ],
              selected: {_resolutionPreset},
              onSelectionChanged: _state == RecordV2State.idle
                  ? (values) => _setResolution(values.first)
                  : null,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: FilledButton.icon(
              onPressed: (_state == RecordV2State.starting ||
                      _state == RecordV2State.stopping ||
                      _state == RecordV2State.reviewing)
                  ? null
                  : _onRecordStopPressed,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor:
                    _state == RecordV2State.recording ? Colors.red : null,
              ),
              icon: (_state == RecordV2State.starting ||
                      _state == RecordV2State.stopping ||
                      _state == RecordV2State.reviewing)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_state == RecordV2State.recording
                      ? Icons.stop
                      : Icons.fiber_manual_record),
              label: Text(
                switch (_state) {
                  RecordV2State.recording => 'Stop',
                  RecordV2State.starting => 'Starting...',
                  RecordV2State.stopping => 'Stopping...',
                  RecordV2State.reviewing => 'Opening Review...',
                  _ => 'Record',
                },
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 150,
            child: Column(
              children: [
                IconButton(
                  onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(24, 72)),
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                ),
                IconButton(
                  onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(24, 72)),
                  icon: const Icon(Icons.remove_circle, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
