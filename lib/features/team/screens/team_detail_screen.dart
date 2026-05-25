import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Scripts',
            onPressed: () => context.push('/scripts'),
          ),
        ],
      ),
      body: teamAsync.when(
        data: (team) {
          if (team == null) {
            return const Center(child: Text('Team not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                team.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if ((team.description ?? '').isNotEmpty)
                Text(
                  team.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Members'),
                  trailing: Text('${team.members.length}'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/scripts'),
                icon: const Icon(Icons.description),
                label: const Text('Open Scripts'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading team: $error')),
      ),
    );
  }
}
