import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/team_providers.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'You must be logged in to create a team';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teamRepository = ref.read(teamRepositoryProvider);
      await teamRepository.createTeam(
        name: _nameController.text.trim(),
        ownerId: currentUser.id,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Icon(
                      Icons.groups,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Create Your Team',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your team workspace for collaborative content creation',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

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

                  // Team name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Team Name',
                      hintText: 'e.g., Content Creators, News Team',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                      helperText: 'Choose a name that represents your team',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a team name';
                      }
                      if (value.length < 3) {
                        return 'Team name must be at least 3 characters';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Tell us about your team',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                      helperText: 'What kind of content does your team create?',
                    ),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 32),

                  // Info card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'What happens next?',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• You\'ll be the team owner with full permissions\n'
                            '• You can invite members and assign roles\n'
                            '• Create and manage scripts for your team\n'
                            '• Control who can edit, publish, and record',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create button
                  FilledButton(
                    onPressed: _isLoading ? null : _createTeam,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Team'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
