import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../providers/script_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../team/providers/team_providers.dart';
import '../../../shared/models/script.dart';
import '../../../shared/models/team.dart';

class ScriptEditorScreen extends ConsumerStatefulWidget {
  final String? scriptId;

  const ScriptEditorScreen({super.key, this.scriptId});

  @override
  ConsumerState<ScriptEditorScreen> createState() => _ScriptEditorScreenState();
}

class _ScriptEditorScreenState extends ConsumerState<ScriptEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagController = TextEditingController();
  
  List<String> _tags = [];
  bool _isLoading = false;
  bool _isSaving = false;
  Script? _currentScript;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScript();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadScript() async {
    if (widget.scriptId == null) return;

    setState(() => _isLoading = true);

    try {
      final scriptRepository = ref.read(scriptRepositoryProvider);
      final script = await scriptRepository.getScript(widget.scriptId!);

      if (script != null) {
        setState(() {
          _currentScript = script;
          _titleController.text = script.title;
          _contentController.text = script.content;
          _notesController.text = script.notes ?? '';
          _tags = List.from(script.tags);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading script: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveScript() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider).value;
    Team? currentTeam = ref.read(currentTeamProvider).value;

    // First-run fallback: currentTeamId may not be set yet on the user profile.
    if (currentTeam == null) {
      final teams = await ref.read(userTeamsProvider.future);
      if (teams.isNotEmpty) {
        currentTeam = teams.first;
      }
    }

    if (currentUser == null || currentTeam == null) {
      setState(() {
        _errorMessage = 'User or team not found';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final scriptRepository = ref.read(scriptRepositoryProvider);

      if (widget.scriptId == null) {
        // Create new script
        await scriptRepository
            .createScript(
          teamId: currentTeam.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdBy: currentUser.id,
          tags: _tags,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        )
            .timeout(const Duration(seconds: 10));
      } else {
        // Update existing script
        await scriptRepository
            .updateScript(
          scriptId: widget.scriptId!,
          userId: currentUser.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: _tags,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        )
            .timeout(const Duration(seconds: 10));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Script saved successfully')),
        );
        context.pop();
      }
    } on TimeoutException {
      setState(() {
        _errorMessage =
            'Save timed out. Please check your connection and try again.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving script: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _publishScript() async {
    if (_currentScript == null || !_currentScript!.isPublished) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Publish Script'),
          content: const Text(
            'Are you sure you want to publish this script? '
            'It will be available to all team members.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Publish'),
            ),
          ],
        ),
      );

      if (confirmed != true || widget.scriptId == null) return;

      try {
        final scriptRepository = ref.read(scriptRepositoryProvider);
        await scriptRepository.publishScript(widget.scriptId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Script published successfully')),
          );
          _loadScript();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error publishing script: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteScript() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Script'),
        content: const Text(
          'Are you sure you want to delete this script? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.scriptId == null) return;

    try {
      final scriptRepository = ref.read(scriptRepositoryProvider);
      await scriptRepository.deleteScript(widget.scriptId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Script deleted')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting script: $e')),
        );
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  int get wordCount => _contentController.text.split(RegExp(r'\s+')).length;
  
  int get estimatedTime => (wordCount / 150 * 60).ceil();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final currentTeam = ref.watch(currentTeamProvider).value;
    final userRole = currentTeam?.getRoleForUser(currentUser?.id ?? '');
    final canPublish = userRole?.canPublish ?? false;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scriptId == null ? 'New Script' : 'Edit Script'),
        actions: [
          if (widget.scriptId != null && canPublish) ...[
            IconButton(
              icon: const Icon(Icons.publish),
              onPressed: _currentScript?.isPublished == true ? null : _publishScript,
              tooltip: 'Publish',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteScript,
              tooltip: 'Delete',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveScript,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Status indicator
            if (_currentScript != null) ...[
              Row(
                children: [
                  Icon(
                    _currentScript!.isPublished
                        ? Icons.check_circle
                        : Icons.edit,
                    color: _currentScript!.isPublished
                        ? Colors.green
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentScript!.isPublished ? 'Published' : 'Draft',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _currentScript!.isPublished
                              ? Colors.green
                              : Colors.orange,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter script title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),

            // Content field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Script Content',
                hintText: 'Enter your script here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter script content';
                }
                return null;
              },
              enabled: !_isSaving,
              onChanged: (_) => setState(() {}), // Update word count
            ),
            const SizedBox(height: 8),

            // Word count and reading time
            Row(
              children: [
                Icon(Icons.text_fields, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '$wordCount words',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '~${(estimatedTime / 60).ceil()} min reading time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tags section
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    onSubmitted: (_) => _addTag(),
                    enabled: !_isSaving,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _isSaving ? null : _addTag,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: _isSaving ? null : () => _removeTag(tag),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any additional notes or instructions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _isSaving ? null : _saveScript,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Script'),
            ),
          ],
        ),
      ),
    );
  }
}
