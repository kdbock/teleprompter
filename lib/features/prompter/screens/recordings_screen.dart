import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../scripts/providers/script_providers.dart';
import '../../../shared/providers/transcription_providers.dart';
import '../../../shared/services/recording_service.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final RecordingService _service = RecordingService();
  bool _loading = true;
  List<Map<String, dynamic>> _recordings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getRecordings();
    if (!mounted) return;
    setState(() {
      _recordings = data;
      _loading = false;
    });
  }

  Future<void> _renameRecording(Map<String, dynamic> rec) async {
    final controller = TextEditingController(text: (rec['title'] as String?) ?? '');
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Recording'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (updated == null || updated.isEmpty) return;
    await _service.updateRecording(rec['id'] as String, {'title': updated});
    await _load();
  }

  Future<void> _editTags(Map<String, dynamic> rec) async {
    final current = ((rec['tags'] as List?) ?? []).join(', ');
    final controller = TextEditingController(text: current);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tags'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Comma-separated tags',
            hintText: 'retake, closeup, final',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (updated == null) return;
    final tags = updated
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await _service.updateRecording(rec['id'] as String, {'tags': tags});
    await _load();
  }

  Future<void> _toggleBestTake(Map<String, dynamic> rec) async {
    final current = rec['isBestTake'] == true;
    await _service.updateRecording(rec['id'] as String, {'isBestTake': !current});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
              ? const Center(child: Text('No recordings yet'))
              : ListView.separated(
                  itemCount: _recordings.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rec = _recordings[index];
                    final createdAt = DateTime.tryParse(rec['createdAt'] as String? ?? '');
                    final title = (rec['title'] as String?)?.trim().isNotEmpty == true
                        ? rec['title'] as String
                        : (rec['scriptTitle'] as String? ?? 'Recording');
                    final tags = ((rec['tags'] as List?) ?? []).cast<dynamic>().join(', ');
                    final isBestTake = rec['isBestTake'] == true;
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(title)),
                          if (isBestTake)
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                        ],
                      ),
                      subtitle: Text(
                        '${createdAt == null ? '' : createdAt.toLocal()}${tags.isNotEmpty ? '  •  $tags' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.play_circle_outline),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'rename') {
                            await _renameRecording(rec);
                          } else if (value == 'tags') {
                            await _editTags(rec);
                          } else if (value == 'best') {
                            await _toggleBestTake(rec);
                          } else if (value == 'delete') {
                            await _service.deleteRecording(rec['id'] as String);
                            await _load();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'rename', child: Text('Rename')),
                          const PopupMenuItem(value: 'tags', child: Text('Edit Tags')),
                          PopupMenuItem(
                            value: 'best',
                            child: Text(isBestTake ? 'Unmark Best Take' : 'Mark Best Take'),
                          ),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecordingPlayerScreen(recording: rec),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class RecordingPlayerScreen extends ConsumerStatefulWidget {
  const RecordingPlayerScreen({super.key, required this.recording});

  final Map<String, dynamic> recording;

  @override
  ConsumerState<RecordingPlayerScreen> createState() => _RecordingPlayerScreenState();
}

class _RecordingPlayerScreenState extends ConsumerState<RecordingPlayerScreen> {
  VideoPlayerController? _controller;
  final RecordingService _recordingService = RecordingService();
  bool _showLowerThird = false;
  final TextEditingController _lowerThirdController =
      TextEditingController(text: 'Your Name  •  Title');
  int _lowerThirdPosition = 1; // 0 left, 1 center, 2 right
  Color _lowerThirdTextColor = Colors.white;
  Color _lowerThirdBackgroundColor = Colors.black54;
  bool _showCaptions = false;
  bool _wordByWordCaptions = true;
  final TextEditingController _captionsController = TextEditingController(
    text: 'Add your caption text here. This can be a sentence or multiple lines.',
  );
  double _captionFontSize = 20;
  Color _captionTextColor = Colors.white;
  double _captionBgOpacity = 0.45;
  bool _isGeneratingCaptions = false;
  Duration? _trimStart;
  Duration? _trimEnd;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = File(widget.recording['path'] as String);
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    controller.addListener(_enforceTrimBounds);
    if (!mounted) return;
    final duration = controller.value.duration;
    final trimStartMs = (widget.recording['trimStartMs'] as num?)?.toInt() ?? 0;
    final trimEndMs =
        (widget.recording['trimEndMs'] as num?)?.toInt() ?? duration.inMilliseconds;
    final safeEndMs = trimEndMs.clamp(0, duration.inMilliseconds);
    final safeStartMs = trimStartMs.clamp(0, safeEndMs);
    setState(() {
      _controller = controller;
      _trimStart = Duration(milliseconds: safeStartMs);
      _trimEnd = Duration(milliseconds: safeEndMs);
    });
    if (safeStartMs > 0) {
      await controller.seekTo(Duration(milliseconds: safeStartMs));
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_enforceTrimBounds);
    _controller?.dispose();
    _lowerThirdController.dispose();
    _captionsController.dispose();
    super.dispose();
  }

  void _enforceTrimBounds() {
    final controller = _controller;
    final trimEnd = _trimEnd;
    if (controller == null || trimEnd == null) return;
    if (!controller.value.isInitialized) return;
    if (controller.value.position >= trimEnd) {
      controller.pause();
      controller.seekTo(_trimStart ?? Duration.zero);
      setState(() {});
    }
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _saveTrim() async {
    final id = widget.recording['id'] as String?;
    final start = _trimStart;
    final end = _trimEnd;
    if (id == null || start == null || end == null) return;
    await _recordingService.updateRecording(id, {
      'trimStartMs': start.inMilliseconds,
      'trimEndMs': end.inMilliseconds,
      'trimUpdatedAt': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trim saved for this take')),
    );
  }

  String _currentCaptionText(VideoPlayerController controller) {
    final raw = _captionsController.text.trim();
    if (raw.isEmpty) return '';
    if (!_wordByWordCaptions) {
      final lines = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (lines.isEmpty) return '';
      final durationMs = controller.value.duration.inMilliseconds;
      if (durationMs <= 0) return lines.first;
      final posMs = controller.value.position.inMilliseconds.clamp(0, durationMs);
      final index = ((posMs / durationMs) * lines.length).floor().clamp(0, lines.length - 1);
      return lines[index];
    }

    final words = raw
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    final durationMs = controller.value.duration.inMilliseconds;
    if (durationMs <= 0) return words.first;
    final posMs = controller.value.position.inMilliseconds.clamp(0, durationMs);
    final index = ((posMs / durationMs) * words.length).floor().clamp(0, words.length - 1);
    return words[index];
  }

  Future<void> _openCaptionsEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Captions', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('One Word')),
                          ButtonSegment(value: false, label: Text('Line')),
                        ],
                        selected: {_wordByWordCaptions},
                        onSelectionChanged: (selection) {
                          setState(() => _wordByWordCaptions = selection.first);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _captionsController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: _wordByWordCaptions
                              ? 'Caption source text'
                              : 'One line per caption step',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loadLinkedScriptText,
                            icon: const Icon(Icons.text_snippet_outlined),
                            label: const Text('Load Script Text'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _isGeneratingCaptions
                                ? null
                                : _generateCaptionsFromAudio,
                            icon: const Icon(Icons.graphic_eq),
                            label: Text(
                              _isGeneratingCaptions
                                  ? 'Generating...'
                                  : 'Generate from Audio',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'You can auto-generate then edit for misspeaks.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Font Size: ${_captionFontSize.toStringAsFixed(0)}'),
                      Slider(
                        value: _captionFontSize,
                        min: 14,
                        max: 34,
                        onChanged: (value) {
                          setState(() => _captionFontSize = value);
                          setSheetState(() {});
                        },
                      ),
                      Text('Background Opacity: ${_captionBgOpacity.toStringAsFixed(2)}'),
                      Slider(
                        value: _captionBgOpacity,
                        min: 0.0,
                        max: 0.85,
                        onChanged: (value) {
                          setState(() => _captionBgOpacity = value);
                          setSheetState(() {});
                        },
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _colorChip(Colors.white, _captionTextColor, 'Text', (c) {
                            setState(() => _captionTextColor = c);
                            setSheetState(() {});
                          }),
                          _colorChip(Colors.yellow, _captionTextColor, 'Text', (c) {
                            setState(() => _captionTextColor = c);
                            setSheetState(() {});
                          }),
                          _colorChip(Colors.cyanAccent, _captionTextColor, 'Text', (c) {
                            setState(() => _captionTextColor = c);
                            setSheetState(() {});
                          }),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show captions'),
                        value: _showCaptions,
                        onChanged: (value) {
                          setState(() => _showCaptions = value);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadLinkedScriptText() async {
    final scriptId = widget.recording['scriptId'] as String?;
    if (scriptId == null || scriptId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No linked script found for this recording')),
      );
      return;
    }
    try {
      final repo = ref.read(scriptRepositoryProvider);
      final script = await repo.getScript(scriptId);
      if (!mounted) return;
      if (script == null || script.content.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Linked script has no content')),
        );
        return;
      }
      setState(() {
        _captionsController.text = script.content.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loaded script text into captions')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load script text: $e')),
      );
    }
  }

  Future<void> _generateCaptionsFromAudio() async {
    final path = widget.recording['path'] as String?;
    if (path == null || path.isEmpty) return;
    setState(() => _isGeneratingCaptions = true);
    try {
      final service = ref.read(transcriptionServiceProvider);
      final transcript = await service.transcribeVideoFile(path);
      if (!mounted) return;
      setState(() {
        _captionsController.text = transcript.trim();
        _showCaptions = transcript.trim().isNotEmpty;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generated captions from audio')),
      );
    } catch (e) {
      await _loadLinkedScriptText();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transcription failed, loaded script text instead: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingCaptions = false);
      }
    }
  }

  Alignment _lowerThirdAlignment() {
    switch (_lowerThirdPosition) {
      case 0:
        return const Alignment(-0.75, 0.78);
      case 2:
        return const Alignment(0.75, 0.78);
      default:
        return const Alignment(0, 0.78);
    }
  }

  Future<void> _openLowerThirdEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lower Third', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lowerThirdController,
                      decoration: const InputDecoration(labelText: 'Overlay text'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Left')),
                        ButtonSegment(value: 1, label: Text('Center')),
                        ButtonSegment(value: 2, label: Text('Right')),
                      ],
                      selected: {_lowerThirdPosition},
                      onSelectionChanged: (selection) {
                        final value = selection.first;
                        setState(() => _lowerThirdPosition = value);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _colorChip(Colors.white, _lowerThirdTextColor, 'Text', (c) {
                          setState(() => _lowerThirdTextColor = c);
                          setSheetState(() {});
                        }),
                        _colorChip(Colors.yellow, _lowerThirdTextColor, 'Text', (c) {
                          setState(() => _lowerThirdTextColor = c);
                          setSheetState(() {});
                        }),
                        _colorChip(Colors.cyan, _lowerThirdTextColor, 'Text', (c) {
                          setState(() => _lowerThirdTextColor = c);
                          setSheetState(() {});
                        }),
                        _colorChip(Colors.black54, _lowerThirdBackgroundColor, 'Bg', (c) {
                          setState(() => _lowerThirdBackgroundColor = c);
                          setSheetState(() {});
                        }),
                        _colorChip(Colors.blueGrey.withValues(alpha: 0.75), _lowerThirdBackgroundColor,
                            'Bg', (c) {
                          setState(() => _lowerThirdBackgroundColor = c);
                          setSheetState(() {});
                        }),
                        _colorChip(Colors.deepOrange.withValues(alpha: 0.75), _lowerThirdBackgroundColor,
                            'Bg', (c) {
                          setState(() => _lowerThirdBackgroundColor = c);
                          setSheetState(() {});
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show lower third'),
                      value: _showLowerThird,
                      onChanged: (value) {
                        setState(() => _showLowerThird = value);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _colorChip(
    Color color,
    Color selected,
    String label,
    ValueChanged<Color> onTap,
  ) {
    final isSelected = color.toARGB32() == selected.toARGB32();
    return InkWell(
      onTap: () => onTap(color),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(label, style: TextStyle(color: _readableTextColor(color))),
      ),
    );
  }

  Color _readableTextColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Playback')),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: Stack(
                        children: [
                          Positioned.fill(child: VideoPlayer(controller)),
                          if (_showLowerThird && _lowerThirdController.text.trim().isNotEmpty)
                            Align(
                              alignment: _lowerThirdAlignment(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _lowerThirdBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _lowerThirdController.text.trim(),
                                  style: TextStyle(
                                    color: _lowerThirdTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          if (_showCaptions && _captionsController.text.trim().isNotEmpty)
                            Align(
                              alignment: const Alignment(0, 0.9),
                              child: AnimatedBuilder(
                                animation: controller,
                                builder: (context, _) {
                                  final caption = _currentCaptionText(controller);
                                  if (caption.isEmpty) return const SizedBox.shrink();
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: _captionBgOpacity),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      caption,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _captionTextColor,
                                        fontSize: _captionFontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openLowerThirdEditor,
                          icon: const Icon(Icons.subtitles_outlined),
                          label: const Text('Lower Third'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _openCaptionsEditor,
                          icon: const Icon(Icons.closed_caption_outlined),
                          label: const Text('Captions'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_trimStart != null && _trimEnd != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Trim: ${_fmt(_trimStart!)} - ${_fmt(_trimEnd!)}'),
                            RangeSlider(
                              values: RangeValues(
                                _trimStart!.inMilliseconds.toDouble(),
                                _trimEnd!.inMilliseconds.toDouble(),
                              ),
                              min: 0,
                              max: controller.value.duration.inMilliseconds.toDouble(),
                              divisions: (controller.value.duration.inSeconds).clamp(1, 7200),
                              labels: RangeLabels(_fmt(_trimStart!), _fmt(_trimEnd!)),
                              onChanged: (values) {
                                setState(() {
                                  _trimStart =
                                      Duration(milliseconds: values.start.round());
                                  _trimEnd = Duration(milliseconds: values.end.round());
                                });
                              },
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    final d = controller.value.duration;
                                    setState(() {
                                      _trimStart = Duration.zero;
                                      _trimEnd = d;
                                    });
                                    await controller.seekTo(Duration.zero);
                                  },
                                  child: const Text('Reset Trim'),
                                ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  onPressed: _saveTrim,
                                  child: const Text('Save Trim'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton.icon(
                      onPressed: () {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          final start = _trimStart;
                          final end = _trimEnd;
                          if (start != null &&
                              end != null &&
                              controller.value.position >= end) {
                            controller.seekTo(start);
                          }
                          controller.play();
                        }
                        setState(() {});
                      },
                      icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(controller.value.isPlaying ? 'Pause' : 'Play'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
