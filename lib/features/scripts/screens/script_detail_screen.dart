import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../repositories/script_repository.dart';
import '../../auth/providers/auth_providers.dart';
import '../../team/providers/team_providers.dart';
import '../../../shared/models/script.dart';
import '../../../shared/models/team.dart';

class ScriptDetailScreen extends ConsumerStatefulWidget {
  final String scriptId;

  const ScriptDetailScreen({super.key, required this.scriptId});

  @override
  ConsumerState<ScriptDetailScreen> createState() => _ScriptDetailScreenState();
}

class _ScriptDetailScreenState extends ConsumerState<ScriptDetailScreen> {
  Script? _script;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScript();
  }

  Future<void> _loadScript() async {
    setState(() => _isLoading = true);
    
    try {
      final scriptRepository = ref.read(scriptRepositoryProvider);
      final script = await scriptRepository.getScript(widget.scriptId);
      
      if (mounted) {
        setState(() {
          _script = script;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading script: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final currentTeam = ref.watch(currentTeamProvider).value;
    final userRole = currentTeam?.getRoleForUser(currentUser?.id ?? '');
    final canEdit = userRole?.canEdit ?? false;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_script == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Script Not Found')),
        body: const Center(
          child: Text('Script not found or has been deleted'),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(_script!.title),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/scripts/${widget.scriptId}/edit');
              },
              tooltip: 'Edit',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status badge
            Row(
              children: [
                if (_script!.isPublished)
                  Chip(
                    label: const Text('Published'),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                else
                  Chip(
                    label: const Text('Draft'),
                    backgroundColor: Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _script!.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Metadata
            _buildMetadataRow(
              Icons.access_time,
              'Created: ${dateFormat.format(_script!.createdAt)}',
            ),
            if (_script!.lastEditedAt != null)
              _buildMetadataRow(
                Icons.edit,
                'Last edited: ${dateFormat.format(_script!.lastEditedAt!)}',
              ),
            _buildMetadataRow(
              Icons.text_fields,
              '${_script!.wordCount} words',
            ),
            _buildMetadataRow(
              Icons.timer,
              'Reading time: ~${(_script!.estimatedReadingTime / 60).ceil()} minutes',
            ),
            const SizedBox(height: 16),

            // Tags
            if (_script!.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _script!.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            if (_script!.notes != null && _script!.notes!.isNotEmpty) ...[
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, size: 18, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Text(
                            'Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _script!.notes!,
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 16),

            // Content label
            Text(
              'Script Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _script!.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Start prompter button
            FilledButton.icon(
              onPressed: () {
                context.push('/prompter/${widget.scriptId}');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Teleprompter'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                context.push('/record/${widget.scriptId}');
              },
              icon: const Icon(Icons.videocam),
              label: const Text('Record With Overlay'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/recordings'),
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('View Recordings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}

// Provider for ScriptRepository (if not already defined)
final scriptRepositoryProvider = Provider((ref) => ScriptRepository());
