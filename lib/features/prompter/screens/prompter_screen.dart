import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scripts/providers/script_providers.dart';
import '../services/scroll_engine.dart';
import '../../../shared/models/script.dart';

class PrompterScreen extends ConsumerStatefulWidget {
  const PrompterScreen({super.key, required this.scriptId});

  final String scriptId;

  @override
  ConsumerState<PrompterScreen> createState() => _PrompterScreenState();
}

class _PrompterScreenState extends ConsumerState<PrompterScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final ScrollEngine _scrollEngine;

  Script? _script;
  bool _isLoading = true;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollEngine = ScrollEngine(scrollController: _scrollController);
    _loadScript();
  }

  @override
  void dispose() {
    _scrollEngine.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScript() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(scriptRepositoryProvider);
      final script = await repository.getScript(widget.scriptId);
      if (!mounted) return;

      setState(() {
        _script = script;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _script = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final performance = _scrollEngine.monitor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_script?.title ?? 'Teleprompter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _script == null
              ? const Center(child: Text('Unable to load script'))
              : Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
                        child: Text(
                          _script!.content,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                height: 1.7,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Divider(thickness: 2, height: 2),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildPerformanceBadge(performance),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildControls(context),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPerformanceBadge(PrompterPerformanceMonitor performance) {
    final fps = performance.averageFps;
    final jank = (performance.jankRate * 100);
    final pass = performance.passesAcceptance;

    return Chip(
      avatar: Icon(
        pass ? Icons.check_circle : Icons.warning,
        color: pass ? Colors.green : Colors.orange,
        size: 18,
      ),
      label: Text(
        'Perf ${pass ? 'PASS' : 'CHECK'}  ${fps.toStringAsFixed(1)} FPS  Jank ${jank.toStringAsFixed(1)}%',
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Speed'),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  label: '${_speed.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    setState(() => _speed = value);
                    _scrollEngine.updateSpeed(value);
                  },
                ),
              ),
              Text('${_speed.toStringAsFixed(1)}x'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  _scrollEngine.pause();
                  _scrollEngine.resetToTop();
                  setState(() {});
                },
                icon: const Icon(Icons.first_page),
                label: const Text('Top'),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (_scrollEngine.isRunning) {
                    _scrollEngine.pause();
                  } else {
                    _scrollEngine.start(this);
                  }
                  setState(() {});
                },
                icon: Icon(
                    _scrollEngine.isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_scrollEngine.isRunning ? 'Pause' : 'Play'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  _scrollEngine.pause();
                  _scrollEngine.jumpToEnd();
                  setState(() {});
                },
                icon: const Icon(Icons.last_page),
                label: const Text('End'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
